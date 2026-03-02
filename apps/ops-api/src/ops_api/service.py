from __future__ import annotations

import hashlib
import json
import os
import sys
import uuid
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path
from typing import Protocol

# Allow imports from platform/event-ledger/src without requiring editable installation.
REPO_ROOT = Path(__file__).resolve().parents[4]
EVENT_LEDGER_SRC = REPO_ROOT / "platform/event-ledger/src"
if str(EVENT_LEDGER_SRC) not in sys.path:
    sys.path.append(str(EVENT_LEDGER_SRC))

from event_ledger import (  # type: ignore[import-not-found]
    AppendResult,
    InMemoryEventLedger,
    LedgerEvent,
    PostgresEventLedger,
    ReplayRejectedError,
)
from domains.governance.contracts_v2_adapter import DualContractReader


REQUIRED_PAYLOAD_FIELDS: tuple[str, ...] = (
    "decision_id",
    "command_id",
    "operator_id",
    "channel",
    "challenge_id",
    "signature_or_proof",
    "evidence_ref",
)


class LedgerPort(Protocol):
    def append_event(self, event: LedgerEvent) -> AppendResult: ...

    def read_stream(self, stream_id: str, *, limit: int = 100) -> list[dict[str, object]]: ...


@dataclass(frozen=True)
class HITLResult:
    status: str
    decision_id: str
    event_id: str
    ledger_status: str
    action: str


class HITLService:
    def __init__(self, ledger: LedgerPort) -> None:
        self._ledger = ledger
        self._contract_reader = DualContractReader()

    @staticmethod
    def _iso_now() -> str:
        return datetime.now(tz=UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z")

    @staticmethod
    def _digest(payload: dict[str, object]) -> str:
        text = json.dumps(payload, ensure_ascii=True, sort_keys=True, separators=(",", ":"))
        return hashlib.sha256(text.encode("utf-8")).hexdigest()

    @staticmethod
    def _validate_payload(payload: dict[str, object]) -> None:
        missing = [field for field in REQUIRED_PAYLOAD_FIELDS if not str(payload.get(field) or "").strip()]
        if missing:
            raise ValueError(f"missing required payload fields: {missing}")

        channel = str(payload.get("channel") or "")
        if channel not in {"telegram", "slack"}:
            raise ValueError("channel must be one of: telegram|slack")

        side_effect_class = str(payload.get("side_effect_class") or "operational")
        explicit_human_approval = bool(payload.get("explicit_human_approval", False))
        if side_effect_class == "financial" and not explicit_human_approval:
            raise ValueError(
                "financial side effect requires explicit_human_approval=true and validated challenge"
            )

    def handle_action(self, action: str, payload: dict[str, object]) -> HITLResult:
        if action not in {"approve", "reject", "kill"}:
            raise ValueError(f"unsupported action: {action}")
        self._validate_payload(payload)

        decision_id = str(payload["decision_id"])
        command_id = str(payload["command_id"])
        channel = str(payload["channel"])
        if bool(payload.get("primary_unavailable", False)) and channel == "telegram":
            channel = str(payload.get("fallback_channel") or "slack")
        stream_id = f"decision:{decision_id}"
        occurred_at = str(payload.get("occurred_at") or self._iso_now())

        decision_v1 = {
            "decision_id": decision_id,
            "decision_key": str(payload.get("decision_key") or decision_id),
            "status": str(payload.get("decision_status") or "PENDING"),
            "created_at": occurred_at,
            "approver_operator_id": str(payload.get("operator_id") or "unknown"),
            "approval_evidence_ref": str(payload.get("evidence_ref") or "unknown"),
            "last_command_id": command_id,
            "challenge_id": str(payload.get("challenge_id") or "not-required"),
            "challenge_status": str(payload.get("challenge_status") or "VALIDATED"),
            "challenge_expires_at": payload.get("challenge_expires_at"),
            "side_effect_class": str(payload.get("side_effect_class") or "operational"),
            "explicit_human_approval": bool(payload.get("explicit_human_approval", False)),
        }
        decision_v2 = self._contract_reader.read_decision(decision_v1)

        task_event_v1 = {
            "event_id": f"{command_id}:{action}",
            "work_order_id": str(payload.get("work_order_id") or decision_id),
            "task_id": str(payload.get("task_id") or decision_id),
            "event_type": action,
            "trace_id": str(payload.get("trace_id") or decision_id),
            "idempotency_key": command_id,
            "attempt": 1,
            "replay_key": f"{decision_id}:{command_id}:{action}:1",
            "created_at": occurred_at,
            "actor": str(payload.get("operator_id") or "unknown"),
            "evidence_ref": str(payload.get("evidence_ref") or "unknown"),
        }
        task_event_v2 = self._contract_reader.read_task_event(task_event_v1)

        event_payload = {
            "action": action,
            "decision_id": decision_id,
            "command_id": command_id,
            "operator_id": str(payload["operator_id"]),
            "channel": channel,
            "challenge_id": str(payload["challenge_id"]),
            "signature_or_proof": str(payload["signature_or_proof"]),
            "evidence_ref": str(payload["evidence_ref"]),
            "side_effect_class": str(payload.get("side_effect_class") or "operational"),
            "explicit_human_approval": bool(payload.get("explicit_human_approval", False)),
            "occurred_at": occurred_at,
            "contracts": {
                "decision_v2": decision_v2,
                "task_event_v2": task_event_v2,
            },
            "contract_read_telemetry": {
                "v1_read_count": self._contract_reader.telemetry.v1_read_count,
                "v2_read_count": self._contract_reader.telemetry.v2_read_count,
            },
        }
        # Telemetry counters are non-deterministic across retries and must not affect idempotency.
        digest_payload = dict(event_payload)
        digest_payload.pop("contract_read_telemetry", None)
        payload_digest = self._digest(digest_payload)
        replay_key = f"{decision_id}:{command_id}:{action}:1"

        event = LedgerEvent(
            event_id=f"evt-{uuid.uuid4()}",
            stream_id=stream_id,
            idempotency_key=command_id,
            replay_key=replay_key,
            command_id=command_id,
            author=str(payload["operator_id"]),
            evidence_ref=str(payload["evidence_ref"]),
            channel=channel,
            action=action,
            occurred_at=occurred_at,
            payload_digest=payload_digest,
            payload_json=event_payload,
        )
        append_result = self._ledger.append_event(event)

        status_by_action = {
            "approve": "APPROVED",
            "reject": "REJECTED",
            "kill": "KILLED",
        }
        return HITLResult(
            status=status_by_action[action],
            decision_id=decision_id,
            event_id=append_result.event_id,
            ledger_status=append_result.status,
            action=action,
        )


def build_hitl_service() -> HITLService:
    dsn = os.environ.get("OPENCLAW_EVENT_LEDGER_DSN", "").strip()
    if not dsn:
        return HITLService(ledger=InMemoryEventLedger())

    ledger = PostgresEventLedger(dsn=dsn)
    migrations_dir = REPO_ROOT / "platform/event-ledger/migrations"
    ledger.apply_migrations(migrations_dir)
    return HITLService(ledger=ledger)


__all__ = ["HITLResult", "HITLService", "ReplayRejectedError", "build_hitl_service"]
