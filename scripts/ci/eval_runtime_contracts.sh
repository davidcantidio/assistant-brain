#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

OUT_DIR="$ROOT/artifacts/generated/ci"
mkdir -p "$OUT_DIR"

"$ROOT/policy-engine" run \
  --domain runtime \
  --format json \
  --root "$ROOT" \
  --output "$OUT_DIR/policy-engine-runtime.json"

bash scripts/ci/eval_runtime_control_plane.sh

echo "eval-runtime-contracts: PASS"
