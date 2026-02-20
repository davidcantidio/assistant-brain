#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

required_files=(
  "VERTICALS/TRADING/TRADING-PRD.md"
  "VERTICALS/TRADING/TRADING-RISK-RULES.md"
  "VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md"
  "SEC/allowlists/ACTIONS.yaml"
)
for f in "${required_files[@]}"; do
  [[ -f "$f" ]] || { echo "Arquivo obrigatorio ausente: $f"; exit 1; }
done

rg -n "S0 - Paper/Sandbox" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md >/dev/null
rg -n "execution_gateway" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md >/dev/null
rg -n "pre_trade_validator" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md >/dev/null
rg -n "Definicao de .*safe_notional" VERTICALS/TRADING/TRADING-RISK-RULES.md >/dev/null
rg -n "pre_live_checklist" VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md PRD/PRD-MASTER.md >/dev/null
rg -n "make eval-trading" VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md DEV/DEV-CI-RULES.md >/dev/null

echo "eval-trading: PASS"
