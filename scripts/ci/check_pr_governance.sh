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

fail() {
  echo "pr-governance-check: FAIL - $1"
  exit 1
}

CODEOWNERS_PATH="${CODEOWNERS_PATH:-.github/CODEOWNERS}"
POLICY_DOC_PATH="${POLICY_DOC_PATH:-DEV/DEV-CI-RULES.md}"

[[ -f "$CODEOWNERS_PATH" ]] || fail "arquivo obrigatorio ausente: $CODEOWNERS_PATH"

if ! search_re '^\*\s+@davidcantidio\s*$' "$CODEOWNERS_PATH"; then
  fail "regra global obrigatoria ausente em $CODEOWNERS_PATH: '* @davidcantidio'"
fi

[[ -f "$POLICY_DOC_PATH" ]] || fail "documento de policy ausente: $POLICY_DOC_PATH"

required_terms=(
  "main.*protegida"
  "PR obrigatorio"
  "checks verdes"
  "excecao por decision"
  "CODEOWNERS"
)

for term in "${required_terms[@]}"; do
  if ! search_re "$term" "$POLICY_DOC_PATH"; then
    fail "termo normativo obrigatorio ausente em $POLICY_DOC_PATH: $term"
  fi
done

echo "pr-governance-check: PASS"
