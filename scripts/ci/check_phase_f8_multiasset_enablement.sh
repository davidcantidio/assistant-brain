#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

REPORT_PATH="${REPORT_PATH:-artifacts/phase-f8/epic-f8-04-multiasset-enablement.md}"
SHADOW_DIR="${SHADOW_DIR:-artifacts/trading/shadow_mode}"
FIXTURE_DIR="${FIXTURE_DIR:-scripts/ci/fixtures/trading/multiasset/shadow}"

resolve_week_id() {
  if [[ -n "${WEEK_ID:-}" ]]; then
    echo "$WEEK_ID"
    return 0
  fi

  if [[ -f "$REPORT_PATH" ]]; then
    local report_week
    report_week="$(sed -n 's/^- week_id: `\([^`]*\)`$/\1/p' "$REPORT_PATH" | head -n 1)"
    if [[ -n "$report_week" ]]; then
      echo "$report_week"
      return 0
    fi
  fi

  echo "$(date +%G-W%V)"
}

WEEK_ID_RESOLVED="$(resolve_week_id)"

python3 scripts/ci/phase_f8_multiasset_enablement.py check \
  --week-id "$WEEK_ID_RESOLVED" \
  --report-path "$REPORT_PATH" \
  --shadow-dir "$SHADOW_DIR" \
  --fixture-dir "$FIXTURE_DIR"
