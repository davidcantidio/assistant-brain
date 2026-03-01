#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

search_re() {
  local pattern="$1"
  shift
  if command -v rg >/dev/null 2>&1; then
    rg -n -- "$pattern" "$@" >/dev/null
  else
    grep -nE -- "$pattern" "$@" >/dev/null
  fi
}

python3 -m json.tool PM/policies/f2-risk-gate-matrix.json >/dev/null

python3 - <<'PY'
import json
import sys
from pathlib import Path


def fail(msg: str) -> None:
    print(msg)
    sys.exit(1)


path = Path("PM/policies/f2-risk-gate-matrix.json")
payload = json.loads(path.read_text(encoding="utf-8"))
if payload.get("phase") != "F2":
    fail("f2-risk-gate-matrix.json invalido: phase deve ser F2.")

matrix = payload.get("risk_gate_matrix")
if not isinstance(matrix, dict):
    fail("f2-risk-gate-matrix.json invalido: risk_gate_matrix ausente.")

expected = {
    "R0": ["schema", "patch_hygiene"],
    "R1": ["schema", "patch_hygiene", "static", "unit"],
    "R2": ["schema", "patch_hygiene", "static", "unit", "integration", "security"],
    "R3": ["schema", "patch_hygiene", "static", "unit", "integration", "security"],
}

for tier, gates in expected.items():
    tier_payload = matrix.get(tier)
    if not isinstance(tier_payload, dict):
        fail(f"f2-risk-gate-matrix.json invalido: tier ausente {tier}.")
    if tier_payload.get("required_gates") != gates:
        fail(f"f2-risk-gate-matrix.json invalido: required_gates incorreto para {tier}.")
    if tier in {"R2", "R3"} and tier_payload.get("gatekeeper_required") is not True:
        fail(f"f2-risk-gate-matrix.json invalido: {tier} deve exigir gatekeeper.")
    if tier in {"R2", "R3"} and tier_payload.get("pre_live_checklist_required") is not True:
        fail(f"f2-risk-gate-matrix.json invalido: {tier} deve exigir pre_live_checklist.")
PY

search_re "R2.*schema.*patch_hygiene.*static.*unit.*integration.*security" PRD/PRD-MASTER.md
search_re 'R3.*todos de `R2`.*seguranca/compliance' PRD/PRD-MASTER.md
search_re "Gatekeeper/Reviewer" PRD/PRD-MASTER.md
search_re "Gatekeeper/Reviewer" PM/DECISION-PROTOCOL.md
search_re "pre_live_checklist" PRD/PRD-MASTER.md

echo "eval-risk-gates: PASS"
