#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

WEEK_ID="${WEEK_ID:-$(date +%G-W%V)}"
CONTRACT_REVIEW_DIR="${CONTRACT_REVIEW_DIR:-artifacts/phase-f8/contract-review}"

python3 scripts/ci/phase_f8_contract_review.py read \
  --week-id "$WEEK_ID" \
  --review-dir "$CONTRACT_REVIEW_DIR"
