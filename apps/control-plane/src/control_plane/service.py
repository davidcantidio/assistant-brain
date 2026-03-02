from __future__ import annotations

import copy
from datetime import UTC, datetime
from hashlib import sha256
from typing import Callable

from control_plane.errors import ControlPlaneError
from control_plane.schema_registry import SchemaRegistry
from control_plane.store import InMemoryTelemetryStore, TelemetryStore, parse_iso8601


DEFAULT_PROVIDER_ALLOWLIST: dict[str, tuple[str, ...]] = {
    "public": ("openrouter", "ollama", "litellm"),
    "internal": ("openrouter", "litellm"),
    "sensitive": ("openrouter",),
}


class ControlPlaneService:
    def __init__(
        self,
        *,
        schemas: SchemaRegistry,
        store: TelemetryStore | None = None,
        provider_allowlist_by_sensitivity: dict[str, tuple[str, ...]] | None = None,
        prompt_storage_mode: str = "hash_and_summary",
    ) -> None:
        self.schemas = schemas
        self.store = store or InMemoryTelemetryStore()
        self.provider_allowlist = provider_allowlist_by_sensitivity or DEFAULT_PROVIDER_ALLOWLIST
        self.prompt_storage_mode = prompt_storage_mode
        self._idempotency_cache: dict[str, dict[str, object]] = {}

    def sync_model_catalog(self, payload: dict[str, object], *, idempotency_key: str) -> dict[str, object]:
        return self._run_idempotent("model-catalog/sync", idempotency_key, lambda: self._sync_model_catalog(payload))

    def _sync_model_catalog(self, payload: dict[str, object]) -> dict[str, object]:
        models_obj = payload.get("models")
        models: list[dict[str, object]]

        if isinstance(models_obj, list):
            models = []
            for item in models_obj:
                if not isinstance(item, dict):
                    raise ControlPlaneError(
                        code="INVALID_PAYLOAD",
                        message="models[] must contain objects",
                        status_code=422,
                    )
                models.append(item)
        elif isinstance(payload, dict) and "models" not in payload:
            models = [payload]
        else:
            raise ControlPlaneError(
                code="INVALID_PAYLOAD",
                message="payload must be a model object or {\"models\": [...]}",
                status_code=422,
            )

        counters = {"created": 0, "updated": 0, "noop": 0}
        for model in models:
            self.schemas.validate("models_catalog", model)
            outcome = self.store.upsert_model(model)
            counters[outcome] += 1

        return {
            "total": len(models),
            "created": counters["created"],
            "updated": counters["updated"],
            "noop": counters["noop"],
        }

    def list_models(
        self,
        *,
        provider: str | None = None,
        status: str | None = None,
        risk_scope: str | None = None,
        capability: str | None = None,
    ) -> dict[str, object]:
        items = self.store.list_models(
            provider=provider,
            status=status,
            risk_scope=risk_scope,
            capability=capability,
        )
        return {"total": len(items), "items": items}

    def decide_router(self, payload: dict[str, object], *, idempotency_key: str) -> dict[str, object]:
        return self._run_idempotent("router/decide", idempotency_key, lambda: self._decide_router(payload))

    def _decide_router(self, payload: dict[str, object]) -> dict[str, object]:
        self.schemas.validate("router_decision", payload)

        sensitivity = str(payload.get("data_sensitivity", "public"))
        effective_provider = str(payload.get("effective_provider", ""))
        self._enforce_provider_allowlist(sensitivity=sensitivity, provider=effective_provider)

        self.store.save_router_decision(payload)
        return {
            "decision_id": payload["decision_id"],
            "trace_id": payload["trace_id"],
            "accepted": True,
        }

    def ingest_run(self, payload: dict[str, object], *, idempotency_key: str) -> dict[str, object]:
        return self._run_idempotent("runs", idempotency_key, lambda: self._ingest_run(payload))

    def _ingest_run(self, payload: dict[str, object]) -> dict[str, object]:
        self.schemas.validate("llm_run", payload)
        self._enforce_provider_allowlist(
            sensitivity="internal",
            provider=str(payload.get("effective_provider", "")),
        )

        # Enforce minimized prompt storage contract.
        if self.prompt_storage_mode == "hash_and_summary":
            raw_prompt = payload.get("prompt")
            if isinstance(raw_prompt, str) and raw_prompt:
                payload = copy.deepcopy(payload)
                payload.pop("prompt", None)
                payload["prompt_hash"] = sha256(raw_prompt.encode("utf-8")).hexdigest()

        self.store.save_llm_run(payload)
        return {
            "run_id": payload["run_id"],
            "trace_id": payload["trace_id"],
            "accepted": True,
        }

    def ingest_budget_snapshot(self, payload: dict[str, object], *, idempotency_key: str) -> dict[str, object]:
        return self._run_idempotent(
            "budget/snapshots",
            idempotency_key,
            lambda: self._ingest_budget_snapshot(payload),
        )

    def _ingest_budget_snapshot(self, payload: dict[str, object]) -> dict[str, object]:
        self.schemas.validate("credits_snapshot", payload)
        self.store.save_credits_snapshot(payload)
        return {
            "snapshot_id": payload["snapshot_id"],
            "accepted": True,
        }

    def check_budget(self, payload: dict[str, object], *, idempotency_key: str) -> dict[str, object]:
        return self._run_idempotent("budget/check", idempotency_key, lambda: self._check_budget(payload))

    def _check_budget(self, payload: dict[str, object]) -> dict[str, object]:
        policy_obj = payload.get("policy")
        if not isinstance(policy_obj, dict):
            raise ControlPlaneError(
                code="INVALID_PAYLOAD",
                message="budget/check requires payload.policy object",
                status_code=422,
            )
        self.schemas.validate("budget_governor_policy", policy_obj)
        self.store.save_budget_policy(policy_obj)

        snapshot_obj = payload.get("snapshot")
        if snapshot_obj is None:
            snapshot = self.store.latest_credits_snapshot()
            if snapshot is None:
                raise ControlPlaneError(
                    code="BUDGET_SNAPSHOT_MISSING",
                    message="no snapshot provided and no stored snapshot available",
                    status_code=422,
                )
        else:
            if not isinstance(snapshot_obj, dict):
                raise ControlPlaneError(
                    code="INVALID_PAYLOAD",
                    message="snapshot must be an object when provided",
                    status_code=422,
                )
            snapshot = snapshot_obj
            self.schemas.validate("credits_snapshot", snapshot)

        blocked = False
        violations: list[str] = []

        period_usage = float(snapshot["period_usage"])
        period_limit = float(snapshot["period_limit"])
        burn_rate_hour = float(snapshot["burn_rate_hour"])
        burn_rate_day = float(snapshot["burn_rate_day"])

        if period_usage > period_limit:
            blocked = True
            violations.append("period_usage_exceeds_period_limit")

        burn_policy = policy_obj["burn_rate_policy"]
        hour_threshold = float(burn_policy["hour_threshold_usd"])
        day_threshold = float(burn_policy["day_threshold_usd"])
        if burn_rate_hour > hour_threshold:
            blocked = True
            violations.append("burn_rate_hour_exceeds_threshold")
        if burn_rate_day > day_threshold:
            blocked = True
            violations.append("burn_rate_day_exceeds_threshold")

        snapshot_contract = policy_obj["snapshot_contract"]
        freshness_minutes_max = int(snapshot_contract["freshness_minutes_max"])
        snapshot_at = parse_iso8601(str(snapshot["snapshot_at"]))
        age_minutes = (datetime.now(tz=UTC) - snapshot_at).total_seconds() / 60.0
        block_stale = bool(policy_obj["enforcement"]["block_with_stale_snapshot"])
        if age_minutes > freshness_minutes_max and block_stale:
            blocked = True
            violations.append("snapshot_stale")

        action = "allow"
        if blocked:
            action = str(burn_policy["circuit_breaker_action"])

        return {
            "blocked": blocked,
            "action": action,
            "violations": violations,
            "policy_id": policy_obj["policy_id"],
            "snapshot_id": snapshot["snapshot_id"],
            "snapshot_age_minutes": round(age_minutes, 2),
        }

    def delegate_a2a(self, payload: dict[str, object], *, idempotency_key: str) -> dict[str, object]:
        return self._run_idempotent("a2a/delegate", idempotency_key, lambda: self._delegate_a2a(payload))

    def _delegate_a2a(self, payload: dict[str, object]) -> dict[str, object]:
        self.schemas.validate("a2a_delegation_event", payload)
        allowed = bool(payload.get("allowed"))
        if not allowed:
            raise ControlPlaneError(
                code="A2A_NOT_ALLOWED",
                message="delegation blocked by allowlist/policy",
                status_code=403,
            )

        self.store.save_a2a_event(payload)
        return {
            "delegation_id": payload["delegation_id"],
            "trace_id": payload["trace_id"],
            "accepted": True,
        }

    def ingest_webhook(self, payload: dict[str, object], *, idempotency_key: str) -> dict[str, object]:
        return self._run_idempotent("hooks/ingest", idempotency_key, lambda: self._ingest_webhook(payload))

    def _ingest_webhook(self, payload: dict[str, object]) -> dict[str, object]:
        self.schemas.validate("webhook_ingest_event", payload)
        signature_status = str(payload.get("signature_status", ""))
        if signature_status != "valid":
            raise ControlPlaneError(
                code="WEBHOOK_SIGNATURE_INVALID",
                message="webhook signature_status must be 'valid'",
                status_code=403,
            )

        duplicate_disposition = str(payload.get("duplicate_disposition", ""))
        applied = duplicate_disposition == "APPLIED"

        if applied:
            self.store.save_webhook_event(payload)

        return {
            "hook_event_id": payload["hook_event_id"],
            "trace_id": payload["trace_id"],
            "applied": applied,
            "status": payload["status"],
        }

    def trace_snapshot(self, trace_id: str) -> dict[str, object]:
        return self.store.trace_snapshot(trace_id)

    def _enforce_provider_allowlist(self, *, sensitivity: str, provider: str) -> None:
        allowed = self.provider_allowlist.get(sensitivity)
        if allowed is None:
            raise ControlPlaneError(
                code="SENSITIVITY_POLICY_MISSING",
                message=f"no provider policy for sensitivity '{sensitivity}'",
                status_code=500,
            )
        if provider not in allowed:
            raise ControlPlaneError(
                code="PROVIDER_NOT_ALLOWED",
                message=(
                    f"provider '{provider}' is not allowed for data_sensitivity='{sensitivity}'"
                ),
                status_code=403,
                details={"sensitivity": sensitivity, "provider": provider, "allowlist": list(allowed)},
            )

    def _run_idempotent(
        self,
        route_key: str,
        idempotency_key: str,
        handler: Callable[[], dict[str, object]],
    ) -> dict[str, object]:
        cache_key = f"{route_key}:{idempotency_key}"
        existing = self._idempotency_cache.get(cache_key)
        if existing is not None:
            replay = copy.deepcopy(existing)
            replay["idempotent_replay"] = True
            return replay

        result = handler()
        if not isinstance(result, dict):
            raise ControlPlaneError(
                code="INTERNAL_ERROR",
                message="handler returned non-object payload",
                status_code=500,
            )

        cached = copy.deepcopy(result)
        cached["idempotent_replay"] = False
        self._idempotency_cache[cache_key] = cached
        return copy.deepcopy(cached)
