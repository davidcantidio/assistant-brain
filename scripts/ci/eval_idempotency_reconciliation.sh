#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

OUT_DIR="$ROOT/artifacts/generated/ci"
mkdir -p "$OUT_DIR"

"$ROOT/policy-engine" run \
  --domain runtime \
  --category idempotency \
  --format json \
  --root "$ROOT" \
  --output "$OUT_DIR/policy-engine-idempotency.json"

echo "eval-idempotency-reconciliation: PASS"
