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

required_files=(
  "VERTICALS/TRADING/TRADING-PRD.md"
  "VERTICALS/TRADING/TRADING-RISK-RULES.md"
  "VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md"
  "SEC/allowlists/ACTIONS.yaml"
  "SEC/allowlists/DOMAINS.yaml"
)
for f in "${required_files[@]}"; do
  [[ -f "$f" ]] || { echo "Arquivo obrigatorio ausente: $f"; exit 1; }
done

search_re "S0 - Paper/Sandbox" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md
search_re "execution_gateway" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md
search_re "pre_trade_validator" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md
search_re_each_file "TradingAgents.*engine primaria de sinal" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md
search_re_each_file "AI-Trader -> signal_intent -> normalizacao/deduplicacao -> pre_trade_validator -> HITL -> execution_gateway" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md
search_re_each_file "ordem direta originada do AI-Trader MUST ser rejeitado e auditado" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md
search_re_each_file 'caminho de execucao unico confirmado: somente `execution_gateway` pode enviar ordem live' VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md
search_re_each_file "dominio de venue ativo.*SEC/allowlists/DOMAINS\\.yaml.*dominio fora da allowlist" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md
search_re "Definicao de .*safe_notional" VERTICALS/TRADING/TRADING-RISK-RULES.md
search_re "pre_live_checklist" VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md PRD/PRD-MASTER.md
search_re "make eval-trading" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md DEV/DEV-CI-RULES.md
search_re "trading_phase1_binance" SEC/allowlists/DOMAINS.yaml
search_re "api\\.binance\\.com" SEC/allowlists/DOMAINS.yaml
search_re "deny:" SEC/allowlists/DOMAINS.yaml

echo "eval-trading: PASS"
