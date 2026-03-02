#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

OUT_DIR="$ROOT/artifacts/generated/ci"
mkdir -p "$OUT_DIR"

"$ROOT/policy-engine" validate \
  --consistency \
  --root "$ROOT" \
  --output "$OUT_DIR/policy-engine-convergence.json"

echo "policy-convergence-check: PASS"
