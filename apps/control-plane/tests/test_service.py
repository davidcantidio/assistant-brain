from __future__ import annotations

import unittest
from pathlib import Path

from control_plane.errors import ControlPlaneError
from control_plane.schema_registry import SchemaRegistry
from control_plane.service import ControlPlaneService
from control_plane.store import InMemoryTelemetryStore


def valid_model(model_id: str = "openrouter-main") -> dict[str, object]:
    return {
        "schema_version": "1.0",
        "model_id": model_id,
        "provider": "openrouter",
        "provider_model_ref": "openrouter/openai/gpt-4o-mini",
        "openrouter_model_id": "openai/gpt-4o-mini",
        "model_family": "gpt-4o",
        "model_tier": "main",
        "risk_scope": "medio",
        "provider_variants": [{"provider": "openrouter", "status": "active"}],
        "supported_parameters": {"temperature": True},
        "capabilities": {
            "tools": True,
            "structured_output": True,
            "reasoning": True,
            "multimodal": False,
        },
        "pricing": {
            "input_per_million": 0.2,
            "output_per_million": 0.8,
            "currency": "USD",
        },
        "limits": {"max_context": 128000, "max_output_tokens": 4096},
        "tags": ["baseline"],
        "status": "active",
        "catalog_synced_at": "2026-03-02T12:00:00Z",
        "sync_source": "seed_fixture",
        "sync_interval_seconds": 3600,
        "effective_from": "2026-03-02T12:00:00Z",
        "effective_to": None,
        "updated_at": "2026-03-02T12:00:00Z",
        "updated_by": "ops-api",
        "catalog_version": "v1",
    }


def valid_router_decision(*, provider: str = "openrouter") -> dict[str, object]:
    return {
        "schema_version": "1.0",
        "decision_id": "DEC-RT-001",
        "trace_id": "TRACE-001",
        "task_type": "chat",
        "preset_id": "preset://main",
        "risk_class": "medio",
        "risk_tier": "R2",
        "data_sensitivity": "sensitive",
        "policy_filters": {"risk": "R2", "sensitivity": "sensitive", "allowlist": [provider]},
        "ranking_strategy": "capabilities-first",
        "requested_model": "openrouter-main",
        "effective_model": "openrouter-main",
        "effective_provider": provider,
        "provider_routing_applied": {
            "include": [provider],
            "exclude": [],
            "order": [provider],
            "require": [],
        },
        "fallback_step": 0,
        "reason": "policy-allowlist",
        "decision_explain": "selected by capabilities and risk policy",
        "pin_provider": False,
        "no_fallback": False,
        "burn_rate_policy": {
            "max_usd_per_hour": 50,
            "circuit_breaker_action": "block_new_runs",
        },
        "privacy_controls": {
            "retention_profile": "zdr_minimal",
            "zdr_enforced": True,
        },
        "created_at": "2026-03-02T12:00:00Z",
    }


def valid_llm_run() -> dict[str, object]:
    return {
        "schema_version": "1.0",
        "run_id": "RUN-001",
        "trace_id": "TRACE-001",
        "task_id": "TASK-001",
        "agent_id": "agent-main",
        "session_id": "session-main",
        "requested_model": "openrouter-main",
        "effective_model": "openrouter-main",
        "effective_provider": "openrouter",
        "preset_id": "preset://main",
        "fallback_step": 0,
        "retry_count": 0,
        "prompt_hash": "12345678abcdef",
        "prompt_summary": "resumo sanitizado",
        "finish_reason": "stop",
        "parse_status": "ok",
        "usage": {
            "prompt_tokens": 100,
            "completion_tokens": 80,
            "total_tokens": 180,
            "total_cost_usd": 0.02,
            "latency_ms": 450,
        },
        "outcome": {"status": "success", "score": 0.95},
        "started_at": "2026-03-02T12:00:00Z",
        "completed_at": "2026-03-02T12:00:01Z",
    }


def valid_snapshot(*, usage: float = 10.0) -> dict[str, object]:
    return {
        "schema_version": "1.0",
        "snapshot_id": "SNAP-001",
        "snapshot_at": "2026-03-02T12:00:00Z",
        "billing_source": "litellm",
        "currency": "USD",
        "period_scope": "day",
        "period_limit": 100.0,
        "period_usage": usage,
        "balance": 90.0,
        "burn_rate_hour": 5.0,
        "burn_rate_day": 20.0,
        "collected_at": "2026-03-02T12:00:10Z",
    }


