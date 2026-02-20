#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

bash scripts/ci/eval_models.sh
bash scripts/ci/eval_rag.sh
bash scripts/ci/eval_trading.sh

echo "eval-gates: PASS"
