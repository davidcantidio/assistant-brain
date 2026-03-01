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
  local f
  for f in "$@"; do
    if ! search_re "$pattern" "$f"; then
      echo "Padrao obrigatorio ausente em $f: $pattern"
      exit 1
    fi
  done
}

schema_assert_minimum_contract() {
  local schema_path="$1"
  local required_csv="$2"
  local properties_csv="$3"

  python3 - "$schema_path" "$required_csv" "$properties_csv" <<'PY'
import json
import sys

schema_path, required_csv, properties_csv = sys.argv[1:4]

with open(schema_path, "r", encoding="utf-8") as fh:
    schema = json.load(fh)

required = schema.get("required", [])
properties = schema.get("properties", {})

if not isinstance(required, list):
    print(f"Schema contract check failed: {schema_path}")
    print("required MUST be a JSON array.")
    sys.exit(1)

if not isinstance(properties, dict):
    print(f"Schema contract check failed: {schema_path}")
    print("properties MUST be a JSON object.")
    sys.exit(1)

expected_required = [item for item in required_csv.split(",") if item]
expected_properties = [item for item in properties_csv.split(",") if item]

missing_required = [item for item in expected_required if item not in required]
missing_properties = [item for item in expected_properties if item not in properties]

if missing_required or missing_properties:
    print(f"Schema contract check failed: {schema_path}")
    if missing_required:
        print("missing required[] entries: " + ", ".join(missing_required))
    if missing_properties:
        print("missing properties entries: " + ", ".join(missing_properties))
    sys.exit(1)
PY
}

schema_assert_versioned_contract() {
  local schema_path="$1"

  python3 - "$schema_path" <<'PY'
import json
import sys

schema_path = sys.argv[1]

with open(schema_path, "r", encoding="utf-8") as fh:
    schema = json.load(fh)

def fail(msg):
    print(f"Schema version contract check failed: {schema_path}")
    print(msg)
    sys.exit(1)

required = schema.get("required", [])
if not isinstance(required, list):
    fail("required MUST be a JSON array.")

for field in ("schema_version", "contract_version"):
    if field not in required:
        fail(f"required MUST include '{field}'.")

properties = schema.get("properties", {})
if not isinstance(properties, dict):
    fail("properties MUST be a JSON object.")

schema_version = properties.get("schema_version")
if not isinstance(schema_version, dict):
    fail("properties.schema_version MUST exist.")
if schema_version.get("type") != "string":
    fail("properties.schema_version.type MUST be 'string'.")
if schema_version.get("const") != "1.0":
    fail("properties.schema_version.const MUST be '1.0'.")

contract_version = properties.get("contract_version")
if not isinstance(contract_version, dict):
    fail("properties.contract_version MUST exist.")
if contract_version.get("type") != "string":
    fail("properties.contract_version.type MUST be 'string'.")
if contract_version.get("const") != "v1":
    fail("properties.contract_version.const MUST be 'v1'.")
PY
}

required_files=(
  "VERTICALS/TRADING/TRADING-PRD.md"
  "VERTICALS/TRADING/TRADING-RISK-RULES.md"
  "VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md"
  "ARC/ARC-DEGRADED-MODE.md"
  "INCIDENTS/DEGRADED-MODE-PROCEDURE.md"
  "SEC/allowlists/ACTIONS.yaml"
  "SEC/allowlists/DOMAINS.yaml"
  ".github/workflows/ci-trading.yml"
  "ARC/schemas/execution_gateway.schema.json"
  "ARC/schemas/pre_trade_validator.schema.json"
)
for f in "${required_files[@]}"; do
  [[ -f "$f" ]] || { echo "Arquivo obrigatorio ausente: $f"; exit 1; }
done

schema_files=(
  "ARC/schemas/execution_gateway.schema.json"
  "ARC/schemas/pre_trade_validator.schema.json"
)
for s in "${schema_files[@]}"; do
  python3 -m json.tool "$s" >/dev/null
done

schema_assert_versioned_contract "ARC/schemas/execution_gateway.schema.json"
schema_assert_versioned_contract "ARC/schemas/pre_trade_validator.schema.json"

schema_assert_minimum_contract \
  "ARC/schemas/execution_gateway.schema.json" \
  "schema_version,contract_version,order_intent_id,client_order_id,idempotency_key,asset_class,symbol,side,order_type,quantity,stop_price,risk_tier,decision_id" \
  "schema_version,contract_version,order_intent_id,client_order_id,idempotency_key,asset_class,symbol,side,order_type,quantity,price,stop_price,risk_tier,decision_id,execution_id,venue_order_id,status,filled_quantity,avg_fill_price,reject_reason,replay_disposition,reconciliation_status,reconciliation_trace_id,position_snapshot_ref"

