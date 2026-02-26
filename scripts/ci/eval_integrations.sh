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

search_fixed_each_file() {
  local pattern="$1"
  shift
  local f
  for f in "$@"; do
    if ! search_fixed "$pattern" "$f"; then
      echo "Texto obrigatorio ausente em $f: $pattern"
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

schema_assert_version_metadata() {
  local schema_path="$1"

  python3 - "$schema_path" <<'PY'
import json
import sys

schema_path = sys.argv[1]

with open(schema_path, "r", encoding="utf-8") as fh:
    schema = json.load(fh)

def fail(msg):
    print(f"Schema version metadata check failed: {schema_path}")
    print(msg)
    sys.exit(1)

schema_uri = schema.get("$schema")
if not isinstance(schema_uri, str) or not schema_uri.strip():
    fail("top-level $schema MUST exist as a non-empty string.")

schema_id = schema.get("$id")
if not isinstance(schema_id, str) or not schema_id.strip():
    fail("top-level $id MUST exist as a non-empty string.")

required = schema.get("required", [])
if not isinstance(required, list) or "schema_version" not in required:
    fail("required MUST include schema_version.")

properties = schema.get("properties", {})
if not isinstance(properties, dict):
    fail("properties MUST be a JSON object.")

schema_version = properties.get("schema_version")
if not isinstance(schema_version, dict):
    fail("properties.schema_version MUST exist as a JSON object.")

if schema_version.get("type") != "string":
    fail("properties.schema_version.type MUST be 'string'.")

if schema_version.get("const") != "1.0":
    fail("properties.schema_version.const MUST be '1.0'.")
PY
}

schema_assert_runtime_dual_contract() {
  local schema_path="$1"

  python3 - "$schema_path" <<'PY'
import json
import sys

schema_path = sys.argv[1]

with open(schema_path, "r", encoding="utf-8") as fh:
    schema = json.load(fh)

def fail(msg):
    print(f"Runtime dual contract check failed: {schema_path}")
    print(msg)
    sys.exit(1)

properties = schema.get("properties", {})
if not isinstance(properties, dict):
    fail("top-level properties MUST be a JSON object.")

gateway = properties.get("gateway")
if not isinstance(gateway, dict):
    fail("properties.gateway MUST exist as a JSON object.")

gateway_required = gateway.get("required", [])
if not isinstance(gateway_required, list):
    fail("gateway.required MUST be a JSON array.")

for field in ("bind", "control_plane"):
    if field not in gateway_required:
        fail(f"gateway.required MUST include '{field}'.")

if "http" in gateway_required:
    fail("gateway.required MUST NOT include 'http' (chatCompletions remains optional under policy).")

gateway_props = gateway.get("properties", {})
if not isinstance(gateway_props, dict):
    fail("gateway.properties MUST be a JSON object.")

control_plane = gateway_props.get("control_plane")
if not isinstance(control_plane, dict):
    fail("gateway.properties.control_plane MUST exist as a JSON object.")

control_plane_required = control_plane.get("required", [])
if not isinstance(control_plane_required, list) or "ws" not in control_plane_required:
    fail("gateway.properties.control_plane.required MUST include 'ws'.")

http = gateway_props.get("http")
if not isinstance(http, dict):
    fail("gateway.properties.http MUST exist as a JSON object.")

http_props = http.get("properties", {})
if not isinstance(http_props, dict):
    fail("gateway.properties.http.properties MUST be a JSON object.")

endpoints = http_props.get("endpoints")
if not isinstance(endpoints, dict):
    fail("gateway.properties.http.properties.endpoints MUST exist as a JSON object.")

endpoints_props = endpoints.get("properties", {})
if not isinstance(endpoints_props, dict):
    fail("gateway.properties.http.properties.endpoints.properties MUST be a JSON object.")

chat_completions = endpoints_props.get("chatCompletions")
if not isinstance(chat_completions, dict):
    fail("gateway.http.endpoints.chatCompletions path MUST exist in schema.")

chat_required = chat_completions.get("required", [])
if not isinstance(chat_required, list) or "enabled" not in chat_required:
    fail("gateway.http.endpoints.chatCompletions.required MUST include 'enabled'.")

chat_props = chat_completions.get("properties", {})
if not isinstance(chat_props, dict) or "enabled" not in chat_props:
    fail("gateway.http.endpoints.chatCompletions.properties.enabled MUST exist in schema.")
PY
}

schema_assert_provider_path_shape() {
  local schema_path="$1"

  python3 - "$schema_path" <<'PY'
import json
import sys

schema_path = sys.argv[1]

with open(schema_path, "r", encoding="utf-8") as fh:
    schema = json.load(fh)

def fail(msg):
    print(f"provider_path shape check failed: {schema_path}")
    print(msg)
    sys.exit(1)

properties = schema.get("properties", {})
if not isinstance(properties, dict):
    fail("top-level properties MUST be a JSON object.")

provider_path = properties.get("provider_path")
if not isinstance(provider_path, dict):
    fail("properties.provider_path MUST exist as a JSON object.")

if provider_path.get("type") != "array":
    fail("provider_path.type MUST be 'array'.")

min_items = provider_path.get("minItems")
if not isinstance(min_items, int) or min_items < 1:
    fail("provider_path.minItems MUST be an integer >= 1.")

items = provider_path.get("items")
if not isinstance(items, dict):
    fail("provider_path.items MUST be a JSON object.")

if items.get("type") != "string":
    fail("provider_path.items.type MUST be 'string'.")

min_length = items.get("minLength")
if not isinstance(min_length, int) or min_length < 1:
    fail("provider_path.items.minLength MUST be an integer >= 1.")
PY
}

required_files=(
  "INTEGRATIONS/README.md"
  "INTEGRATIONS/AI-TRADER.md"
  "INTEGRATIONS/CLAWWORK.md"
  "INTEGRATIONS/OPENCLAW-UPSTREAM.md"
  "ARC/schemas/signal_intent.schema.json"
  "ARC/schemas/order_intent.schema.json"
  "ARC/schemas/execution_report.schema.json"
  "ARC/schemas/economic_run.schema.json"
  "ARC/schemas/openclaw_runtime_config.schema.json"
)
for f in "${required_files[@]}"; do
  [[ -f "$f" ]] || { echo "Arquivo obrigatorio ausente: $f"; exit 1; }
done

schema_files=(
  "ARC/schemas/signal_intent.schema.json"
  "ARC/schemas/order_intent.schema.json"
  "ARC/schemas/execution_report.schema.json"
  "ARC/schemas/economic_run.schema.json"
  "ARC/schemas/openclaw_runtime_config.schema.json"
)
for s in "${schema_files[@]}"; do
  python3 -m json.tool "$s" >/dev/null
done

schema_assert_minimum_contract \
  "ARC/schemas/signal_intent.schema.json" \
  "intent_id,source_engine,symbol,side,confidence,thesis,time_horizon,as_of,trace_id" \
  "intent_id,source_engine,symbol,side,confidence,thesis,time_horizon,as_of,trace_id"

schema_assert_minimum_contract \
  "ARC/schemas/order_intent.schema.json" \
  "order_intent_id,signal_intent_id,symbol,side,order_type,quantity,stage,decision_id,approved_by,approved_at" \
  "order_intent_id,signal_intent_id,symbol,side,order_type,quantity,stage,decision_id,approved_by,approved_at"

schema_assert_minimum_contract \
  "ARC/schemas/execution_report.schema.json" \
  "execution_report_id,order_intent_id,venue,status,filled_qty,avg_price,timestamp,gateway_trace_id" \
  "execution_report_id,order_intent_id,venue,status,filled_qty,avg_price,timestamp,gateway_trace_id"

schema_assert_minimum_contract \
  "ARC/schemas/economic_run.schema.json" \
  "run_id,benchmark,scenario,success,quality_score,total_cost_usd,provider_path,started_at,ended_at" \
  "run_id,benchmark,scenario,success,quality_score,total_cost_usd,provider_path,started_at,ended_at"

schema_assert_version_metadata "ARC/schemas/signal_intent.schema.json"
schema_assert_version_metadata "ARC/schemas/order_intent.schema.json"
schema_assert_version_metadata "ARC/schemas/execution_report.schema.json"
schema_assert_version_metadata "ARC/schemas/economic_run.schema.json"

schema_assert_runtime_dual_contract "ARC/schemas/openclaw_runtime_config.schema.json"
schema_assert_provider_path_shape "ARC/schemas/economic_run.schema.json"

openrouter_rule="OpenRouter e adaptador cloud opcional, permanece desabilitado por default e so pode ser habilitado por decision formal; quando cloud adicional estiver habilitado, OpenRouter e o preferido."
search_fixed_each_file "$openrouter_rule" README.md PRD/ROADMAP.md PRD/PRD-MASTER.md ARC/ARC-MODEL-ROUTING.md SEC/SEC-POLICY.md

search_re 'cloud_adapter_default: "disabled"' SEC/allowlists/PROVIDERS.yaml
search_re 'cloud_adapter_enablement: "decision_required"' SEC/allowlists/PROVIDERS.yaml
search_re 'cloud_adapter_preferred_when_enabled: "openrouter"' SEC/allowlists/PROVIDERS.yaml

search_absent_re "OpenRouter e o adaptador padrao recomendado" README.md PRD/ROADMAP.md PRD/PRD-MASTER.md ARC/ARC-MODEL-ROUTING.md
search_absent_re "OpenRouter MAY operar como adaptador cloud recomendado" SEC/SEC-POLICY.md
search_absent_re "adaptador cloud recomendado quando necessario" README.md
search_absent_re "OpenRouter e o adaptador recomendado quando operacao multi-provider estiver habilitada" PRD/ROADMAP.md

search_re "America/Sao_Paulo" PRD/PRD-MASTER.md ARC/ARC-HEARTBEAT.md workspaces/main/HEARTBEAT.md PRD/CHANGELOG.md
search_re "override deliberado de timezone.*America/Sao_Paulo" PRD/CHANGELOG.md

search_re "gateway\\.control_plane\\.ws" PRD/PRD-MASTER.md ARC/ARC-CORE.md INTEGRATIONS/OPENCLAW-UPSTREAM.md
search_re "chatCompletions" PRD/PRD-MASTER.md ARC/ARC-CORE.md INTEGRATIONS/OPENCLAW-UPSTREAM.md ARC/schemas/openclaw_runtime_config.schema.json

search_re_each_file "Matriz de Compatibilidade" INTEGRATIONS/OPENCLAW-UPSTREAM.md
search_re_each_file "control plane WS \\(canonico\\)" INTEGRATIONS/OPENCLAW-UPSTREAM.md
search_re_each_file "chatCompletions HTTP \\(opcional\\)" INTEGRATIONS/OPENCLAW-UPSTREAM.md
search_re_each_file "Matriz de Modos Permitidos" INTEGRATIONS/README.md
search_re_each_file "AI-Trader.*signal_only" INTEGRATIONS/README.md
search_re_each_file "ClawWork.*lab_isolated.*default.*governed.*gateway-only" INTEGRATIONS/README.md
search_re_each_file "OpenClaw upstream.*gateway\\.control_plane\\.ws.*chatCompletions.*opcional" INTEGRATIONS/README.md

search_fixed "MUST operar somente como gerador de \`signal_intent\`." INTEGRATIONS/AI-TRADER.md
search_fixed "MUST NOT enviar \`order_intent\` diretamente para venue/exchange." INTEGRATIONS/AI-TRADER.md
search_fixed "qualquer payload que represente ordem direta originada do AI-Trader MUST ser bloqueado e auditado." INTEGRATIONS/AI-TRADER.md

search_re_each_file "AI-Trader -> signal_intent -> normalizacao/deduplicacao -> pre_trade_validator -> HITL -> execution_gateway" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md
search_re_each_file "ordem direta originada do AI-Trader MUST ser rejeitado e auditado" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md

search_fixed "modo \`lab_isolated\` e default." INTEGRATIONS/CLAWWORK.md
search_fixed "modo \`governed\` MUST rotear toda chamada LLM via OpenClaw Gateway." INTEGRATIONS/CLAWWORK.md
search_fixed "chamada direta a provider externo no modo \`governed\` MUST ser bloqueada." INTEGRATIONS/CLAWWORK.md
search_re "E2B" INTEGRATIONS/CLAWWORK.md
search_re "provider_path" INTEGRATIONS/CLAWWORK.md ARC/schemas/economic_run.schema.json

echo "eval-integrations: PASS"
