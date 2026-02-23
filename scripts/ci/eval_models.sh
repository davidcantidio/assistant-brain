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

python3 -m json.tool ARC/schemas/models_catalog.schema.json >/dev/null

required_patterns=(
  "## OpenRouter como Camada Padrao"
  "## Provider Variance e Provider Routing"
  "## Fallback Policy"
  "## Presets (governanca central)"
  "## Perfis Oficiais de Execucao"
)
for pattern in "${required_patterns[@]}"; do
  search_fixed "$pattern" ARC/ARC-MODEL-ROUTING.md
done

required_files=(
  "SEC/allowlists/PROVIDERS.yaml"
  "SEC/SEC-POLICY.md"
  "PRD/PRD-MASTER.md"
)
for f in "${required_files[@]}"; do
  [[ -f "$f" ]] || { echo "Arquivo obrigatorio ausente: $f"; exit 1; }
done

search_re "cloud/provider externo MUST passar por OpenRouter" SEC/SEC-POLICY.md
search_re "chamada direta a API de provider externo fora do OpenRouter MUST ser bloqueada" SEC/SEC-POLICY.md

echo "eval-models: PASS"
