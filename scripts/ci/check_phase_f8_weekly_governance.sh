#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

OUT_DIR="$ROOT/artifacts/generated/ci"
mkdir -p "$OUT_DIR"

"$ROOT/policy-engine" run \
  --domain governance \
  --category weekly_governance \
  --root "$ROOT" \
  --output "$OUT_DIR/policy-engine-governance-weekly.json"

echo "phase-f8-weekly-governance: PASS"
