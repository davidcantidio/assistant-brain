from __future__ import annotations

import argparse
from copy import deepcopy
from pathlib import Path

from ci.checks.common import (
    CheckFailure,
    ensure_files,
    load_json,
    parse_iso8601,
    search,
    search_absent,
    search_each_file,
    utc_now,
    write_output,
)


REQUIRED_FILES = (
    "SEC/allowlists/PROVIDERS.yaml",
    "SEC/SEC-POLICY.md",
    "PRD/PRD-MASTER.md",
    "PRD/ROADMAP.md",
    "README.md",
)

REQUIRED_SECTIONS = (
    "## OpenClaw Gateway e Adapters Cloud",
    "## Provider Variance e Provider Routing",
    "## Fallback Policy",
    "## Presets (governanca central)",
    "## Perfis Oficiais de Execucao",
)

OPENROUTER_RULE = (
    "OpenRouter e o adaptador cloud padrao (cloud-first), habilitado por default no runtime cloud e hibrido."
)


def validate_catalog(payload: dict[str, object], schema_required: set[str], label: str) -> None:
    missing_required = sorted(field for field in schema_required if field not in payload)
    if missing_required:
        raise ValueError(f"{label} sem campos obrigatorios: {missing_required}")

    required_contract = {
        "model_id",
        "provider",
        "capabilities",
        "limits",
        "pricing",
        "status",
        "catalog_synced_at",
        "sync_source",
        "sync_interval_seconds",
        "catalog_version",
    }
    missing_contract = sorted(field for field in required_contract if field not in payload)
    if missing_contract:
        raise ValueError(f"{label} sem contrato minimo de catalogo/sync: {missing_contract}")

    if payload["status"] not in {"active", "degraded", "disabled"}:
        raise ValueError(f"{label} com status invalido.")

    capabilities = payload["capabilities"]
    if not isinstance(capabilities, dict):
        raise ValueError(f"{label} com capabilities invalido.")
    for field in ("tools", "structured_output", "reasoning", "multimodal"):
        if not isinstance(capabilities.get(field), bool):
            raise ValueError(f"{label} com capabilities.{field} ausente ou nao-booleano.")

    limits = payload["limits"]
    if not isinstance(limits, dict):
        raise ValueError(f"{label} com limits invalido.")
    if not isinstance(limits.get("max_context"), int) or int(limits["max_context"]) < 1:
        raise ValueError(f"{label} com limits.max_context invalido.")
    if not isinstance(limits.get("max_output_tokens"), int) or int(limits["max_output_tokens"]) < 1:
        raise ValueError(f"{label} com limits.max_output_tokens invalido.")

    pricing = payload["pricing"]
    if not isinstance(pricing, dict):
        raise ValueError(f"{label} com pricing invalido.")
    for field in ("input_per_million", "output_per_million"):
        value = pricing.get(field)
        if not isinstance(value, (int, float)) or float(value) < 0:
            raise ValueError(f"{label} com pricing.{field} invalido.")
    currency = pricing.get("currency")
    if not isinstance(currency, str) or len(currency) != 3:
        raise ValueError(f"{label} com pricing.currency invalido.")

    variants = payload.get("provider_variants")
    if not isinstance(variants, list) or not variants:
        raise ValueError(f"{label} sem provider_variants valido.")
    for idx, variant in enumerate(variants):
        if not isinstance(variant, dict):
            raise ValueError(f"{label} com provider_variants[{idx}] invalido.")
        provider = variant.get("provider")
        if not isinstance(provider, str) or len(provider.strip()) < 2:
            raise ValueError(f"{label} com provider_variants[{idx}].provider invalido.")
        status = variant.get("status")
        if status not in {"active", "degraded", "disabled"}:
            raise ValueError(f"{label} com provider_variants[{idx}].status invalido.")

    parse_iso8601(str(payload["catalog_synced_at"]), f"{label}.catalog_synced_at")
    if payload["sync_source"] not in {"models_api", "manual_override", "seed_fixture"}:
        raise ValueError(f"{label} com sync_source invalido.")
    if not isinstance(payload["sync_interval_seconds"], int) or int(payload["sync_interval_seconds"]) < 60:
        raise ValueError(f"{label} com sync_interval_seconds invalido.")


