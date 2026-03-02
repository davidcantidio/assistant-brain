from __future__ import annotations

import hashlib
import json
from collections.abc import Mapping
from dataclasses import dataclass
from datetime import UTC, datetime


def _iso_now() -> str:
    return datetime.now(tz=UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def _as_dict(payload: Mapping[str, object]) -> dict[str, object]:
    return dict(payload)


def _digest(payload: Mapping[str, object]) -> str:
    text = json.dumps(payload, ensure_ascii=True, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def _base_challenge(payload: Mapping[str, object]) -> dict[str, object]:
    challenge_id_obj = payload.get("challenge_id")
    challenge_status_obj = payload.get("challenge_status")
    challenge_expires_obj = payload.get("challenge_expires_at")
    challenge_id = str(challenge_id_obj) if challenge_id_obj not in (None, "") else "not-required"
    challenge_status = (
        str(challenge_status_obj) if challenge_status_obj not in (None, "") else "NOT_REQUIRED"
    )
    expires_at = str(challenge_expires_obj) if challenge_expires_obj not in (None, "") else None
    return {
        "challenge_id": challenge_id,
        "status": challenge_status,
        "expires_at": expires_at,
    }


def adapt_decision_v1_to_v2(payload_v1: Mapping[str, object]) -> dict[str, object]:
    source = _as_dict(payload_v1)
    author = str(source.get("approver_operator_id") or source.get("requested_by") or "unknown")
    evidence_ref = str(source.get("approval_evidence_ref") or "PRD/CHANGELOG.md")
    command_id = str(source.get("last_command_id") or source.get("decision_id") or "unknown")
    occurred_at = str(source.get("created_at") or _iso_now())
    status = str(source.get("status") or "PENDING")
    side_effect_class = str(source.get("side_effect_class") or "none")
    explicit_human_approval = bool(source.get("explicit_human_approval", False))
    idempotency_key = str(source.get("decision_key") or source.get("decision_id") or command_id)

    adapted: dict[str, object] = {
        "schema_version": "2.0",
        "contract_version": "v2",
        "decision_id": str(source.get("decision_id") or "unknown"),
        "idempotency_key": idempotency_key,
        "author": author,
        "evidence_refs": [evidence_ref],
        "command_id": command_id,
        "challenge": _base_challenge(source),
        "occurred_at": occurred_at,
        "status": status,
        "side_effect_class": side_effect_class,
        "explicit_human_approval": explicit_human_approval,
    }
    adapted["payload_digest"] = _digest(adapted)
    return adapted


def adapt_work_order_v1_to_v2(payload_v1: Mapping[str, object]) -> dict[str, object]:
    source = _as_dict(payload_v1)
    command_id = str(source.get("work_order_id") or "unknown")
    occurred_at = str(source.get("created_at") or _iso_now())
    adapted: dict[str, object] = {
        "schema_version": "2.0",
        "contract_version": "v2",
        "work_order_id": str(source.get("work_order_id") or "unknown"),
        "idempotency_key": str(source.get("idempotency_key") or command_id),
        "author": str(source.get("requested_by") or "unknown"),
        "evidence_refs": [str(source.get("evidence_ref") or "ARC/schemas/work_order.schema.json")],
        "command_id": command_id,
        "challenge": {
            "challenge_id": "not-required",
            "status": "NOT_REQUIRED",
            "expires_at": None,
        },
        "occurred_at": occurred_at,
        "objective": str(source.get("objective") or ""),
        "status": str(source.get("status") or "DRAFT"),
    }
    adapted["payload_digest"] = _digest(adapted)
    return adapted


def adapt_task_event_v1_to_v2(payload_v1: Mapping[str, object]) -> dict[str, object]:
    source = _as_dict(payload_v1)
    command_id = str(source.get("event_id") or source.get("task_id") or "unknown")
    occurred_at = str(source.get("created_at") or _iso_now())
    adapted: dict[str, object] = {
        "schema_version": "2.0",
        "contract_version": "v2",
        "event_id": str(source.get("event_id") or "unknown"),
        "idempotency_key": str(source.get("idempotency_key") or command_id),
        "author": str(source.get("actor") or "unknown"),
        "evidence_refs": [str(source.get("evidence_ref") or "ARC/schemas/task_event.schema.json")],
        "command_id": command_id,
        "challenge": {
            "challenge_id": "not-required",
            "status": "NOT_REQUIRED",
            "expires_at": None,
        },
        "occurred_at": occurred_at,
        "work_order_id": str(source.get("work_order_id") or "unknown"),
        "task_id": str(source.get("task_id") or "unknown"),
        "event_type": str(source.get("event_type") or "unknown"),
        "replay_key": str(source.get("replay_key") or f"{command_id}:1"),
    }
    adapted["payload_digest"] = _digest(adapted)
    return adapted


@dataclass
class ContractReadTelemetry:
    v1_read_count: int = 0
    v2_read_count: int = 0


class DualContractReader:
    def __init__(self) -> None:
        self.telemetry = ContractReadTelemetry()

    def read_decision(self, payload: Mapping[str, object]) -> dict[str, object]:
        if str(payload.get("contract_version") or "").lower() == "v2":
            self.telemetry.v2_read_count += 1
            return _as_dict(payload)
        self.telemetry.v1_read_count += 1
        return adapt_decision_v1_to_v2(payload)

    def read_work_order(self, payload: Mapping[str, object]) -> dict[str, object]:
        if str(payload.get("contract_version") or "").lower() == "v2":
            self.telemetry.v2_read_count += 1
            return _as_dict(payload)
        self.telemetry.v1_read_count += 1
        return adapt_work_order_v1_to_v2(payload)

    def read_task_event(self, payload: Mapping[str, object]) -> dict[str, object]:
        if str(payload.get("contract_version") or "").lower() == "v2":
            self.telemetry.v2_read_count += 1
            return _as_dict(payload)
        self.telemetry.v1_read_count += 1
        return adapt_task_event_v1_to_v2(payload)
