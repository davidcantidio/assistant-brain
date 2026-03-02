#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

if ! command -v git >/dev/null 2>&1; then
  echo "repo-hygiene-check: FAIL - git nao encontrado"
  exit 1
fi

search_tracked() {
  local pattern="$1"
  if command -v rg >/dev/null 2>&1; then
    git ls-files | rg "$pattern" || true
    return
  fi
  git ls-files | grep -E "$pattern" || true
}

tracked_noise="$(search_tracked '(^|/)(__pycache__/|\.DS_Store$|.*\.swp$|.*\.swo$|.*\.pyc$)')"
if [[ -n "$tracked_noise" ]]; then
  echo "repo-hygiene-check: FAIL - arquivos de ruido versionados"
  printf '%s\n' "$tracked_noise"
  exit 1
fi

tracked_generated="$(search_tracked '^artifacts/phase-f10/runtime-(convergence-report|inventory|merge-plan)-.*\.json$')"
if [[ -n "$tracked_generated" ]]; then
  echo "repo-hygiene-check: FAIL - snapshots runtime temporarios nao devem ser versionados"
  printf '%s\n' "$tracked_generated"
  exit 1
fi

echo "repo-hygiene-check: PASS"
