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
  "RAG/RAG-GENERAL.md"
  "RAG/RAG-INGESTION.md"
  "RAG/RAG-EVALS.md"
  "RAG/RAG-QUARANTINE.md"
  "EVALS/RAG-EVALS-TESTS.md"
)
for f in "${required_files[@]}"; do
  [[ -f "$f" ]] || { echo "Arquivo obrigatorio ausente: $f"; exit 1; }
done

search_re "citation coverage < 95%" RAG/RAG-EVALS.md
search_re "leakage > 0" RAG/RAG-EVALS.md
search_re "accuracy < 90%" RAG/RAG-EVALS.md
search_re "make eval-rag" EVALS/RAG-EVALS-TESTS.md

echo "eval-rag: PASS"
