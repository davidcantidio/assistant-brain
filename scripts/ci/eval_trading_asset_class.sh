#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

ASSET_CLASS="${ASSET_CLASS:-}"

case "$ASSET_CLASS" in
  equities_br|fii_br|fixed_income_br)
    ;;
  *)
    echo "ASSET_CLASS invalido: '${ASSET_CLASS}'. Use equities_br, fii_br ou fixed_income_br."
    exit 1
    ;;
esac

bash scripts/ci/check_phase_f8_multiasset_contracts.sh >/dev/null

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
  "ARC/schemas/asset_class_validator.schema.json"
  "VERTICALS/TRADING/validator_profiles/${ASSET_CLASS}.json"
  "VERTICALS/TRADING/TRADING-PRD.md"
  "VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md"
  "VERTICALS/TRADING/TRADING-RISK-RULES.md"
)

for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || { echo "Arquivo obrigatorio ausente: $file"; exit 1; }
done

python3 -m json.tool "ARC/schemas/asset_class_validator.schema.json" >/dev/null
python3 -m json.tool "VERTICALS/TRADING/validator_profiles/${ASSET_CLASS}.json" >/dev/null

python3 - "$ASSET_CLASS" <<'PY'
import json
import sys
from pathlib import Path


ROOT = Path(".")
ASSET_CLASS = sys.argv[1]
FIXTURES_DIR = ROOT / "scripts/ci/fixtures/trading/multiasset" / ASSET_CLASS


def fail(message: str) -> None:
    print(message)
    sys.exit(1)


def load_json(path: Path) -> object:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def expect_dict(value: object, label: str) -> dict:
    if not isinstance(value, dict):
        fail(f"{label} deve ser objeto JSON.")
    return value


