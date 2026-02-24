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

openrouter_rule="OpenRouter e adaptador cloud opcional, permanece desabilitado por default e so pode ser habilitado por decision formal; quando cloud adicional estiver habilitado, OpenRouter e o preferido."
search_fixed "$openrouter_rule" README.md PRD/ROADMAP.md PRD/PRD-MASTER.md ARC/ARC-MODEL-ROUTING.md SEC/SEC-POLICY.md

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

search_re "Matriz de Compatibilidade" INTEGRATIONS/OPENCLAW-UPSTREAM.md
search_re "control plane WS \\(canonico\\)" INTEGRATIONS/OPENCLAW-UPSTREAM.md
search_re "chatCompletions HTTP \\(opcional\\)" INTEGRATIONS/OPENCLAW-UPSTREAM.md

search_fixed "MUST operar somente como gerador de \`signal_intent\`." INTEGRATIONS/AI-TRADER.md
search_fixed "MUST NOT enviar \`order_intent\` diretamente para venue/exchange." INTEGRATIONS/AI-TRADER.md
search_fixed "qualquer payload que represente ordem direta originada do AI-Trader MUST ser bloqueado e auditado." INTEGRATIONS/AI-TRADER.md

search_re "AI-Trader -> signal_intent -> normalizacao/deduplicacao -> pre_trade_validator -> HITL -> execution_gateway" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md
search_re "ordem direta originada do AI-Trader MUST ser rejeitado e auditado" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md

search_fixed "modo \`lab_isolated\` e default." INTEGRATIONS/CLAWWORK.md
search_fixed "modo \`governed\` MUST rotear toda chamada LLM via OpenClaw Gateway." INTEGRATIONS/CLAWWORK.md
search_fixed "chamada direta a provider externo no modo \`governed\` MUST ser bloqueada." INTEGRATIONS/CLAWWORK.md
search_re "E2B" INTEGRATIONS/CLAWWORK.md
search_re "provider_path" INTEGRATIONS/CLAWWORK.md ARC/schemas/economic_run.schema.json

echo "eval-integrations: PASS"
