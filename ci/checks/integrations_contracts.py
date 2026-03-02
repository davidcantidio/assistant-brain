from __future__ import annotations

import argparse
from pathlib import Path

from ci.checks.common import CheckFailure, ensure_files, ensure_json_paths, load_json, search, search_absent, search_each_file, utc_now, write_output


REQUIRED_FILES = (
    "INTEGRATIONS/README.md",
    "INTEGRATIONS/AI-TRADER.md",
    "INTEGRATIONS/CLAWWORK.md",
    "INTEGRATIONS/OPENCLAW-UPSTREAM.md",
    "ARC/schemas/signal_intent.schema.json",
    "ARC/schemas/order_intent.schema.json",
    "ARC/schemas/execution_report.schema.json",
    "ARC/schemas/economic_run.schema.json",
    "ARC/schemas/openclaw_runtime_config.schema.json",
)

SCHEMA_FILES = (
    "ARC/schemas/signal_intent.schema.json",
    "ARC/schemas/order_intent.schema.json",
    "ARC/schemas/execution_report.schema.json",
    "ARC/schemas/economic_run.schema.json",
    "ARC/schemas/openclaw_runtime_config.schema.json",
)


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


def schema_assert_version_metadata(root: Path, schema_path: str) -> None:
    schema = load_json(root, schema_path)
    schema_uri = schema.get("$schema")
    schema_id = schema.get("$id")
    required = schema.get("required", [])
    properties = schema.get("properties", {})
    schema_version = properties.get("schema_version") if isinstance(properties, dict) else None
    if not isinstance(schema_uri, str) or not schema_uri.strip():
        raise ValueError(f"Schema version metadata check failed: {schema_path}\ntop-level $schema MUST exist as a non-empty string.")
    if not isinstance(schema_id, str) or not schema_id.strip():
        raise ValueError(f"Schema version metadata check failed: {schema_path}\ntop-level $id MUST exist as a non-empty string.")
    if not isinstance(required, list) or "schema_version" not in required:
        raise ValueError(f"Schema version metadata check failed: {schema_path}\nrequired MUST include schema_version.")
    if not isinstance(properties, dict):
        raise ValueError(f"Schema version metadata check failed: {schema_path}\nproperties MUST be a JSON object.")
    if not isinstance(schema_version, dict):
        raise ValueError(f"Schema version metadata check failed: {schema_path}\nproperties.schema_version MUST exist as a JSON object.")
    if schema_version.get("type") != "string":
        raise ValueError(f"Schema version metadata check failed: {schema_path}\nproperties.schema_version.type MUST be 'string'.")
    if schema_version.get("const") != "1.0":
        raise ValueError(f"Schema version metadata check failed: {schema_path}\nproperties.schema_version.const MUST be '1.0'.")