def expect_non_empty_string(value: object, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        fail(f"{label} deve ser string nao vazia.")
    return value


def validate_schema_contract() -> None:
    schema = expect_dict(load_json(ROOT / "ARC/schemas/asset_class_validator.schema.json"), "asset_class_validator schema")
    required = schema.get("required")
    properties = schema.get("properties")
    if not isinstance(required, list):
        fail("asset_class_validator.schema.json com required invalido.")
    if not isinstance(properties, dict):
        fail("asset_class_validator.schema.json com properties invalido.")
    expected = [
        "schema_version",
        "contract_version",
        "asset_class",
        "asset_profile_ref",
        "calendar_rules",
        "lot_tick_notional_rules",
        "cost_rules",
        "market_state_blockers",
        "normalization_rules",
        "risk_assertions",
    ]
    for field in expected:
        if field not in required or field not in properties:
            fail(f"asset_class_validator.schema.json sem campo obrigatorio: {field}")


def analyze_validator_profile(profile: object, asset_class: str, label: str) -> list[str]:
    payload = expect_dict(profile, label)
    reasons: list[str] = []

    if payload.get("schema_version") != "1.0":
        reasons.append("schema_version invalido")
    if payload.get("contract_version") != "v1":
        reasons.append("contract_version invalido")
    if payload.get("asset_class") != asset_class:
        reasons.append("asset_class divergente")
    expected_ref = f"VERTICALS/TRADING/asset_profiles/{asset_class}.json"
    if payload.get("asset_profile_ref") != expected_ref:
        reasons.append("asset_profile_ref divergente")

    calendar_rules = payload.get("calendar_rules")
    if not isinstance(calendar_rules, dict):
        reasons.append("calendar_rules ausente")
    else:
        if not isinstance(calendar_rules.get("calendar_id"), str) or not calendar_rules["calendar_id"].strip():
            reasons.append("calendar_id ausente")
        if not isinstance(calendar_rules.get("timezone"), str) or not calendar_rules["timezone"].strip():
            reasons.append("timezone ausente")
        statuses = calendar_rules.get("tradable_statuses")
        if not isinstance(statuses, list) or not statuses:
            reasons.append("tradable_statuses ausente")

    lot_tick = payload.get("lot_tick_notional_rules")
    if not isinstance(lot_tick, dict):
        reasons.append("lot_tick_notional_rules ausente")
    else:
        for field in ("min_notional", "lot_size", "tick_size"):
            value = lot_tick.get(field)
            if not isinstance(value, (int, float)) or value <= 0:
                reasons.append(f"{field} ausente")
        if not isinstance(lot_tick.get("quantity_rounding"), str) or not lot_tick["quantity_rounding"].strip():
            reasons.append("quantity_rounding ausente")

    cost_rules = payload.get("cost_rules")
    if not isinstance(cost_rules, dict):
        reasons.append("cost_rules ausente")
    else:
        for field in ("base_fee_bps", "emoluments_bps", "taxes_bps", "slippage_bps"):
            value = cost_rules.get(field)
            if not isinstance(value, (int, float)) or value < 0:
                reasons.append(f"{field} ausente")

    blockers = payload.get("market_state_blockers")
    if not isinstance(blockers, list) or not blockers:
        reasons.append("market_state_blockers ausente")
        blockers = []
    else:
        required_blockers = {"closed", "halt"}
        missing = sorted(required_blockers - set(blockers))
        if missing:
            reasons.append("market_state_blockers incompleto")
        if asset_class != "fixed_income_br" and "auction" not in blockers:
            reasons.append("auction ausente")

    normalization = payload.get("normalization_rules")
    if not isinstance(normalization, dict):
        reasons.append("normalization_rules ausente")
    else:
        for field in ("quantity_mode", "price_mode"):
            if not isinstance(normalization.get(field), str) or not normalization[field].strip():
                reasons.append(f"{field} ausente")

    risk_assertions = payload.get("risk_assertions")
    if not isinstance(risk_assertions, dict):
        reasons.append("risk_assertions ausente")
    else:
        if not isinstance(risk_assertions.get("unit_guard"), str) or not risk_assertions["unit_guard"].strip():
            reasons.append("unit_guard ausente")
        if risk_assertions.get("effective_risk_quote_required") is not True:
            reasons.append("effective_risk_quote_required ausente")
        expected_max_loss = asset_class == "fixed_income_br"
        if risk_assertions.get("requires_max_loss_per_unit_brl") is not expected_max_loss:
            reasons.append("requires_max_loss_per_unit_brl divergente")

    return reasons


def analyze_fixture(path: Path, asset_class: str) -> tuple[str, str]:
    fixture = expect_dict(load_json(path), str(path))
    case_id = expect_non_empty_string(fixture.get("case_id"), f"{path}.case_id")
    expected_status = expect_non_empty_string(fixture.get("expected_status"), f"{path}.expected_status")
    if expected_status not in {"PASS", "FAIL"}:
        fail(f"{path} com expected_status invalido: {expected_status}")
    if fixture.get("asset_class") != asset_class:
        fail(f"{path} com asset_class divergente.")
    market_state = expect_dict(fixture.get("market_state"), f"{path}.market_state")
    status = expect_non_empty_string(market_state.get("status"), f"{path}.market_state.status")
    profile = fixture.get("validator_profile")
    reasons = analyze_validator_profile(profile, asset_class, f"{path}.validator_profile")
    blockers = []
    if isinstance(profile, dict) and isinstance(profile.get("market_state_blockers"), list):
        blockers = profile["market_state_blockers"]
    if status in blockers:
        reasons.append(f"market_state bloqueante: {status}")
    computed_status = "FAIL" if reasons else "PASS"
    if computed_status != expected_status:
        fail(
            f"{path} com resultado inesperado. esperado={expected_status} calculado={computed_status} motivos={'; '.join(reasons) or 'none'}"
        )
    return case_id, computed_status


validate_schema_contract()

canonical_profile = load_json(ROOT / "VERTICALS/TRADING/validator_profiles" / f"{ASSET_CLASS}.json")
canonical_reasons = analyze_validator_profile(canonical_profile, ASSET_CLASS, f"validator_profiles/{ASSET_CLASS}.json")
if canonical_reasons:
    fail(
        f"validator_profiles/{ASSET_CLASS}.json invalido: {'; '.join(canonical_reasons)}"
    )

if not FIXTURES_DIR.exists():
    fail(f"diretorio de fixtures ausente: {FIXTURES_DIR}")

fixture_paths = sorted(FIXTURES_DIR.glob("*.json"))
if not fixture_paths:
    fail(f"sem fixtures em {FIXTURES_DIR}")

seen_pass = False
seen_fail = False
for path in fixture_paths:
    _, result = analyze_fixture(path, ASSET_CLASS)
    if result == "PASS":
        seen_pass = True
    if result == "FAIL":
        seen_fail = True

if not seen_pass or not seen_fail:
    fail(f"{FIXTURES_DIR} deve conter ao menos um fixture PASS e um FAIL.")
PY

search_re_each_file 'VERTICALS/TRADING/validator_profiles/' \
  VERTICALS/TRADING/TRADING-PRD.md \
  VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md \
  VERTICALS/TRADING/TRADING-RISK-RULES.md
search_re "eval-trading-${ASSET_CLASS}" VERTICALS/TRADING/TRADING-PRD.md
search_re "eval-trading-${ASSET_CLASS}" VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md
search_re 'eval-trading-multiasset' DEV/DEV-CI-RULES.md
search_re 'make eval-trading-multiasset' .github/workflows/ci-trading.yml

echo "eval-trading-${ASSET_CLASS}: PASS"
