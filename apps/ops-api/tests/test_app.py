from __future__ import annotations

import unittest
from pathlib import Path

from fastapi.testclient import TestClient

from control_plane.schema_registry import SchemaRegistry
from control_plane.service import ControlPlaneService
from control_plane.store import InMemoryTelemetryStore
from ops_api.app import create_app


def auth_headers(*, token: str = "openclaw-dev-token", idem: str | None = "idem-1") -> dict[str, str]:
    out = {"Authorization": f"Bearer {token}"}
    if idem is not None:
        out["X-Idempotency-Key"] = idem
    return out


def model_payload() -> dict[str, object]:
    return {
        "models": [
            {
                "schema_version": "1.0",
                "model_id": "openrouter-main",
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
        ]
    }


class TestOpsApi(unittest.TestCase):
    def setUp(self) -> None:
        root = Path(__file__).resolve().parents[3]
        schemas = SchemaRegistry(root)
        service = ControlPlaneService(schemas=schemas, store=InMemoryTelemetryStore())
        self.client = TestClient(create_app(service))

    def test_post_requires_bearer_token(self) -> None:
        resp = self.client.post("/v1/model-catalog/sync", json=model_payload())
        self.assertEqual(resp.status_code, 401)
        self.assertEqual(resp.json()["status"], "error")

    def test_post_requires_idempotency_key(self) -> None:
        resp = self.client.post(
            "/v1/model-catalog/sync",
            headers=auth_headers(idem=None),
            json=model_payload(),
        )
        self.assertEqual(resp.status_code, 400)
        self.assertEqual(resp.json()["status"], "error")

    def test_model_sync_and_list_flow(self) -> None:
        sync_resp = self.client.post(
            "/v1/model-catalog/sync",
            headers=auth_headers(idem="mc-1"),
            json=model_payload(),
        )
        self.assertEqual(sync_resp.status_code, 200)
        self.assertEqual(sync_resp.json()["status"], "ok")
        self.assertEqual(sync_resp.json()["data"]["created"], 1)

        list_resp = self.client.get("/v1/model-catalog/models?provider=openrouter")
        self.assertEqual(list_resp.status_code, 200)
        self.assertEqual(list_resp.json()["data"]["total"], 1)

    def test_router_decide_blocks_sensitive_provider_outside_allowlist(self) -> None:
        payload = {
            "schema_version": "1.0",
            "decision_id": "DEC-RT-001",
            "trace_id": "TRACE-001",
            "task_type": "chat",
            "preset_id": "preset://main",
            "risk_class": "medio",
            "risk_tier": "R2",
            "data_sensitivity": "sensitive",
            "policy_filters": {"risk": "R2", "sensitivity": "sensitive", "allowlist": ["ollama"]},
            "ranking_strategy": "capabilities-first",
            "requested_model": "ollama-main",
            "effective_model": "ollama-main",
            "effective_provider": "ollama",
            "provider_routing_applied": {
                "include": ["ollama"],
                "exclude": [],
                "order": ["ollama"],
                "require": [],
            },
            "fallback_step": 0,
            "reason": "candidate-selected",
            "decision_explain": "selected by ranking",
            "pin_provider": False,
            "no_fallback": False,
            "burn_rate_policy": {
                "max_usd_per_hour": 10,
                "circuit_breaker_action": "block_new_runs",
            },
            "privacy_controls": {
                "retention_profile": "zdr_minimal",
                "zdr_enforced": True,
            },
            "created_at": "2026-03-02T12:00:00Z",
        }
        resp = self.client.post(
            "/v1/router/decide",
            headers=auth_headers(idem="rt-1"),
            json=payload,
        )
        self.assertEqual(resp.status_code, 403)
        self.assertEqual(resp.json()["error"]["code"], "PROVIDER_NOT_ALLOWED")

    def test_budget_check_blocks_usage_violation(self) -> None:
        policy = {
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
        snapshot = {
            "schema_version": "1.0",
            "snapshot_id": "SNAP-001",
            "snapshot_at": "2026-03-02T12:00:00Z",
            "billing_source": "litellm",
            "currency": "USD",
            "period_scope": "day",
            "period_limit": 100.0,
            "period_usage": 120.0,
            "balance": 20.0,
            "burn_rate_hour": 5.0,
            "burn_rate_day": 20.0,
            "collected_at": "2026-03-02T12:00:10Z",
        }

        resp = self.client.post(
            "/v1/budget/check",
            headers=auth_headers(idem="bdg-1"),
            json={"policy": policy, "snapshot": snapshot},
        )
        self.assertEqual(resp.status_code, 200)
        self.assertTrue(resp.json()["data"]["blocked"])

    def test_hooks_ingest_rejects_invalid_signature(self) -> None:
        payload = {
            "schema_version": "1.0",
            "hook_event_id": "HOOK-001",
            "trace_id": "TRACE-001",
            "source_hook_id": "hook-main",
            "mapping_id": "map-main",
            "idempotency_key": "idem-hook-001",
            "signature_status": "invalid",
            "signature_alg": "hmac-sha256",
            "signature_key_id": "key-main",
            "duplicate_disposition": "APPLIED",
            "event_type": "task_event",
            "status": "accepted",
            "payload_hash": "abcdef12345678",
            "thread_context": {"issue_id": "ISSUE-1", "microtask_id": "MT-1"},
            "received_at": "2026-03-02T12:00:00Z",
        }

        resp = self.client.post(
            "/v1/hooks/ingest",
            headers=auth_headers(idem="hook-1"),
            json=payload,
        )
        self.assertEqual(resp.status_code, 403)
        self.assertEqual(resp.json()["error"]["code"], "WEBHOOK_SIGNATURE_INVALID")

    def test_hitl_approve_endpoint_requires_payload_contract(self) -> None:
        payload = {
            "decision_id": "DEC-HITL-001",
            "command_id": "CMD-HITL-001",
            "operator_id": "primary-01",
            "channel": "telegram",
            "challenge_id": "CH-HITL-001",
            "signature_or_proof": "valid-proof",
            "evidence_ref": "PM/DECISION-PROTOCOL.md",
            "side_effect_class": "operational",
            "explicit_human_approval": True,
        }
        resp = self.client.post(
            "/internal/hitl/approve",
            headers=auth_headers(idem="hitl-1"),
            json=payload,
        )
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.json()["status"], "ok")
        self.assertEqual(resp.json()["data"]["decision_status"], "APPROVED")

    def test_hitl_financial_requires_explicit_approval(self) -> None:
        payload = {
            "decision_id": "DEC-HITL-002",
            "command_id": "CMD-HITL-002",
            "operator_id": "primary-01",
            "channel": "telegram",
            "challenge_id": "CH-HITL-002",
            "signature_or_proof": "valid-proof",
            "evidence_ref": "PM/DECISION-PROTOCOL.md",
            "side_effect_class": "financial",
            "explicit_human_approval": False,
        }
        resp = self.client.post(
            "/internal/hitl/approve",
            headers=auth_headers(idem="hitl-2"),
            json=payload,
        )
        self.assertEqual(resp.status_code, 422)
        self.assertEqual(resp.json()["error"]["code"], "HTTP_ERROR")

    def test_hitl_requires_command_id_in_payload(self) -> None:
        payload = {
            "decision_id": "DEC-HITL-003",
            "operator_id": "primary-01",
            "channel": "telegram",
            "challenge_id": "CH-HITL-003",
            "signature_or_proof": "valid-proof",
            "evidence_ref": "PM/DECISION-PROTOCOL.md",
            "side_effect_class": "operational",
            "explicit_human_approval": True,
        }
        resp = self.client.post(
            "/internal/hitl/approve",
            headers=auth_headers(idem="hitl-3"),
            json=payload,
        )
        self.assertEqual(resp.status_code, 422)
        self.assertEqual(resp.json()["error"]["code"], "HTTP_ERROR")


if __name__ == "__main__":
    unittest.main()
