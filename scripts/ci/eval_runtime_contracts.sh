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

required_files=(
  "META/DOCUMENT-HIERARCHY.md"
  "PRD/PRD-MASTER.md"
  "ARC/ARC-CORE.md"
  "ARC/schemas/openclaw_runtime_config.schema.json"
  "SEC/SEC-POLICY.md"
  "PM/DECISION-PROTOCOL.md"
  "ARC/ARC-HEARTBEAT.md"
  "workspaces/main/HEARTBEAT.md"
  "workspaces/main/MEMORY.md"
)
for f in "${required_files[@]}"; do
  [[ -f "$f" ]] || { echo "Arquivo obrigatorio ausente: $f"; exit 1; }
done

python3 -m json.tool ARC/schemas/openclaw_runtime_config.schema.json >/dev/null

# Canonical precedence
search_re "felixcraft\.md" META/DOCUMENT-HIERARCHY.md

# Runtime contract and A2A/hooks
search_re 'Contrato Canonico `openclaw_runtime_config`' PRD/PRD-MASTER.md
search_re "tools\.agentToAgent\.enabled" PRD/PRD-MASTER.md ARC/ARC-CORE.md
search_re "tools\.agentToAgent\.allow\[\]" PRD/PRD-MASTER.md ARC/ARC-CORE.md
search_re "hooks\.enabled" PRD/PRD-MASTER.md ARC/ARC-CORE.md
search_re "hooks\.mappings\[\]" PRD/PRD-MASTER.md ARC/ARC-CORE.md
search_re "hooks\.internal\.entries\[\]" PRD/PRD-MASTER.md ARC/ARC-CORE.md
search_re "gateway\.bind = loopback" PRD/PRD-MASTER.md ARC/ARC-CORE.md
search_re "chatCompletions" PRD/PRD-MASTER.md ARC/ARC-CORE.md

# Memory lifecycle contract
search_re 'Contrato `memory_contract`' PRD/PRD-MASTER.md
search_re "nightly-extraction" PRD/PRD-MASTER.md ARC/ARC-HEARTBEAT.md
search_re "workspaces/main/MEMORY\.md" PRD/PRD-MASTER.md META/DOCUMENT-HIERARCHY.md
if ! ls workspaces/main/memory/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md >/dev/null 2>&1; then
  echo "Nenhuma nota diaria encontrada em workspaces/main/memory/YYYY-MM-DD.md"
  exit 1
fi

# Channel trust + financial hard gate
search_re "email.*nunca.*canal confiavel de comando|canal nao confiavel para comando" PRD/PRD-MASTER.md SEC/SEC-POLICY.md PM/DECISION-PROTOCOL.md
search_re "aprovacao humana explicita" PRD/PRD-MASTER.md SEC/SEC-POLICY.md VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-RISK-RULES.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md

# Heartbeat baseline alignment
search_re "baseline unico de 15 minutos|base global: 15 minutos" ARC/ARC-HEARTBEAT.md
search_re "Baseline oficial: 15 minutos" workspaces/main/HEARTBEAT.md

echo "eval-runtime-contracts: PASS"
