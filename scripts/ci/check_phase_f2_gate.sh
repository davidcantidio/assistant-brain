#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

echo "[phase-f2-gate] running ci-quality"
bash scripts/ci/check_quality.sh

echo "[phase-f2-gate] running ci-security"
bash scripts/ci/check_security.sh

echo "[phase-f2-gate] running eval-gates"
bash scripts/ci/eval_gates.sh

echo "phase-f2-gate: PASS"
