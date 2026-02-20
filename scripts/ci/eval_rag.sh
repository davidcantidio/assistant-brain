#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

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

rg -n "citation coverage < 95%" RAG/RAG-EVALS.md >/dev/null
rg -n "leakage > 0" RAG/RAG-EVALS.md >/dev/null
rg -n "accuracy < 90%" RAG/RAG-EVALS.md >/dev/null
rg -n "make eval-rag" EVALS/RAG-EVALS-TESTS.md >/dev/null

echo "eval-rag: PASS"
