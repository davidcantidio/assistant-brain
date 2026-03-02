#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

PYTHONPATH="$ROOT/apps/control-plane/src:$ROOT/apps/ops-api/src"

PYTHONPATH="$PYTHONPATH" python3 -m unittest discover \
  -s apps/control-plane/tests \
  -p 'test_*.py'

PYTHONPATH="$PYTHONPATH" python3 -m unittest discover \
  -s apps/ops-api/tests \
  -p 'test_*.py'

echo "eval-runtime-control-plane: PASS"
