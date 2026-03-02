from __future__ import annotations

import argparse
from pathlib import Path

from ci.checks.common import CheckFailure, ensure_files, ensure_json_paths, load_json, search, search_each_file, utc_now, write_output


PRE_LIVE_CHECKLIST_PATH = "artifacts/trading/pre_live_checklist/CHECKLIST-F7-02-S1-20260301-01.json"
REQUIRED_FILES = (
    "VERTICALS/TRADING/TRADING-PRD.md",
    "VERTICALS/TRADING/TRADING-RISK-RULES.md",
    "VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md",
    "ARC/ARC-DEGRADED-MODE.md",
    "INCIDENTS/DEGRADED-MODE-PROCEDURE.md",
    "SEC/allowlists/ACTIONS.yaml",
    "SEC/allowlists/DOMAINS.yaml",
    ".github/workflows/ci-trading.yml",
    "ARC/schemas/execution_gateway.schema.json",
    "ARC/schemas/pre_trade_validator.schema.json",
    PRE_LIVE_CHECKLIST_PATH,
)
SCHEMA_FILES = (
    "ARC/schemas/execution_gateway.schema.json",
    "ARC/schemas/pre_trade_validator.schema.json",
)


def schema_assert_versioned_contract(root: Path, schema_path: str) -> None:
    schema = load_json(root, schema_path)
    required = schema.get("required", [])
    if not isinstance(required, list):
        raise ValueError(f"Schema version contract check failed: {schema_path}\nrequired MUST be a JSON array.")
    for field in ("schema_version", "contract_version"):
        if field not in required:
            raise ValueError(f"Schema version contract check failed: {schema_path}\nrequired MUST include '{field}'.")
    properties = schema.get("properties", {})
    if not isinstance(properties, dict):
        raise ValueError(f"Schema version contract check failed: {schema_path}\nproperties MUST be a JSON object.")
    schema_version = properties.get("schema_version")
    if not isinstance(schema_version, dict) or schema_version.get("type") != "string" or schema_version.get("const") != "1.0":
        raise ValueError(f"Schema version contract check failed: {schema_path}\nproperties.schema_version must be string const 1.0.")
    contract_version = properties.get("contract_version")
    if not isinstance(contract_version, dict) or contract_version.get("type") != "string" or contract_version.get("const") != "v1":
        raise ValueError(f"Schema version contract check failed: {schema_path}\nproperties.contract_version must be string const v1.")


def schema_assert_minimum_contract(root: Path, schema_path: str, required_fields: tuple[str, ...], properties_fields: tuple[str, ...]) -> None:
    schema = load_json(root, schema_path)
    required = schema.get("required", [])
    properties = schema.get("properties", {})
    if not isinstance(required, list):
        raise ValueError(f"Schema contract check failed: {schema_path}\nrequired MUST be a JSON array.")
    if not isinstance(properties, dict):
        raise ValueError(f"Schema contract check failed: {schema_path}\nproperties MUST be a JSON object.")
    missing_required = [item for item in required_fields if item not in required]
    missing_properties = [item for item in properties_fields if item not in properties]
    if missing_required or missing_properties:
        parts = [f"Schema contract check failed: {schema_path}"]
        if missing_required:
            parts.append("missing required[] entries: " + ", ".join(missing_required))
        if missing_properties:
            parts.append("missing properties entries: " + ", ".join(missing_properties))
        raise ValueError("\n".join(parts))


