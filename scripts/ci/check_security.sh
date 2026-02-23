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
if git grep -nE \
  -e 'sk-[A-Za-z0-9]{20,}' \
  -e 'xox[baprs]-[A-Za-z0-9-]{10,}' \
  -e 'AKIA[0-9A-Z]{16}' \
  -- . > /tmp/security_hits.txt; then
  echo "Possivel segredo detectado em arquivos versionados:"
  cat /tmp/security_hits.txt
  exit 1
else
  status=$?
  if [ "$status" -ne 1 ]; then
    echo "Falha ao executar scan de segredos (git grep exit=$status)"
    exit "$status"
  fi
fi

search_re "telegram_user_id" SEC/allowlists/OPERATORS.yaml
search_re "trading_live_requires_backup_operator" SEC/allowlists/OPERATORS.yaml

echo "security-check: PASS"
