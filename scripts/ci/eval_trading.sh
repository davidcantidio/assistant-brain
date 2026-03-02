#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

OUT_DIR="$ROOT/artifacts/generated/ci"
mkdir -p "$OUT_DIR"

python3 -m ci.checks.trading_contracts \
  --root "$ROOT" \
  --output "$OUT_DIR/policy-engine-trading.json"
