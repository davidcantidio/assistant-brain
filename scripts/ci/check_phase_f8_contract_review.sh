#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

CONTRACT_REVIEW_DIR="${CONTRACT_REVIEW_DIR:-artifacts/phase-f8/contract-review}"

resolve_week_id() {
  if [[ -n "${WEEK_ID:-}" ]]; then
    echo "$WEEK_ID"
    return 0
  fi

  local current_week
  current_week="$(date +%G-W%V)"
  if [[ -f "$CONTRACT_REVIEW_DIR/$current_week.md" ]]; then
    echo "$current_week"
    return 0
  fi

  shopt -s nullglob
  local candidates=("$CONTRACT_REVIEW_DIR"/[0-9][0-9][0-9][0-9]-W[0-9][0-9].md)
  shopt -u nullglob

  if [[ "${#candidates[@]}" -eq 0 ]]; then
    echo "[F8-CONTRACT] nenhum baseline encontrado em $CONTRACT_REVIEW_DIR" >&2
    return 1
  fi

  printf '%s\n' "${candidates[@]##*/}" | sed 's/\.md$//' | sort | tail -n 1
}

WEEK_ID_RESOLVED="$(resolve_week_id)"

python3 scripts/ci/phase_f8_contract_review.py check \
  --week-id "$WEEK_ID_RESOLVED" \
  --review-dir "$CONTRACT_REVIEW_DIR"
