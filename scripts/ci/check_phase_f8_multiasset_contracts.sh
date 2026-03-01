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

search_re_each_file() {
  local pattern="$1"
  shift
  local file
  for file in "$@"; do
    if ! search_re "$pattern" "$file"; then
      echo "Padrao obrigatorio ausente em $file: $pattern"
      exit 1
    fi
  done
}

required_files=(
  "ARC/schemas/asset_profile.schema.json"
  "ARC/schemas/venue_adapter.schema.json"
  "VERTICALS/TRADING/asset_profiles/equities_br.json"
  "VERTICALS/TRADING/asset_profiles/fii_br.json"
  "VERTICALS/TRADING/asset_profiles/fixed_income_br.json"
  "VERTICALS/TRADING/venue_adapters/equities_br.json"
  "VERTICALS/TRADING/venue_adapters/fii_br.json"
  "VERTICALS/TRADING/venue_adapters/fixed_income_br.json"
  "VERTICALS/TRADING/TRADING-PRD.md"
  "VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md"
  "VERTICALS/TRADING/TRADING-RISK-RULES.md"
  "SEC/allowlists/DOMAINS.yaml"
)

for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || { echo "Arquivo obrigatorio ausente: $file"; exit 1; }
done

json_files=(
  "ARC/schemas/asset_profile.schema.json"
  "ARC/schemas/venue_adapter.schema.json"
  "VERTICALS/TRADING/asset_profiles/equities_br.json"
  "VERTICALS/TRADING/asset_profiles/fii_br.json"
  "VERTICALS/TRADING/asset_profiles/fixed_income_br.json"
  "VERTICALS/TRADING/venue_adapters/equities_br.json"
  "VERTICALS/TRADING/venue_adapters/fii_br.json"
  "VERTICALS/TRADING/venue_adapters/fixed_income_br.json"
)

for file in "${json_files[@]}"; do
  python3 -m json.tool "$file" >/dev/null
done

python3 - <<'PY'
import json
import sys
from pathlib import Path


ROOT = Path(".")


def fail(message: str) -> None:
    print(message)
    sys.exit(1)


def load_json(path: str) -> dict:
    with (ROOT / path).open("r", encoding="utf-8") as handle:
        return json.load(handle)


def assert_schema_fields(path: str, expected_required: list[str], expected_properties: list[str]) -> None:
    schema = load_json(path)
    required = schema.get("required")
    properties = schema.get("properties")
    if not isinstance(required, list):
        fail(f"{path} com required invalido.")
    if not isinstance(properties, dict):
        fail(f"{path} com properties invalido.")
    missing_required = [item for item in expected_required if item not in required]
    missing_properties = [item for item in expected_properties if item not in properties]
    if missing_required:
        fail(f"{path} sem required obrigatorio: {', '.join(missing_required)}")
    if missing_properties:
        fail(f"{path} sem property obrigatoria: {', '.join(missing_properties)}")


def assert_positive_number(value: object, label: str) -> None:
    if not isinstance(value, (int, float)) or value <= 0:
        fail(f"{label} deve ser numero > 0.")


asset_profile_schema = "ARC/schemas/asset_profile.schema.json"
venue_adapter_schema = "ARC/schemas/venue_adapter.schema.json"

assert_schema_fields(
    asset_profile_schema,
    [
        "schema_version",
        "contract_version",
        "asset_class",
        "profile_version",
        "market_calendar",
        "market_sessions",
        "order_constraints",
        "rounding_rules",
        "cost_model",
        "liquidity_controls",
        "risk_units",
        "capital_ramp_defaults",
    ],
    [
        "schema_version",
        "contract_version",
        "asset_class",
        "profile_version",
        "market_calendar",
        "market_sessions",
        "order_constraints",
        "rounding_rules",
        "cost_model",
        "liquidity_controls",
        "risk_units",
        "capital_ramp_defaults",
    ],
)
assert_schema_fields(
    venue_adapter_schema,
    [
        "schema_version",
        "contract_version",
        "adapter_id",
        "asset_class",
        "venue_type",
        "execution_path",
        "allowlist_group",
        "supported_order_types",
        "shadow_mode_required",
        "decision_r3_required_for_live",
        "status",
    ],
    [
        "schema_version",
        "contract_version",
        "adapter_id",
        "asset_class",
        "venue_type",
        "execution_path",
        "allowlist_group",
        "supported_order_types",
        "shadow_mode_required",
        "decision_r3_required_for_live",
        "status",
    ],
)

expected_asset_classes = {"equities_br", "fii_br", "fixed_income_br"}
seen_asset_classes = set()