def schema_assert_runtime_dual_contract(root: Path, schema_path: str) -> None:
    schema = load_json(root, schema_path)
    properties = schema.get("properties", {})
    if not isinstance(properties, dict):
        raise ValueError(f"Runtime dual contract check failed: {schema_path}\ntop-level properties MUST be a JSON object.")
    gateway = properties.get("gateway")
    if not isinstance(gateway, dict):
        raise ValueError(f"Runtime dual contract check failed: {schema_path}\nproperties.gateway MUST exist as a JSON object.")
    gateway_required = gateway.get("required", [])
    if not isinstance(gateway_required, list):
        raise ValueError(f"Runtime dual contract check failed: {schema_path}\ngateway.required MUST be a JSON array.")
    for field in ("bind", "control_plane"):
        if field not in gateway_required:
            raise ValueError(f"Runtime dual contract check failed: {schema_path}\ngateway.required MUST include '{field}'.")
    if "http" in gateway_required:
        raise ValueError(f"Runtime dual contract check failed: {schema_path}\ngateway.required MUST NOT include 'http' (chatCompletions remains optional under policy).")
    gateway_props = gateway.get("properties", {})
    if not isinstance(gateway_props, dict):
        raise ValueError(f"Runtime dual contract check failed: {schema_path}\ngateway.properties MUST be a JSON object.")
    control_plane = gateway_props.get("control_plane")
    if not isinstance(control_plane, dict):
        raise ValueError(f"Runtime dual contract check failed: {schema_path}\ngateway.properties.control_plane MUST exist as a JSON object.")
    control_plane_required = control_plane.get("required", [])
    if not isinstance(control_plane_required, list) or "ws" not in control_plane_required:
        raise ValueError(f"Runtime dual contract check failed: {schema_path}\ngateway.properties.control_plane.required MUST include 'ws'.")
    http = gateway_props.get("http")
    if not isinstance(http, dict):
        raise ValueError(f"Runtime dual contract check failed: {schema_path}\ngateway.properties.http MUST exist as a JSON object.")
    http_props = http.get("properties", {})
    if not isinstance(http_props, dict):
        raise ValueError(f"Runtime dual contract check failed: {schema_path}\ngateway.properties.http.properties MUST be a JSON object.")
    endpoints = http_props.get("endpoints")
    if not isinstance(endpoints, dict):
        raise ValueError(f"Runtime dual contract check failed: {schema_path}\ngateway.properties.http.properties.endpoints MUST exist as a JSON object.")
    endpoints_props = endpoints.get("properties", {})
    if not isinstance(endpoints_props, dict):
        raise ValueError(f"Runtime dual contract check failed: {schema_path}\ngateway.properties.http.properties.endpoints.properties MUST be a JSON object.")
    chat_completions = endpoints_props.get("chatCompletions")
    if not isinstance(chat_completions, dict):
        raise ValueError(f"Runtime dual contract check failed: {schema_path}\ngateway.http.endpoints.chatCompletions path MUST exist in schema.")
    chat_required = chat_completions.get("required", [])
    if not isinstance(chat_required, list) or "enabled" not in chat_required:
        raise ValueError(f"Runtime dual contract check failed: {schema_path}\ngateway.http.endpoints.chatCompletions.required MUST include 'enabled'.")
    chat_props = chat_completions.get("properties", {})
    if not isinstance(chat_props, dict) or "enabled" not in chat_props:
        raise ValueError(f"Runtime dual contract check failed: {schema_path}\ngateway.http.endpoints.chatCompletions.properties.enabled MUST exist in schema.")


def schema_assert_provider_path_shape(root: Path, schema_path: str) -> None:
    schema = load_json(root, schema_path)
    properties = schema.get("properties", {})
    if not isinstance(properties, dict):
        raise ValueError(f"provider_path shape check failed: {schema_path}\ntop-level properties MUST be a JSON object.")
    provider_path = properties.get("provider_path")
    if not isinstance(provider_path, dict):
        raise ValueError(f"provider_path shape check failed: {schema_path}\nproperties.provider_path MUST exist as a JSON object.")
    if provider_path.get("type") != "array":
        raise ValueError(f"provider_path shape check failed: {schema_path}\nprovider_path.type MUST be 'array'.")
    min_items = provider_path.get("minItems")
    if not isinstance(min_items, int) or min_items < 1:
        raise ValueError(f"provider_path shape check failed: {schema_path}\nprovider_path.minItems MUST be an integer >= 1.")
    items = provider_path.get("items")
    if not isinstance(items, dict):
        raise ValueError(f"provider_path shape check failed: {schema_path}\nprovider_path.items MUST be a JSON object.")
    if items.get("type") != "string":
        raise ValueError(f"provider_path shape check failed: {schema_path}\nprovider_path.items.type MUST be 'string'.")
    min_length = items.get("minLength")
    if not isinstance(min_length, int) or min_length < 1:
        raise ValueError(f"provider_path shape check failed: {schema_path}\nprovider_path.items.minLength MUST be an integer >= 1.")