def validate_router_decision(payload: dict[str, object], schema_required: set[str], label: str) -> None:
    missing_required = sorted(field for field in schema_required if field not in payload)
    if missing_required:
        raise ValueError(f"{label} sem campos obrigatorios: {missing_required}")

    required_audit = {"requested_model", "effective_model", "effective_provider"}
    missing_audit = sorted(field for field in required_audit if field not in payload)
    if missing_audit:
        raise ValueError(f"{label} sem trilha requested/effective: {missing_audit}")

    preset_id = payload.get("preset_id")
    if not isinstance(preset_id, str) or len(preset_id.strip()) < 2:
        raise ValueError(f"{label} com preset_id invalido.")
    if payload.get("risk_class") not in {"baixo", "medio", "alto"}:
        raise ValueError(f"{label} com risk_class invalido.")
    if payload.get("risk_tier") not in {"R0", "R1", "R2", "R3"}:
        raise ValueError(f"{label} com risk_tier invalido.")
    if payload.get("data_sensitivity") not in {"public", "internal", "sensitive"}:
        raise ValueError(f"{label} com data_sensitivity invalido.")

    ranking = payload.get("ranking_strategy")
    if ranking not in {"capabilities-first", "cost-per-success", "balanced"}:
        raise ValueError(f"{label} com ranking_strategy invalido.")

    routing = payload.get("provider_routing_applied")
    if not isinstance(routing, dict):
        raise ValueError(f"{label} com provider_routing_applied invalido.")
    for field in ("include", "exclude", "order", "require"):
        if not isinstance(routing.get(field), list):
            raise ValueError(f"{label} com provider_routing_applied.{field} invalido.")
    if not routing.get("order"):
        raise ValueError(f"{label} com provider_routing_applied.order vazio.")

    fallback_step = payload.get("fallback_step")
    if not isinstance(fallback_step, int) or fallback_step < 0:
        raise ValueError(f"{label} com fallback_step invalido.")
    reason = payload.get("reason")
    if not isinstance(reason, str) or not reason.strip():
        raise ValueError(f"{label} com reason invalido.")
    fallback_reason = payload.get("fallback_reason")
    if fallback_reason is not None:
        if not isinstance(fallback_reason, str) or not fallback_reason.strip():
            raise ValueError(f"{label} com fallback_reason invalido.")
        if fallback_reason != reason:
            raise ValueError(f"{label} com fallback_reason divergente de reason.")

    pin_provider = payload.get("pin_provider")
    if not isinstance(pin_provider, bool):
        raise ValueError(f"{label} com pin_provider invalido.")
    no_fallback = payload.get("no_fallback")
    if not isinstance(no_fallback, bool):
        raise ValueError(f"{label} com no_fallback invalido.")

    burn_rate_policy = payload.get("burn_rate_policy")
    if not isinstance(burn_rate_policy, dict):
        raise ValueError(f"{label} com burn_rate_policy invalido.")
    max_usd_per_hour = burn_rate_policy.get("max_usd_per_hour")
    if not isinstance(max_usd_per_hour, (int, float)) or float(max_usd_per_hour) <= 0:
        raise ValueError(f"{label} com burn_rate_policy.max_usd_per_hour invalido.")
    if burn_rate_policy.get("circuit_breaker_action") not in {
        "block_new_runs",
        "fallback_economic_preset",
    }:
        raise ValueError(f"{label} com burn_rate_policy.circuit_breaker_action invalido.")

    privacy_controls = payload.get("privacy_controls")
    if not isinstance(privacy_controls, dict):
        raise ValueError(f"{label} com privacy_controls invalido.")
    if privacy_controls.get("retention_profile") not in {"standard", "restricted", "zdr_minimal"}:
        raise ValueError(f"{label} com privacy_controls.retention_profile invalido.")
    zdr_enforced = privacy_controls.get("zdr_enforced")
    if not isinstance(zdr_enforced, bool):
        raise ValueError(f"{label} com privacy_controls.zdr_enforced invalido.")

    if payload.get("data_sensitivity") == "sensitive":
        if no_fallback is not True:
            raise ValueError(f"{label} sensivel sem no_fallback=true.")
        if pin_provider is not True:
            raise ValueError(f"{label} sensivel sem pin_provider=true.")
        if zdr_enforced is not True:
            raise ValueError(f"{label} sensivel sem ZDR enforced.")
        if privacy_controls.get("retention_profile") != "zdr_minimal":
            raise ValueError(f"{label} sensivel sem retention_profile=zdr_minimal.")

    parse_iso8601(str(payload["created_at"]), f"{label}.created_at")


def expect_invalid(validator, payload: dict[str, object], schema_required: set[str], label: str) -> None:
    try:
        validator(payload, schema_required, label)
    except ValueError:
        return
    raise ValueError(f"{label} deveria falhar, mas passou.")


