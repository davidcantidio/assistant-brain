#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

OUT_DIR="$ROOT/artifacts/generated/ci"
mkdir -p "$OUT_DIR"

python3 scripts/ci/governance_kpis.py \
  --root "$ROOT" \
  --output "$OUT_DIR/governance-kpis.json"
