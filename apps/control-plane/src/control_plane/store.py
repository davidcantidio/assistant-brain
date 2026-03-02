from __future__ import annotations

import copy
import json
from dataclasses import dataclass, field
from datetime import UTC, datetime
from typing import Protocol

from control_plane.errors import ControlPlaneError


class TelemetryStore(Protocol):
    def upsert_model(self, payload: dict[str, object]) -> str:
        ...

    def list_models(
        self,
        *,
        provider: str | None = None,
        status: str | None = None,
        risk_scope: str | None = None,
        capability: str | None = None,
    ) -> list[dict[str, object]]:
        ...

    def save_router_decision(self, payload: dict[str, object]) -> None:
        ...

    def save_llm_run(self, payload: dict[str, object]) -> None:
        ...

    def save_credits_snapshot(self, payload: dict[str, object]) -> None:
        ...

    def save_budget_policy(self, payload: dict[str, object]) -> None:
        ...

    def latest_credits_snapshot(self) -> dict[str, object] | None:
        ...

    def latest_budget_policy(self) -> dict[str, object] | None:
        ...

    def save_a2a_event(self, payload: dict[str, object]) -> None:
        ...

    def save_webhook_event(self, payload: dict[str, object]) -> None:
        ...

    def trace_snapshot(self, trace_id: str) -> dict[str, object]:
        ...


@dataclass
class InMemoryTelemetryStore:
    _models: dict[str, dict[str, object]] = field(default_factory=dict)
    _router_decisions: list[dict[str, object]] = field(default_factory=list)
    _llm_runs: list[dict[str, object]] = field(default_factory=list)
    _credits_snapshots: list[dict[str, object]] = field(default_factory=list)
    _budget_policies: list[dict[str, object]] = field(default_factory=list)
    _a2a_events: list[dict[str, object]] = field(default_factory=list)
    _webhook_events: list[dict[str, object]] = field(default_factory=list)

    def upsert_model(self, payload: dict[str, object]) -> str:
        model_id = str(payload["model_id"])
        previous = self._models.get(model_id)
        if previous is None:
            self._models[model_id] = copy.deepcopy(payload)
            return "created"
        if previous == payload:
            return "noop"
        self._models[model_id] = copy.deepcopy(payload)
        return "updated"

    def list_models(
        self,
        *,
        provider: str | None = None,
        status: str | None = None,
        risk_scope: str | None = None,
        capability: str | None = None,
    ) -> list[dict[str, object]]:
        out: list[dict[str, object]] = []
        for model in self._models.values():
            if provider and model.get("provider") != provider:
                continue
            if status and model.get("status") != status:
                continue
            if risk_scope and model.get("risk_scope") != risk_scope:
                continue
            if capability:
                capabilities = model.get("capabilities")
                if not isinstance(capabilities, dict):
                    continue
                if not bool(capabilities.get(capability)):
                    continue
            out.append(copy.deepcopy(model))
        return sorted(out, key=lambda item: str(item.get("model_id", "")))

    def save_router_decision(self, payload: dict[str, object]) -> None:
        self._router_decisions.append(copy.deepcopy(payload))

    def save_llm_run(self, payload: dict[str, object]) -> None:
        self._llm_runs.append(copy.deepcopy(payload))

    def save_credits_snapshot(self, payload: dict[str, object]) -> None:
        self._credits_snapshots.append(copy.deepcopy(payload))

    def save_budget_policy(self, payload: dict[str, object]) -> None:
        self._budget_policies.append(copy.deepcopy(payload))

    def latest_credits_snapshot(self) -> dict[str, object] | None:
        if not self._credits_snapshots:
            return None
        return copy.deepcopy(self._credits_snapshots[-1])

    def latest_budget_policy(self) -> dict[str, object] | None:
        if not self._budget_policies:
            return None
        return copy.deepcopy(self._budget_policies[-1])

    def save_a2a_event(self, payload: dict[str, object]) -> None:
        self._a2a_events.append(copy.deepcopy(payload))

    def save_webhook_event(self, payload: dict[str, object]) -> None:
        self._webhook_events.append(copy.deepcopy(payload))

    def trace_snapshot(self, trace_id: str) -> dict[str, object]:
        def _filter(rows: list[dict[str, object]]) -> list[dict[str, object]]:
            out: list[dict[str, object]] = []
            for row in rows:
                if str(row.get("trace_id", "")) == trace_id:
                    out.append(copy.deepcopy(row))
            return out

        return {
            "trace_id": trace_id,
            "router_decisions": _filter(self._router_decisions),
            "llm_runs": _filter(self._llm_runs),
            "a2a_events": _filter(self._a2a_events),
            "webhook_events": _filter(self._webhook_events),
        }


