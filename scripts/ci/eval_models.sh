#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

search_re() {
  local pattern="$1"
  shift
  if command -v rg >/dev/null 2>&1; then
    rg -n -- "$pattern" "$@" >/dev/null
  else
    grep -nE -- "$pattern" "$@" >/dev/null
  fi
}

search_fixed() {
  local pattern="$1"
  shift
  if command -v rg >/dev/null 2>&1; then
    rg -Fn -- "$pattern" "$@" >/dev/null
  else
    grep -Fn -- "$pattern" "$@" >/dev/null
  fi
}

search_absent_re() {
  local pattern="$1"
  shift
  if command -v rg >/dev/null 2>&1; then
    if rg -n -- "$pattern" "$@" >/dev/null; then
      echo "Padrao proibido encontrado: $pattern"
      exit 1
    fi
  else
    if grep -nE -- "$pattern" "$@" >/dev/null; then
      echo "Padrao proibido encontrado: $pattern"
      exit 1
    fi
  fi
}

python3 -m json.tool ARC/schemas/models_catalog.schema.json >/dev/null

python3 - <<'PY'
import datetime as dt
import json
import sys
from copy import deepcopy
from pathlib import Path


def fail(msg: str) -> None:
    print(msg)
    sys.exit(1)


def parse_iso8601(value: str, field: str) -> None:
    if not isinstance(value, str):
        raise ValueError(f"{field} deve ser string ISO-8601.")
    try:
        dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as exc:
        raise ValueError(f"{field} invalido: {exc}") from exc


def validate_catalog(payload: dict, schema_required: set[str], label: str) -> None:
    missing_required = sorted([field for field in schema_required if field not in payload])
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
    }
    missing_contract = sorted([field for field in required_contract if field not in payload])
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
    if not isinstance(limits.get("max_context"), int) or limits["max_context"] < 1:
        raise ValueError(f"{label} com limits.max_context invalido.")
    if not isinstance(limits.get("max_output_tokens"), int) or limits["max_output_tokens"] < 1:
        raise ValueError(f"{label} com limits.max_output_tokens invalido.")

    pricing = payload["pricing"]
    if not isinstance(pricing, dict):
        raise ValueError(f"{label} com pricing invalido.")
    for field in ("input_per_million", "output_per_million"):
        value = pricing.get(field)
        if not isinstance(value, (int, float)) or value < 0:
            raise ValueError(f"{label} com pricing.{field} invalido.")
    currency = pricing.get("currency")
    if not isinstance(currency, str) or len(currency) != 3:
        raise ValueError(f"{label} com pricing.currency invalido.")

    variants = payload.get("provider_variants")
    if not isinstance(variants, list) or len(variants) == 0:
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

    parse_iso8601(payload["catalog_synced_at"], f"{label}.catalog_synced_at")
    if payload["sync_source"] not in {"models_api", "manual_override", "seed_fixture"}:
        raise ValueError(f"{label} com sync_source invalido.")
    if not isinstance(payload["sync_interval_seconds"], int) or payload["sync_interval_seconds"] < 60:
        raise ValueError(f"{label} com sync_interval_seconds invalido.")


def expect_invalid(payload: dict, schema_required: set[str], label: str) -> None:
    try:
        validate_catalog(payload, schema_required, label)
    except ValueError:
        return
    fail(f"{label} deveria falhar, mas passou.")


schema = json.loads(Path("ARC/schemas/models_catalog.schema.json").read_text(encoding="utf-8"))
schema_required = set(schema.get("required", []))
expected_required = {
    "model_id",
    "provider",
    "capabilities",
    "limits",
    "pricing",
    "status",
    "catalog_synced_at",
    "sync_source",
    "sync_interval_seconds",
}

missing_schema_required = sorted(expected_required - schema_required)
if missing_schema_required:
    fail(f"models_catalog.schema.json sem required obrigatorio: {missing_schema_required}")

props = schema.get("properties", {})
missing_properties = sorted([field for field in expected_required if field not in props])
if missing_properties:
    fail(f"models_catalog.schema.json sem properties obrigatorias: {missing_properties}")

sync_minimum = props.get("sync_interval_seconds", {}).get("minimum")
if not isinstance(sync_minimum, int) or sync_minimum < 60:
    fail("models_catalog.schema.json invalido: sync_interval_seconds.minimum deve ser >= 60.")