for asset_class in sorted(expected_asset_classes):
    payload = load_json(f"VERTICALS/TRADING/asset_profiles/{asset_class}.json")
    if payload.get("schema_version") != "1.0":
        fail(f"asset_profile de {asset_class} com schema_version invalido.")
    if payload.get("contract_version") != "v1":
        fail(f"asset_profile de {asset_class} com contract_version invalido.")
    if payload.get("asset_class") != asset_class:
        fail(f"asset_profile de {asset_class} com asset_class divergente.")
    seen_asset_classes.add(asset_class)
    if not isinstance(payload.get("market_sessions"), list) or not payload["market_sessions"]:
        fail(f"asset_profile de {asset_class} sem market_sessions.")
    order_constraints = payload.get("order_constraints")
    if not isinstance(order_constraints, dict):
        fail(f"asset_profile de {asset_class} sem order_constraints.")
    for field in ("min_notional", "lot_size", "tick_size"):
        assert_positive_number(order_constraints.get(field), f"{asset_class}.order_constraints.{field}")
    cost_model = payload.get("cost_model")
    if not isinstance(cost_model, dict):
        fail(f"asset_profile de {asset_class} sem cost_model.")
    for field in ("base_fee_bps", "emoluments_bps", "taxes_bps", "slippage_bps"):
        value = cost_model.get(field)
        if not isinstance(value, (int, float)) or value < 0:
            fail(f"{asset_class}.cost_model.{field} deve ser numero >= 0.")
    liquidity_controls = payload.get("liquidity_controls")
    if not isinstance(liquidity_controls, dict):
        fail(f"asset_profile de {asset_class} sem liquidity_controls.")
    for field in ("max_spread_bps", "min_average_daily_volume_brl"):
        value = liquidity_controls.get(field)
        if not isinstance(value, (int, float)) or value < 0:
            fail(f"{asset_class}.liquidity_controls.{field} deve ser numero >= 0.")
    risk_units = payload.get("risk_units")
    if not isinstance(risk_units, dict):
        fail(f"asset_profile de {asset_class} sem risk_units.")
    for field in ("quote_currency", "quantity_unit"):
        value = risk_units.get(field)
        if not isinstance(value, str) or not value.strip():
            fail(f"{asset_class}.risk_units.{field} deve ser string nao vazia.")
    if asset_class == "fixed_income_br":
        assert_positive_number(
            risk_units.get("max_loss_per_unit_brl"),
            "fixed_income_br.risk_units.max_loss_per_unit_brl",
        )
    ramp_defaults = payload.get("capital_ramp_defaults")
    if not isinstance(ramp_defaults, dict) or "L0" not in ramp_defaults:
        fail(f"asset_profile de {asset_class} sem capital_ramp_defaults.L0.")
    l0 = ramp_defaults["L0"]
    if not isinstance(l0, dict):
        fail(f"asset_profile de {asset_class} com L0 invalido.")
    for field in ("max_notional_per_order", "max_daily_notional", "max_orders_per_day"):
        assert_positive_number(l0.get(field), f"{asset_class}.capital_ramp_defaults.L0.{field}")

if seen_asset_classes != expected_asset_classes:
    fail("asset_profiles sem cobertura exata das classes obrigatorias.")

seen_adapter_classes = set()
for asset_class in sorted(expected_asset_classes):
    payload = load_json(f"VERTICALS/TRADING/venue_adapters/{asset_class}.json")
    if payload.get("schema_version") != "1.0":
        fail(f"venue_adapter de {asset_class} com schema_version invalido.")
    if payload.get("contract_version") != "v1":
        fail(f"venue_adapter de {asset_class} com contract_version invalido.")
    if payload.get("asset_class") != asset_class:
        fail(f"venue_adapter de {asset_class} com asset_class divergente.")
    seen_adapter_classes.add(asset_class)
    if payload.get("execution_path") != "execution_gateway_only":
        fail(f"venue_adapter de {asset_class} deve usar execution_gateway_only.")
    if payload.get("allowlist_group") != "trading_phase2_brokers":
        fail(f"venue_adapter de {asset_class} deve usar allowlist_group=trading_phase2_brokers.")
    if payload.get("status") != "blocked":
        fail(f"venue_adapter de {asset_class} deve permanecer blocked nesta rodada.")
    if payload.get("shadow_mode_required") is not True:
        fail(f"venue_adapter de {asset_class} deve exigir shadow_mode.")
    if payload.get("decision_r3_required_for_live") is not True:
        fail(f"venue_adapter de {asset_class} deve exigir decision R3 para live.")
    order_types = payload.get("supported_order_types")
    if not isinstance(order_types, list) or not order_types:
        fail(f"venue_adapter de {asset_class} sem supported_order_types.")

if seen_adapter_classes != expected_asset_classes:
    fail("venue_adapters sem cobertura exata das classes obrigatorias.")
PY

search_re '^  trading_phase2_brokers:' SEC/allowlists/DOMAINS.yaml
search_re_each_file 'VERTICALS/TRADING/asset_profiles/' \
  VERTICALS/TRADING/TRADING-PRD.md \
  VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md \
  VERTICALS/TRADING/TRADING-RISK-RULES.md
search_re_each_file 'VERTICALS/TRADING/venue_adapters/' \
  VERTICALS/TRADING/TRADING-PRD.md \
  VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md \
  VERTICALS/TRADING/TRADING-RISK-RULES.md
search_re 'trading_phase2_brokers' VERTICALS/TRADING/TRADING-PRD.md

echo "phase-f8-multiasset-contracts: PASS"