schema_assert_minimum_contract \
  "ARC/schemas/pre_trade_validator.schema.json" \
  "schema_version,contract_version,asset_profile_version,capital_ramp_level,symbol,symbol_constraints,order_intent,market_state,validator_status,block_reasons,normalized_order,effective_risk_quote" \
  "schema_version,contract_version,asset_profile_version,capital_ramp_level,symbol,symbol_constraints,order_intent,market_state,validator_status,block_reasons,normalized_order,effective_risk_quote"

search_re "S0 - Paper/Sandbox" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md
search_re "execution_gateway" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md
search_re "pre_trade_validator" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md
search_re 'execution_gateway` \(v1 minimo\)' VERTICALS/TRADING/TRADING-PRD.md
search_re 'pre_trade_validator` \(v1 minimo\)' VERTICALS/TRADING/TRADING-PRD.md
search_re 'symbol_constraints' VERTICALS/TRADING/TRADING-PRD.md
search_re_each_file "client_order_id" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md
search_re_each_file "replay.*client_order_id.*idempotency_key.*no-op.*auditavel" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md
search_re_each_file "falha parcial.*estado final consistente.*auditavel" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md
search_re_each_file "fail_closed.*engine primaria|engine primaria.*fail_closed" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-RISK-RULES.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md
search_re_each_file "single_engine_mode.*engine secundaria|engine secundaria.*single_engine_mode" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-RISK-RULES.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md
search_re_each_file "single_engine_mode.*primaria.*saudavel" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-RISK-RULES.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md
search_re_each_file "TradingAgents.*engine primaria de sinal" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md
search_re_each_file "AI-Trader -> signal_intent -> normalizacao/deduplicacao -> pre_trade_validator -> HITL -> execution_gateway" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md
search_re_each_file "ordem direta originada do AI-Trader MUST ser rejeitado e auditado" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md
search_re_each_file 'caminho de execucao unico confirmado: somente `execution_gateway` pode enviar ordem live' VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md
search_re_each_file "dominio de venue ativo.*SEC/allowlists/DOMAINS\\.yaml.*dominio fora da allowlist" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md
search_re_each_file "sem permissao de saque|permissao sem saque" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md
search_re_each_file "IP allowlist" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md
search_re_each_file "sem fallback HITL validado.*TRADING_BLOCKED|TRADING_BLOCKED.*sem fallback HITL validado" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md PM/DECISION-PROTOCOL.md
search_re_each_file "remocao de .*TRADING_BLOCKED.*decisao formal|decisao formal.*TRADING_BLOCKED" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md PM/DECISION-PROTOCOL.md
search_re_each_file "TRADING_BLOCKED" ARC/ARC-DEGRADED-MODE.md INCIDENTS/DEGRADED-MODE-PROCEDURE.md
search_re "position_snapshot" ARC/ARC-DEGRADED-MODE.md INCIDENTS/DEGRADED-MODE-PROCEDURE.md
search_re "open_orders_snapshot" INCIDENTS/DEGRADED-MODE-PROCEDURE.md
search_re_each_file "reconcili" ARC/ARC-DEGRADED-MODE.md INCIDENTS/DEGRADED-MODE-PROCEDURE.md
search_re_each_file "UNMANAGED_EXPOSURE" ARC/ARC-DEGRADED-MODE.md INCIDENTS/DEGRADED-MODE-PROCEDURE.md
search_re "posicoes e ordens reconciliadas" INCIDENTS/DEGRADED-MODE-PROCEDURE.md
search_re "Definicao de .*safe_notional" VERTICALS/TRADING/TRADING-RISK-RULES.md
search_re "pre_live_checklist" VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md PRD/PRD-MASTER.md
search_re "make eval-trading" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md DEV/DEV-CI-RULES.md
search_re "trading_phase1_binance" SEC/allowlists/DOMAINS.yaml
search_re "api\\.binance\\.com" SEC/allowlists/DOMAINS.yaml
search_re "deny:" SEC/allowlists/DOMAINS.yaml
search_re 'action: "trading_place_order"' SEC/allowlists/ACTIONS.yaml
search_re 'action: "trading_cancel_order"' SEC/allowlists/ACTIONS.yaml
search_re 'action: "trading_replace_order"' SEC/allowlists/ACTIONS.yaml
search_re 'action: "trading_reconcile_orders"' SEC/allowlists/ACTIONS.yaml
search_re 'policy: "execution_gateway_only"' SEC/allowlists/ACTIONS.yaml
search_re 'action: "trading_withdraw_funds"' SEC/allowlists/ACTIONS.yaml
search_re 'policy: "blocked"' SEC/allowlists/ACTIONS.yaml
search_re "Run trading eval harness" .github/workflows/ci-trading.yml
search_re "make eval-trading" .github/workflows/ci-trading.yml

echo "eval-trading: PASS"
