#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

echo "[phase-f2-gate] running ci-quality"
bash scripts/ci/check_quality.sh

echo "[phase-f2-gate] running ci-security"
bash scripts/ci/check_security.sh

echo "[phase-f2-gate] running eval-gates"
bash scripts/ci/eval_gates.sh

echo "[phase-f2-gate] validating degraded reconciliation status"
python3 - <<'PY'
import json
import sys
from pathlib import Path


def fail(msg: str) -> None:
    print(msg)
    sys.exit(1)


path = Path("artifacts/phase-f2/degraded-reconciliation-status.json")
if not path.exists():
    fail("degraded reconciliation status ausente: artifacts/phase-f2/degraded-reconciliation-status.json")

payload = json.loads(path.read_text(encoding="utf-8"))
if payload.get("status") != "reconciled":
    fail("degraded reconciliation status invalido: status deve ser reconciled.")
if payload.get("promotion_blocked") is not False:
    fail("degraded reconciliation status invalido: promotion_blocked deve ser false.")
if not payload.get("reconciled_at"):
    fail("degraded reconciliation status invalido: reconciled_at obrigatorio.")
if not payload.get("evidence_ref"):
    fail("degraded reconciliation status invalido: evidence_ref obrigatorio.")
PY

echo "phase-f2-gate: PASS"