def run(root: Path) -> dict[str, object]:
    ensure_files(root, REQUIRED_FILES)
    ensure_json_paths(root, SCHEMA_FILES)

    schema_assert_minimum_contract(root, "ARC/schemas/signal_intent.schema.json", ("intent_id", "source_engine", "symbol", "side", "confidence", "thesis", "time_horizon", "as_of", "trace_id"), ("intent_id", "source_engine", "symbol", "side", "confidence", "thesis", "time_horizon", "as_of", "trace_id"))
    schema_assert_minimum_contract(root, "ARC/schemas/order_intent.schema.json", ("order_intent_id", "signal_intent_id", "symbol", "side", "order_type", "quantity", "stage", "decision_id", "approved_by", "approved_at"), ("order_intent_id", "signal_intent_id", "symbol", "side", "order_type", "quantity", "stage", "decision_id", "approved_by", "approved_at"))
    schema_assert_minimum_contract(root, "ARC/schemas/execution_report.schema.json", ("execution_report_id", "order_intent_id", "venue", "status", "filled_qty", "avg_price", "timestamp", "gateway_trace_id"), ("execution_report_id", "order_intent_id", "venue", "status", "filled_qty", "avg_price", "timestamp", "gateway_trace_id"))
    schema_assert_minimum_contract(root, "ARC/schemas/economic_run.schema.json", ("run_id", "benchmark", "scenario", "success", "quality_score", "total_cost_usd", "provider_path", "started_at", "ended_at"), ("run_id", "benchmark", "scenario", "success", "quality_score", "total_cost_usd", "provider_path", "started_at", "ended_at"))

    for schema_path in ("ARC/schemas/signal_intent.schema.json", "ARC/schemas/order_intent.schema.json", "ARC/schemas/execution_report.schema.json", "ARC/schemas/economic_run.schema.json"):
        schema_assert_version_metadata(root, schema_path)

    schema_assert_runtime_dual_contract(root, "ARC/schemas/openclaw_runtime_config.schema.json")
    schema_assert_provider_path_shape(root, "ARC/schemas/economic_run.schema.json")

    rule = "OpenRouter e o adaptador cloud padrao (cloud-first), habilitado por default no runtime cloud e hibrido."
    search_each_file(root, rule, ["README.md", "PRD/ROADMAP.md", "PRD/PRD-MASTER.md", "ARC/ARC-MODEL-ROUTING.md", "SEC/SEC-POLICY.md"], fixed=True)
    search(root, r'cloud_adapter_default: "enabled"', ["SEC/allowlists/PROVIDERS.yaml"])
    search(root, r'cloud_adapter_enablement: "default_on"', ["SEC/allowlists/PROVIDERS.yaml"])
    search(root, r'cloud_adapter_primary: "openrouter"', ["SEC/allowlists/PROVIDERS.yaml"])
    search_absent(root, r"OpenRouter e o adaptador padrao recomendado", ["README.md", "PRD/ROADMAP.md", "PRD/PRD-MASTER.md", "ARC/ARC-MODEL-ROUTING.md"])
    search_absent(root, r"OpenRouter MAY operar como adaptador cloud recomendado", ["SEC/SEC-POLICY.md"])
    search_absent(root, r"adaptador cloud recomendado quando necessario", ["README.md"])
    search_absent(root, r"OpenRouter e o adaptador recomendado quando operacao multi-provider estiver habilitada", ["PRD/ROADMAP.md"])
    search_absent(root, r"OpenRouter e adaptador cloud opcional, permanece desabilitado por default", ["README.md", "PRD/ROADMAP.md", "PRD/PRD-MASTER.md", "ARC/ARC-MODEL-ROUTING.md", "SEC/SEC-POLICY.md"])
    search_absent(root, r'cloud_adapter_default: "disabled"', ["SEC/allowlists/PROVIDERS.yaml"])
    search_absent(root, r'cloud_adapter_enablement: "decision_required"', ["SEC/allowlists/PROVIDERS.yaml"])
    search_absent(root, r'cloud_adapter_preferred_when_enabled: "openrouter"', ["SEC/allowlists/PROVIDERS.yaml"])
    search(root, r"America/Sao_Paulo", ["PRD/PRD-MASTER.md", "ARC/ARC-HEARTBEAT.md", "workspaces/main/HEARTBEAT.md", "PRD/CHANGELOG.md"])
    search(root, r"override deliberado de timezone.*America/Sao_Paulo", ["PRD/CHANGELOG.md"])
    search(root, r"gateway\.control_plane\.ws", ["PRD/PRD-MASTER.md", "ARC/ARC-CORE.md", "INTEGRATIONS/OPENCLAW-UPSTREAM.md"])
    search(root, r"chatCompletions", ["PRD/PRD-MASTER.md", "ARC/ARC-CORE.md", "INTEGRATIONS/OPENCLAW-UPSTREAM.md", "ARC/schemas/openclaw_runtime_config.schema.json"])
    search_each_file(root, r"Matriz de Compatibilidade", ["INTEGRATIONS/OPENCLAW-UPSTREAM.md"])
    search_each_file(root, r"control plane WS \(canonico\)", ["INTEGRATIONS/OPENCLAW-UPSTREAM.md"])
    search_each_file(root, r"chatCompletions HTTP \(opcional\)", ["INTEGRATIONS/OPENCLAW-UPSTREAM.md"])
    search_each_file(root, r"Matriz de Modos Permitidos", ["INTEGRATIONS/README.md"])
    search_each_file(root, r"AI-Trader.*signal_only", ["INTEGRATIONS/README.md"])
    search_each_file(root, r"ClawWork.*lab_isolated.*default.*governed.*gateway-only", ["INTEGRATIONS/README.md"])
    search_each_file(root, r"OpenClaw upstream.*gateway\.control_plane\.ws.*chatCompletions.*opcional", ["INTEGRATIONS/README.md"])
    search_each_file(root, "MUST operar somente como gerador de `signal_intent`.", ["INTEGRATIONS/AI-TRADER.md"], fixed=True)
    search_each_file(root, "MUST NOT enviar `order_intent` diretamente para venue/exchange.", ["INTEGRATIONS/AI-TRADER.md"], fixed=True)
    search_each_file(root, "qualquer payload que represente ordem direta originada do AI-Trader MUST ser bloqueado e auditado.", ["INTEGRATIONS/AI-TRADER.md"], fixed=True)
    search_each_file(root, r"AI-Trader -> signal_intent -> normalizacao/deduplicacao -> pre_trade_validator -> HITL -> execution_gateway", ["VERTICALS/TRADING/TRADING-PRD.md", "VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md"])
    search_each_file(root, r"ordem direta originada do AI-Trader MUST ser rejeitado e auditado", ["VERTICALS/TRADING/TRADING-PRD.md", "VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md"])
    search_each_file(root, "modo `lab_isolated` e default.", ["INTEGRATIONS/CLAWWORK.md"], fixed=True)
    search_each_file(root, "modo `governed` MUST rotear toda chamada LLM via OpenClaw Gateway.", ["INTEGRATIONS/CLAWWORK.md"], fixed=True)
    search_each_file(root, "chamada direta a provider externo no modo `governed` MUST ser bloqueada.", ["INTEGRATIONS/CLAWWORK.md"], fixed=True)
    search(root, r"E2B", ["INTEGRATIONS/CLAWWORK.md"])
    search(root, r"provider_path", ["INTEGRATIONS/CLAWWORK.md", "ARC/schemas/economic_run.schema.json"])

    return {"schema_version": "1.0", "check_id": "eval-integrations", "status": "PASS", "validated_at": utc_now(), "validated_files": sorted(REQUIRED_FILES)}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate integrations contracts")
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
            write_output(output_path, {"schema_version": "1.0", "check_id": "eval-integrations", "status": "FAIL", "validated_at": utc_now(), "error": str(exc)})
        print(str(exc))
        return 1

    write_output(output_path, payload)
    print("eval-integrations: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