def valid_budget_policy() -> dict[str, object]:
    return {
        "schema_version": "1.0",
        "policy_id": "BUDGET-001",
        "scope": "workspace",
        "currency": "USD",
        "telemetry_source": "litellm_aggregated",
        "provider_snapshot_source": "effective_provider_snapshot",
        "limits": {"run_usd": 1.0, "task_usd": 5.0, "day_usd": 100.0},
        "snapshot_contract": {
            "entity": "credits_snapshots",
            "schema_ref": "ARC/schemas/credits_snapshot.schema.json",
            "freshness_minutes_max": 999999,
            "required_fields": [
                "snapshot_at",
                "period_limit",
                "period_usage",
                "balance",
                "burn_rate_hour",
                "burn_rate_day",
            ],
        },
        "burn_rate_policy": {
            "hour_threshold_usd": 10.0,
            "day_threshold_usd": 50.0,
            "circuit_breaker_action": "block_new_runs",
        },
        "enforcement": {
            "block_without_limits": True,
            "block_with_stale_snapshot": True,
            "violation_actions": ["block_non_critical"],
        },
        "updated_at": "2026-03-02T12:00:00Z",
        "updated_by": "ops-api",
    }


def valid_a2a(*, allowed: bool = True) -> dict[str, object]:
    return {
        "schema_version": "1.0",
        "delegation_id": "A2A-001",
        "trace_id": "TRACE-001",
        "requester_agent": "agent-main",
        "target_agent": "agent-review",
        "source_workspace": "main",
        "target_workspace": "ops",
        "allowlist_entry": "main->ops",
        "allowed": allowed,
        "max_concurrency": 2,
        "max_cost_usd": 3.0,
        "serial_fallback_on_conflict": True,
        "status": "queued",
        "created_at": "2026-03-02T12:00:00Z",
    }


def valid_webhook(*, signature_status: str = "valid") -> dict[str, object]:
    return {
        "schema_version": "1.0",
        "hook_event_id": "HOOK-001",
        "trace_id": "TRACE-001",
        "source_hook_id": "hook-main",
        "mapping_id": "map-main",
        "idempotency_key": "idem-hook-001",
        "signature_status": signature_status,
        "signature_alg": "hmac-sha256",
        "signature_key_id": "key-main",
        "duplicate_disposition": "APPLIED",
        "event_type": "task_event",
        "status": "accepted",
        "payload_hash": "abcdef12345678",
        "thread_context": {"issue_id": "ISSUE-1", "microtask_id": "MT-1"},
        "received_at": "2026-03-02T12:00:00Z",
    }


class TestControlPlaneService(unittest.TestCase):
    def setUp(self) -> None:
        root = Path(__file__).resolve().parents[3]
        schemas = SchemaRegistry(root)
        self.service = ControlPlaneService(schemas=schemas, store=InMemoryTelemetryStore())

    def test_model_catalog_sync_is_idempotent_and_detects_noop(self) -> None:
        payload = {"models": [valid_model()]}
        first = self.service.sync_model_catalog(payload, idempotency_key="sync-1")
        second = self.service.sync_model_catalog(payload, idempotency_key="sync-2")
        replay = self.service.sync_model_catalog(payload, idempotency_key="sync-2")

        self.assertEqual(first["created"], 1)
        self.assertFalse(first["idempotent_replay"])
        self.assertEqual(second["noop"], 1)
        self.assertFalse(second["idempotent_replay"])
        self.assertTrue(replay["idempotent_replay"])

    def test_router_decision_blocks_provider_outside_allowlist_for_sensitive(self) -> None:
        with self.assertRaises(ControlPlaneError) as ctx:
            self.service.decide_router(valid_router_decision(provider="ollama"), idempotency_key="rt-1")
        self.assertEqual(ctx.exception.code, "PROVIDER_NOT_ALLOWED")

    def test_trace_snapshot_correlates_router_and_run(self) -> None:
        decision = valid_router_decision(provider="openrouter")
        self.service.decide_router(decision, idempotency_key="rt-2")
        self.service.ingest_run(valid_llm_run(), idempotency_key="run-1")

        snapshot = self.service.trace_snapshot("TRACE-001")
        self.assertEqual(len(snapshot["router_decisions"]), 1)
        self.assertEqual(len(snapshot["llm_runs"]), 1)

    def test_budget_check_blocks_when_snapshot_exceeds_limits(self) -> None:
        policy = valid_budget_policy()
        high_usage = valid_snapshot(usage=140.0)

        result = self.service.check_budget(
            {"policy": policy, "snapshot": high_usage},
            idempotency_key="budget-1",
        )

        self.assertTrue(result["blocked"])
        self.assertIn("period_usage_exceeds_period_limit", result["violations"])

    def test_a2a_blocks_when_not_allowed(self) -> None:
        with self.assertRaises(ControlPlaneError) as ctx:
            self.service.delegate_a2a(valid_a2a(allowed=False), idempotency_key="a2a-1")
        self.assertEqual(ctx.exception.code, "A2A_NOT_ALLOWED")

    def test_webhook_rejects_invalid_signature(self) -> None:
        with self.assertRaises(ControlPlaneError) as ctx:
            self.service.ingest_webhook(valid_webhook(signature_status="invalid"), idempotency_key="hook-1")
        self.assertEqual(ctx.exception.code, "WEBHOOK_SIGNATURE_INVALID")


if __name__ == "__main__":
    unittest.main()