def run(root: Path) -> dict[str, object]:
    ensure_files(root, REQUIRED_FILES)

    models_schema = load_json(root, "ARC/schemas/models_catalog.schema.json")
    router_schema = load_json(root, "ARC/schemas/router_decision.schema.json")

    models_required = set(models_schema.get("required", []))
    expected_model_required = {
        "model_id",
        "provider",
        "capabilities",
        "limits",
        "pricing",
        "status",
        "catalog_synced_at",
        "sync_source",
        "sync_interval_seconds",
        "catalog_version",
    }
    missing_schema_required = sorted(expected_model_required - models_required)
    if missing_schema_required:
        raise ValueError(f"models_catalog.schema.json sem required obrigatorio: {missing_schema_required}")

    props = models_schema.get("properties", {})
    if not isinstance(props, dict):
        raise ValueError("models_catalog.schema.json sem properties obrigatorias.")
    missing_properties = sorted(field for field in expected_model_required if field not in props)
    if missing_properties:
        raise ValueError(f"models_catalog.schema.json sem properties obrigatorias: {missing_properties}")
    sync_minimum = props.get("sync_interval_seconds", {}).get("minimum")
    if not isinstance(sync_minimum, int) or sync_minimum < 60:
        raise ValueError("models_catalog.schema.json invalido: sync_interval_seconds.minimum deve ser >= 60.")

    valid_catalog = {
        "schema_version": "1.0",
        "model_id": "openrouter-main",
        "provider": "litellm",
        "provider_model_ref": "openrouter/openai/gpt-4o-mini",
        "model_family": "gpt",
        "model_tier": "supervisor",
        "risk_scope": "medio",
        "provider_variants": [{"provider": "litellm", "status": "active", "latency_p50": 0.8, "latency_p95": 1.2}],
        "supported_parameters": {"temperature": True, "max_output_tokens": True},
        "capabilities": {"tools": True, "structured_output": True, "reasoning": True, "multimodal": False},
        "pricing": {"input_per_million": 1.25, "output_per_million": 5.0, "currency": "USD"},
        "limits": {"max_context": 128000, "max_output_tokens": 4096},
        "tags": ["supervisor", "prod"],
        "status": "active",
        "catalog_synced_at": "2026-02-26T10:00:00Z",
        "sync_source": "models_api",
        "sync_interval_seconds": 300,
        "effective_from": "2026-02-26T10:00:00Z",
        "updated_at": "2026-02-26T10:00:01Z",
        "updated_by": "catalog-sync",
        "catalog_version": "catalog-v1",
    }
    validate_catalog(valid_catalog, models_required, "valid_payload")
    invalid_missing_provider = deepcopy(valid_catalog)
    invalid_missing_provider.pop("provider")
    expect_invalid(validate_catalog, invalid_missing_provider, models_required, "invalid_missing_provider")
    invalid_missing_sync = deepcopy(valid_catalog)
    invalid_missing_sync.pop("catalog_synced_at")
    expect_invalid(validate_catalog, invalid_missing_sync, models_required, "invalid_missing_sync_metadata")
    invalid_missing_model = deepcopy(valid_catalog)
    invalid_missing_model.pop("model_id")
    expect_invalid(validate_catalog, invalid_missing_model, models_required, "invalid_missing_model_id")

    router_required = set(router_schema.get("required", []))
    expected_router_required = {
        "preset_id",
        "requested_model",
        "effective_model",
        "effective_provider",
        "reason",
        "pin_provider",
        "no_fallback",
        "burn_rate_policy",
        "privacy_controls",
    }
    missing_router_required = sorted(expected_router_required - router_required)
    if missing_router_required:
        raise ValueError(f"router_decision.schema.json sem required obrigatorio: {missing_router_required}")

    valid_router = {
        "schema_version": "1.0",
        "decision_id": "ROUTER-DEC-001",
        "trace_id": "TRACE-ROUTER-001",
        "task_type": "dev_patch",
        "preset_id": "preset.dev_patch_v1",
        "risk_class": "medio",
        "risk_tier": "R2",
        "data_sensitivity": "internal",
        "policy_filters": {"risk": "R2", "sensitivity": "internal", "allowlist": ["litellm", "ollama"]},
        "ranking_strategy": "capabilities-first",
        "requested_model": "openrouter-main",
        "effective_model": "openrouter-main",
        "effective_provider": "litellm",
        "provider_routing_applied": {"include": ["litellm", "ollama"], "exclude": [], "order": ["litellm", "ollama"], "require": []},
        "fallback_step": 0,
        "reason": "primary_available",
        "fallback_reason": "primary_available",
        "candidates_considered": [{"model": "openrouter-main", "provider": "litellm", "score": 0.94}],
        "decision_explain": "cloud-first com fallback local quando necessario.",
        "pin_provider": False,
        "no_fallback": False,
        "burn_rate_policy": {"max_usd_per_hour": 5.0, "circuit_breaker_action": "fallback_economic_preset"},
        "privacy_controls": {"retention_profile": "restricted", "zdr_enforced": False},
        "created_at": "2026-02-26T10:15:00Z",
    }
    validate_router_decision(valid_router, router_required, "valid_router_decision")
    invalid_missing_requested = deepcopy(valid_router)
    invalid_missing_requested.pop("requested_model")
    expect_invalid(validate_router_decision, invalid_missing_requested, router_required, "invalid_missing_requested")
    invalid_missing_effective = deepcopy(valid_router)
    invalid_missing_effective.pop("effective_model")
    expect_invalid(validate_router_decision, invalid_missing_effective, router_required, "invalid_missing_effective")
    invalid_missing_provider = deepcopy(valid_router)
    invalid_missing_provider.pop("effective_provider")
    expect_invalid(validate_router_decision, invalid_missing_provider, router_required, "invalid_missing_provider")
    invalid_missing_reason = deepcopy(valid_router)
    invalid_missing_reason.pop("reason")
    expect_invalid(validate_router_decision, invalid_missing_reason, router_required, "invalid_missing_reason")
    invalid_sensitive = deepcopy(valid_router)
    invalid_sensitive["data_sensitivity"] = "sensitive"
    invalid_sensitive["pin_provider"] = True
    invalid_sensitive["no_fallback"] = True
    invalid_sensitive["privacy_controls"]["retention_profile"] = "restricted"
    invalid_sensitive["privacy_controls"]["zdr_enforced"] = False
    expect_invalid(validate_router_decision, invalid_sensitive, router_required, "invalid_sensitive_without_zdr")

    for section in REQUIRED_SECTIONS:
        search_each_file(root, section, ["ARC/ARC-MODEL-ROUTING.md"], fixed=True)

    search(root, r"chamadas programaticas de inferencia MUST passar pelo gateway OpenClaw", ["SEC/SEC-POLICY.md"])
    search(root, r"chamada direta a API de provider externo fora do gateway OpenClaw MUST ser bloqueada", ["SEC/SEC-POLICY.md"])
    search(root, r"LiteLLM MUST operar como adaptador padrao para supervisores pagos", ["SEC/SEC-POLICY.md"])
    search(root, r"gateway\.supervisor_adapter.*LiteLLM", ["PRD/PRD-MASTER.md"])
    search(root, r"qwen2\.5:7b-instruct-q8_0", ["PRD/PRD-MASTER.md"])
    search(root, r"preset_id", ["ARC/ARC-MODEL-ROUTING.md", "PRD/PRD-MASTER.md"])
    search(root, r"burn-rate|circuit breaker", ["ARC/ARC-MODEL-ROUTING.md", "PRD/PRD-MASTER.md", "EVALS/SYSTEM-HEALTH-THRESHOLDS.md"])
    search(root, r"fallback_step.*reason|reason.*fallback_step", ["ARC/ARC-MODEL-ROUTING.md", "PRD/PRD-MASTER.md", "EVALS/SYSTEM-HEALTH-THRESHOLDS.md"])
    search(root, r"sensitive.*no_fallback.*pin_provider.*ZDR|no_fallback.*pin_provider.*ZDR", ["ARC/ARC-MODEL-ROUTING.md", "SEC/SEC-POLICY.md"])
    search_each_file(root, OPENROUTER_RULE, ["PRD/PRD-MASTER.md", "ARC/ARC-MODEL-ROUTING.md", "SEC/SEC-POLICY.md", "PRD/ROADMAP.md", "README.md"], fixed=True)
    search(root, r'cloud_adapter_default: "enabled"', ["SEC/allowlists/PROVIDERS.yaml"])
    search(root, r'cloud_adapter_enablement: "default_on"', ["SEC/allowlists/PROVIDERS.yaml"])
    search(root, r'cloud_adapter_primary: "openrouter"', ["SEC/allowlists/PROVIDERS.yaml"])
    search_absent(root, r"OpenRouter e adaptador cloud opcional, permanece desabilitado por default", ["PRD/PRD-MASTER.md", "ARC/ARC-MODEL-ROUTING.md", "PRD/ROADMAP.md", "README.md", "SEC/SEC-POLICY.md"])

    return {
        "schema_version": "1.0",
        "check_id": "eval-models",
        "status": "PASS",
        "validated_at": utc_now(),
        "validated_files": sorted(REQUIRED_FILES),
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate model and routing contracts")
    parser.add_argument("--root", default=".")
    parser.add_argument("--output")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = Path(args.root).resolve()
    output_path = Path(args.output).resolve() if args.output else None
    try:
        payload = run(root)
    except (CheckFailure, ValueError) as exc:
        if output_path is not None:
            write_output(output_path, {"schema_version": "1.0", "check_id": "eval-models", "status": "FAIL", "validated_at": utc_now(), "error": str(exc)})
        print(str(exc))
        return 1

    write_output(output_path, payload)
    print("eval-models: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