class PostgresTelemetryStore(InMemoryTelemetryStore):
    """
    Postgres adapter kept intentionally simple. If psycopg is unavailable,
    fail closed with explicit guidance.
    """

    def __init__(self, dsn: str) -> None:
        super().__init__()
        try:
            import psycopg  # type: ignore
        except Exception as exc:  # pragma: no cover
            raise ControlPlaneError(
                code="POSTGRES_DRIVER_MISSING",
                message="psycopg is required for telemetry_backend=postgres",
                status_code=500,
            ) from exc

        self._psycopg = psycopg
        self._dsn = dsn
        self._conn = self._psycopg.connect(self._dsn)
        self._conn.autocommit = True
        self._ensure_schema()

    def _ensure_schema(self) -> None:
        ddl = """
        create table if not exists control_plane_events (
            id bigserial primary key,
            kind text not null,
            object_id text not null,
            trace_id text,
            payload jsonb not null,
            created_at timestamptz not null default now()
        );
        """
        with self._conn.cursor() as cur:
            cur.execute(ddl)

    def _insert_event(
        self,
        *,
        kind: str,
        object_id: str,
        payload: dict[str, object],
        trace_id: str | None = None,
    ) -> None:
        with self._conn.cursor() as cur:
            cur.execute(
                """
                insert into control_plane_events(kind, object_id, trace_id, payload)
                values (%s, %s, %s, %s::jsonb)
                """,
                (kind, object_id, trace_id, json.dumps(payload, ensure_ascii=True)),
            )

    def upsert_model(self, payload: dict[str, object]) -> str:
        status = super().upsert_model(payload)
        self._insert_event(
            kind="models_catalog",
            object_id=str(payload["model_id"]),
            trace_id=None,
            payload=payload,
        )
        return status

    def save_router_decision(self, payload: dict[str, object]) -> None:
        super().save_router_decision(payload)
        self._insert_event(
            kind="router_decision",
            object_id=str(payload["decision_id"]),
            trace_id=str(payload.get("trace_id", "")) or None,
            payload=payload,
        )

    def save_llm_run(self, payload: dict[str, object]) -> None:
        super().save_llm_run(payload)
        self._insert_event(
            kind="llm_run",
            object_id=str(payload["run_id"]),
            trace_id=str(payload.get("trace_id", "")) or None,
            payload=payload,
        )

    def save_credits_snapshot(self, payload: dict[str, object]) -> None:
        super().save_credits_snapshot(payload)
        self._insert_event(
            kind="credits_snapshot",
            object_id=str(payload["snapshot_id"]),
            trace_id=None,
            payload=payload,
        )

    def save_budget_policy(self, payload: dict[str, object]) -> None:
        super().save_budget_policy(payload)
        self._insert_event(
            kind="budget_policy",
            object_id=str(payload["policy_id"]),
            trace_id=None,
            payload=payload,
        )

    def save_a2a_event(self, payload: dict[str, object]) -> None:
        super().save_a2a_event(payload)
        self._insert_event(
            kind="a2a_delegation_event",
            object_id=str(payload["delegation_id"]),
            trace_id=str(payload.get("trace_id", "")) or None,
            payload=payload,
        )

    def save_webhook_event(self, payload: dict[str, object]) -> None:
        super().save_webhook_event(payload)
        self._insert_event(
            kind="webhook_ingest_event",
            object_id=str(payload["hook_event_id"]),
            trace_id=str(payload.get("trace_id", "")) or None,
            payload=payload,
        )


def parse_iso8601(value: str) -> datetime:
    text = value.strip()
    if text.endswith("Z"):
        text = text[:-1] + "+00:00"
    parsed = datetime.fromisoformat(text)
    if parsed.tzinfo is None:
        return parsed.replace(tzinfo=UTC)
    return parsed.astimezone(UTC)