def pre_live_checklist_assert_contract(root: Path, checklist_path: str) -> None:
    checklist = load_json(root, checklist_path)
    required_fields = ("checklist_id", "decision_id", "risk_tier", "asset_class", "capital_ramp_level", "operator_id", "approved_at", "items")
    for field in required_fields:
        if field not in checklist:
            raise ValueError(f"pre_live_checklist contract check failed: {checklist_path}\nmissing required field: {field}")
    for field in required_fields[:-1]:
        value = checklist.get(field)
        if not isinstance(value, str) or not value.strip():
            raise ValueError(f"pre_live_checklist contract check failed: {checklist_path}\nfield '{field}' MUST be a non-empty string.")

    items = checklist.get("items")
    if not isinstance(items, list) or not items:
        raise ValueError(f"pre_live_checklist contract check failed: {checklist_path}\nfield 'items' MUST be a non-empty array.")

    required_item_ids = {
        "eval_trading_green",
        "execution_gateway_only",
        "pre_trade_validator_active",
        "credentials_live_no_withdraw",
        "hitl_channel_ready",
        "degraded_mode_runbook_ok",
        "backup_operator_enabled",
        "explicit_order_approval_active",
    }
    seen_item_ids: set[str] = set()
    for index, item in enumerate(items):
        if not isinstance(item, dict):
            raise ValueError(f"pre_live_checklist contract check failed: {checklist_path}\nitems[{index}] MUST be an object.")
        for key in ("item_id", "status", "evidence_ref"):
            value = item.get(key)
            if not isinstance(value, str) or not value.strip():
                raise ValueError(f"pre_live_checklist contract check failed: {checklist_path}\nitems[{index}].{key} MUST be a non-empty string.")
        status = item["status"]
        if status not in {"pass", "fail"}:
            raise ValueError(f"pre_live_checklist contract check failed: {checklist_path}\nitems[{index}].status MUST be 'pass' or 'fail'.")
        item_id = item["item_id"]
        if item_id in seen_item_ids:
            raise ValueError(f"pre_live_checklist contract check failed: {checklist_path}\nduplicate item_id detected: {item_id}")
        seen_item_ids.add(item_id)

    missing_item_ids = sorted(required_item_ids - seen_item_ids)
    if missing_item_ids:
        raise ValueError(f"pre_live_checklist contract check failed: {checklist_path}\nmissing required item_ids: {', '.join(missing_item_ids)}")


def pre_live_checklist_assert_s1_guardrails(root: Path, checklist_path: str) -> None:
    checklist = load_json(root, checklist_path)
    if checklist.get("capital_ramp_level") != "L0":
        raise ValueError(f"S1 guardrail check failed: {checklist_path}\ncapital_ramp_level MUST be 'L0' for S1 micro-live entry.")
    items = checklist.get("items")
    if not isinstance(items, list):
        raise ValueError(f"S1 guardrail check failed: {checklist_path}\nitems MUST be a JSON array.")
    status_by_item = {item.get("item_id"): item.get("status") for item in items if isinstance(item, dict)}
    for item_id in ("execution_gateway_only", "pre_trade_validator_active"):
        if status_by_item.get(item_id) != "pass":
            raise ValueError(f"S1 guardrail check failed: {checklist_path}\nitem '{item_id}' MUST be 'pass' for S1 guardrail compliance.")


