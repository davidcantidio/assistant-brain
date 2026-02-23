#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

required_files=(
  "SEC/allowlists/DOMAINS.yaml"
  "SEC/allowlists/TOOLS.yaml"
  "SEC/allowlists/ACTIONS.yaml"
  "SEC/allowlists/OPERATORS.yaml"
  "SEC/allowlists/PROVIDERS.yaml"
)
for f in "${required_files[@]}"; do
  [[ -f "$f" ]] || { echo "Arquivo obrigatorio ausente: $f"; exit 1; }
done

# basic leak signatures in tracked files
if git ls-files | xargs rg -n --no-messages --no-heading -e 'sk-[A-Za-z0-9]{20,}' -e 'xox[baprs]-[A-Za-z0-9-]{10,}' -e 'AKIA[0-9A-Z]{16}' >/tmp/security_hits.txt; then
  echo "Possivel segredo detectado em arquivos versionados:"
  cat /tmp/security_hits.txt
  exit 1
fi

rg -n "telegram_user_id" SEC/allowlists/OPERATORS.yaml >/dev/null
rg -n "trading_live_requires_backup_operator" SEC/allowlists/OPERATORS.yaml >/dev/null

echo "security-check: PASS"
