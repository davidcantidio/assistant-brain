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

python3 -m json.tool ARC/schemas/models_catalog.schema.json >/dev/null

required_patterns=(
  "## OpenClaw Gateway e Adapters Cloud"
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

search_re "chamadas programaticas de inferencia MUST passar pelo gateway OpenClaw" SEC/SEC-POLICY.md
search_re "chamada direta a API de provider externo fora do gateway OpenClaw MUST ser bloqueada" SEC/SEC-POLICY.md
search_re "LiteLLM MUST operar como adaptador padrao para supervisores pagos" SEC/SEC-POLICY.md
search_re "gateway\\.supervisor_adapter.*LiteLLM" PRD/PRD-MASTER.md
search_re "qwen2\\.5-coder:32b" PRD/PRD-MASTER.md
search_re "deepseek-r1:32b" PRD/PRD-MASTER.md
search_re "OpenRouter fica desabilitado no baseline" PRD/PRD-MASTER.md
search_absent_re "OpenRouter e o adaptador padrao recomendado" PRD/PRD-MASTER.md ARC/ARC-MODEL-ROUTING.md
search_absent_re "OpenRouter MAY operar como adaptador cloud recomendado" SEC/SEC-POLICY.md

echo "eval-models: PASS"
