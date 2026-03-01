#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

WEEK_ID="${WEEK_ID:-$(date +%G-W%V)}"
SOURCE_OF_TRUTH="${SOURCE_OF_TRUTH:-PRD/PRD-MASTER.md}"
REPORT_PATH="${REPORT_PATH:-artifacts/phase-f8/epic-f8-04-multiasset-enablement.md}"
SHADOW_DIR="${SHADOW_DIR:-artifacts/trading/shadow_mode}"
FIXTURE_DIR="${FIXTURE_DIR:-scripts/ci/fixtures/trading/multiasset/shadow}"

python3 scripts/ci/phase_f8_multiasset_enablement.py render \
  --report-path "$REPORT_PATH" \
  --week-id "$WEEK_ID" \
  --source-of-truth "$SOURCE_OF_TRUTH" \
  --shadow-dir "$SHADOW_DIR"

python3 scripts/ci/phase_f8_multiasset_enablement.py check \
  --week-id "$WEEK_ID" \
  --report-path "$REPORT_PATH" \
  --shadow-dir "$SHADOW_DIR" \
  --fixture-dir "$FIXTURE_DIR"