valid_payload = {
    "schema_version": "1.0",
    "model_id": "codex-main",
    "provider": "litellm",
    "provider_model_ref": "openai/gpt-5",
    "model_family": "gpt",
    "model_tier": "supervisor",
    "risk_scope": "medio",
    "provider_variants": [
        {
            "provider": "litellm",
            "status": "active",
            "latency_p50": 0.8,
            "latency_p95": 1.2
        }
    ],
    "supported_parameters": {
        "temperature": True,
        "max_output_tokens": True
    },
    "capabilities": {
        "tools": True,
        "structured_output": True,
        "reasoning": True,
        "multimodal": False
    },
    "pricing": {
        "input_per_million": 1.25,
        "output_per_million": 5.00,
        "currency": "USD"
    },
    "limits": {
        "max_context": 128000,
        "max_output_tokens": 4096
    },
    "tags": ["supervisor", "prod"],
    "status": "active",
    "catalog_synced_at": "2026-02-26T10:00:00Z",
    "sync_source": "models_api",
    "sync_interval_seconds": 300,
    "effective_from": "2026-02-26T10:00:00Z",
    "updated_at": "2026-02-26T10:00:01Z",
    "updated_by": "catalog-sync",
    "catalog_version": "catalog-v1"
}

try:
    validate_catalog(valid_payload, schema_required, "valid_payload")
except ValueError as exc:
    fail(str(exc))

invalid_missing_provider = deepcopy(valid_payload)
invalid_missing_provider.pop("provider")
expect_invalid(invalid_missing_provider, schema_required, "invalid_missing_provider")

invalid_missing_sync_metadata = deepcopy(valid_payload)
invalid_missing_sync_metadata.pop("catalog_synced_at")
expect_invalid(invalid_missing_sync_metadata, schema_required, "invalid_missing_sync_metadata")

invalid_missing_model_id = deepcopy(valid_payload)
invalid_missing_model_id.pop("model_id")
expect_invalid(invalid_missing_model_id, schema_required, "invalid_missing_model_id")
PY

required_patterns=(
  "## OpenClaw Gateway e Adapters Cloud"
  "## Provider Variance e Provider Routing"
  "## Fallback Policy"
  "## Presets (governanca central)"
  "## Perfis Oficiais de Execucao"
)
for pattern in "${required_patterns[@]}"; do
  search_fixed "$pattern" ARC/ARC-MODEL-ROUTING.md
done

required_files=(
  "SEC/allowlists/PROVIDERS.yaml"
  "SEC/SEC-POLICY.md"
  "PRD/PRD-MASTER.md"
  "PRD/ROADMAP.md"
  "README.md"
)
for f in "${required_files[@]}"; do
  [[ -f "$f" ]] || { echo "Arquivo obrigatorio ausente: $f"; exit 1; }
done

search_re "chamadas programaticas de inferencia MUST passar pelo gateway OpenClaw" SEC/SEC-POLICY.md
search_re "chamada direta a API de provider externo fora do gateway OpenClaw MUST ser bloqueada" SEC/SEC-POLICY.md
search_re "LiteLLM MUST operar como adaptador padrao para supervisores pagos" SEC/SEC-POLICY.md
search_re "gateway\\.supervisor_adapter.*LiteLLM" PRD/PRD-MASTER.md
search_re "qwen2\\.5-coder:32b" PRD/PRD-MASTER.md
search_re "deepseek-r1:32b" PRD/PRD-MASTER.md
search_fixed "OpenRouter e adaptador cloud opcional, permanece desabilitado por default e so pode ser habilitado por decision formal; quando cloud adicional estiver habilitado, OpenRouter e o preferido." PRD/PRD-MASTER.md ARC/ARC-MODEL-ROUTING.md SEC/SEC-POLICY.md PRD/ROADMAP.md README.md
search_re 'cloud_adapter_default: "disabled"' SEC/allowlists/PROVIDERS.yaml
search_re 'cloud_adapter_enablement: "decision_required"' SEC/allowlists/PROVIDERS.yaml
search_re 'cloud_adapter_preferred_when_enabled: "openrouter"' SEC/allowlists/PROVIDERS.yaml
search_absent_re "OpenRouter e o adaptador padrao recomendado" PRD/PRD-MASTER.md ARC/ARC-MODEL-ROUTING.md PRD/ROADMAP.md README.md
search_absent_re "OpenRouter MAY operar como adaptador cloud recomendado" SEC/SEC-POLICY.md

echo "eval-models: PASS"