def run(root: Path) -> dict[str, object]:
    ensure_files(root, REQUIRED_FILES)
    ensure_json_paths(root, SCHEMA_FILES)
    for schema_path in SCHEMA_FILES:
        schema_assert_versioned_contract(root, schema_path)
    schema_assert_minimum_contract(root, "ARC/schemas/execution_gateway.schema.json", ("schema_version", "contract_version", "order_intent_id", "client_order_id", "idempotency_key", "asset_class", "symbol", "side", "order_type", "quantity", "stop_price", "risk_tier", "decision_id"), ("schema_version", "contract_version", "order_intent_id", "client_order_id", "idempotency_key", "asset_class", "symbol", "side", "order_type", "quantity", "price", "stop_price", "risk_tier", "decision_id", "execution_id", "venue_order_id", "status", "filled_quantity", "avg_fill_price", "reject_reason", "replay_disposition", "reconciliation_status", "reconciliation_trace_id", "position_snapshot_ref"))
    schema_assert_minimum_contract(root, "ARC/schemas/pre_trade_validator.schema.json", ("schema_version", "contract_version", "asset_profile_version", "capital_ramp_level", "symbol", "symbol_constraints", "order_intent", "market_state", "validator_status", "block_reasons", "normalized_order", "effective_risk_quote"), ("schema_version", "contract_version", "asset_profile_version", "capital_ramp_level", "symbol", "symbol_constraints", "order_intent", "market_state", "validator_status", "block_reasons", "normalized_order", "effective_risk_quote"))
    pre_live_checklist_assert_contract(root, PRE_LIVE_CHECKLIST_PATH)
    pre_live_checklist_assert_s1_guardrails(root, PRE_LIVE_CHECKLIST_PATH)

    search(root, r"S0 - Paper/Sandbox", ["VERTICALS/TRADING/TRADING-PRD.md", "VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md"])
    search_each_file(root, r"tentativa de ordem live em .*S0.*TRADING_BLOCKED|TRADING_BLOCKED.*tentativa de ordem live em .*S0", ["VERTICALS/TRADING/TRADING-PRD.md", "VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md"])
    search_each_file(root, r"ordem de entrada em .*S0.*aprovacao humana explicita e auditavel|aprovacao humana explicita e auditavel.*ordem de entrada em .*S0", ["VERTICALS/TRADING/TRADING-PRD.md", "VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md", "PM/DECISION-PROTOCOL.md"])
    search(root, r"execution_gateway", ["VERTICALS/TRADING/TRADING-PRD.md", "VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md"])
    search(root, r"pre_trade_validator", ["VERTICALS/TRADING/TRADING-PRD.md", "VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md"])
    search(root, r"execution_gateway` \(v1 minimo\)", ["VERTICALS/TRADING/TRADING-PRD.md"])
    search(root, r"pre_trade_validator` \(v1 minimo\)", ["VERTICALS/TRADING/TRADING-PRD.md"])
    search(root, r"symbol_constraints", ["VERTICALS/TRADING/TRADING-PRD.md"])
    search_each_file(root, r"client_order_id", ["VERTICALS/TRADING/TRADING-PRD.md", "VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md"])
    search_each_file(root, r"replay.*client_order_id.*idempotency_key.*no-op.*auditavel", ["VERTICALS/TRADING/TRADING-PRD.md", "VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md"])
    search_each_file(root, r"falha parcial.*estado final consistente.*auditavel", ["VERTICALS/TRADING/TRADING-PRD.md", "VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md"])
    search_each_file(root, r"fail_closed.*engine primaria|engine primaria.*fail_closed", ["VERTICALS/TRADING/TRADING-PRD.md", "VERTICALS/TRADING/TRADING-RISK-RULES.md", "VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md"])
    search_each_file(root, r"single_engine_mode.*engine secundaria|engine secundaria.*single_engine_mode", ["VERTICALS/TRADING/TRADING-PRD.md", "VERTICALS/TRADING/TRADING-RISK-RULES.md", "VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md"])
    search_each_file(root, r"single_engine_mode.*primaria.*saudavel", ["VERTICALS/TRADING/TRADING-PRD.md", "VERTICALS/TRADING/TRADING-RISK-RULES.md", "VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md"])
    search_each_file(root, r"TradingAgents.*engine primaria de sinal", ["VERTICALS/TRADING/TRADING-PRD.md", "VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md"])
    search_each_file(root, r"AI-Trader -> signal_intent -> normalizacao/deduplicacao -> pre_trade_validator -> HITL -> execution_gateway", ["VERTICALS/TRADING/TRADING-PRD.md", "VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md"])
    search_each_file(root, r"ordem direta originada do AI-Trader MUST ser rejeitado e auditado", ["VERTICALS/TRADING/TRADING-PRD.md", "VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md"])
    search_each_file(root, r"caminho de execucao unico confirmado: somente `execution_gateway` pode enviar ordem live", ["VERTICALS/TRADING/TRADING-PRD.md", "VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md"])
    search_each_file(root, r"dominio de venue ativo.*SEC/allowlists/DOMAINS\.yaml.*dominio fora da allowlist", ["VERTICALS/TRADING/TRADING-PRD.md", "VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md"])
    search_each_file(root, r"sem permissao de saque|permissao sem saque", ["VERTICALS/TRADING/TRADING-PRD.md", "VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md"])
    search_each_file(root, r"IP allowlist", ["VERTICALS/TRADING/TRADING-PRD.md", "VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md"])
    search_each_file(root, r"sem fallback HITL validado.*TRADING_BLOCKED|TRADING_BLOCKED.*sem fallback HITL validado", ["VERTICALS/TRADING/TRADING-PRD.md", "VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md", "PM/DECISION-PROTOCOL.md"])
    search_each_file(root, r"remocao de .*TRADING_BLOCKED.*decisao formal|decisao formal.*TRADING_BLOCKED", ["VERTICALS/TRADING/TRADING-PRD.md", "VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md", "PM/DECISION-PROTOCOL.md"])
    search_each_file(root, r"TRADING_BLOCKED", ["ARC/ARC-DEGRADED-MODE.md", "INCIDENTS/DEGRADED-MODE-PROCEDURE.md"])
    search(root, r"position_snapshot", ["ARC/ARC-DEGRADED-MODE.md", "INCIDENTS/DEGRADED-MODE-PROCEDURE.md"])
    search(root, r"open_orders_snapshot", ["INCIDENTS/DEGRADED-MODE-PROCEDURE.md"])
    search_each_file(root, r"reconcili", ["ARC/ARC-DEGRADED-MODE.md", "INCIDENTS/DEGRADED-MODE-PROCEDURE.md"])
    search_each_file(root, r"UNMANAGED_EXPOSURE", ["ARC/ARC-DEGRADED-MODE.md", "INCIDENTS/DEGRADED-MODE-PROCEDURE.md"])
    search(root, r"posicoes e ordens reconciliadas", ["INCIDENTS/DEGRADED-MODE-PROCEDURE.md"])
    search(root, r"Definicao de .*safe_notional", ["VERTICALS/TRADING/TRADING-RISK-RULES.md"])
    search(root, r"pre_live_checklist", ["VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md", "PRD/PRD-MASTER.md", "VERTICALS/TRADING/TRADING-PRD.md"])
    search(root, r"make eval-trading", ["VERTICALS/TRADING/TRADING-PRD.md", "VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md", "DEV/DEV-CI-RULES.md"])
    search(root, r"trading_phase1_binance", ["SEC/allowlists/DOMAINS.yaml"])
    search(root, r"api\.binance\.com", ["SEC/allowlists/DOMAINS.yaml"])
    search(root, r"deny:", ["SEC/allowlists/DOMAINS.yaml"])
    search(root, r'action: "trading_place_order"', ["SEC/allowlists/ACTIONS.yaml"])
    search(root, r'action: "trading_cancel_order"', ["SEC/allowlists/ACTIONS.yaml"])
    search(root, r'action: "trading_replace_order"', ["SEC/allowlists/ACTIONS.yaml"])
    search(root, r'action: "trading_reconcile_orders"', ["SEC/allowlists/ACTIONS.yaml"])
    search(root, r'policy: "execution_gateway_only"', ["SEC/allowlists/ACTIONS.yaml"])
    search(root, r'action: "trading_withdraw_funds"', ["SEC/allowlists/ACTIONS.yaml"])
    search(root, r'policy: "blocked"', ["SEC/allowlists/ACTIONS.yaml"])
    search(root, r"Run trading eval harness", [".github/workflows/ci-trading.yml"])
    search(root, r"make eval-trading", [".github/workflows/ci-trading.yml"])

    return {"schema_version": "1.0", "check_id": "eval-trading", "status": "PASS", "validated_at": utc_now(), "validated_files": sorted(REQUIRED_FILES)}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate trading contracts")
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
            write_output(output_path, {"schema_version": "1.0", "check_id": "eval-trading", "status": "FAIL", "validated_at": utc_now(), "error": str(exc)})
        print(str(exc))
        return 1

    write_output(output_path, payload)
    print("eval-trading: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
