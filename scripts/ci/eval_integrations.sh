#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
OUTPUT_PATH="${ROOT}/artifacts/generated/ci/eval-integrations.json"

python3 -m ci.checks.integrations_contracts \
  --root "$ROOT" \
  --output "$OUTPUT_PATH"
