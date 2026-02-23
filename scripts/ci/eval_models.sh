#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

python3 -m json.tool ARC/schemas/models_catalog.schema.json >/dev/null

required_patterns=(
  "## OpenRouter como Camada Padrao"
  "## Provider Variance e Provider Routing"
  "## Fallback Policy"
  "## Presets (governanca central)"
  "## Perfis Oficiais de Execucao"
)
for pattern in "${required_patterns[@]}"; do
  rg -Fn "$pattern" ARC/ARC-MODEL-ROUTING.md >/dev/null
done

required_files=(
  "SEC/allowlists/PROVIDERS.yaml"
  "SEC/SEC-POLICY.md"
  "PRD/PRD-MASTER.md"
)
for f in "${required_files[@]}"; do
  [[ -f "$f" ]] || { echo "Arquivo obrigatorio ausente: $f"; exit 1; }
done

rg -n "cloud/provider externo MUST passar por OpenRouter" SEC/SEC-POLICY.md >/dev/null
rg -n "chamada direta a API de provider externo fora do OpenRouter MUST ser bloqueada" SEC/SEC-POLICY.md >/dev/null

echo "eval-models: PASS"
