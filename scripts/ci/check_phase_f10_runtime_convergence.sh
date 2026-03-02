#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

required_files=(
  "PM/PHASES/F10-CONVERGENCIA-PRD-RUNTIME-SEM-REGRESSAO/EPICS.md"
  "PM/PHASES/F10-CONVERGENCIA-PRD-RUNTIME-SEM-REGRESSAO/EPIC-F10-01-AUDITORIA-E-BASELINE-RUNTIME.md"
  "PM/PHASES/F10-CONVERGENCIA-PRD-RUNTIME-SEM-REGRESSAO/EPIC-F10-02-CONVERGENCIA-PRD-SEM-PERDA-DE-ESTADO.md"
  "PM/PHASES/F10-CONVERGENCIA-PRD-RUNTIME-SEM-REGRESSAO/EPIC-F10-03-ROLLOUT-CANARIO-E-PROMOCAO.md"
  "artifacts/phase-f10/epic-f10-01-runtime-baseline-audit.md"
  "artifacts/phase-f10/epic-f10-02-runtime-merge-policy.md"
  "artifacts/phase-f10/epic-f10-03-canary-rollout-playbook.md"
  "scripts/runtime/export_runtime_state.sh"
  "scripts/runtime/build_runtime_merge_plan.py"
  "scripts/runtime/apply_runtime_merge_plan.sh"
  "scripts/runtime/verify_runtime_convergence.sh"
)

for file in "${required_files[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "[F10-MISSING] arquivo obrigatorio ausente: $file"
    exit 1
  fi
done

required_exec=(
  "scripts/runtime/export_runtime_state.sh"
  "scripts/runtime/apply_runtime_merge_plan.sh"
  "scripts/runtime/verify_runtime_convergence.sh"
  "scripts/ci/check_phase_f10_runtime_convergence.sh"
)

for file in "${required_exec[@]}"; do
  if [[ ! -x "$file" ]]; then
    echo "[F10-PERMS] script deve ser executavel: $file"
    exit 1
  fi
done

python3 -m py_compile scripts/runtime/build_runtime_merge_plan.py

if ! rg -n "runtime_inventory\.v1|runtime_merge_plan\.v1" PM/PHASES/F10-CONVERGENCIA-PRD-RUNTIME-SEM-REGRESSAO artifacts/phase-f10 >/dev/null; then
  echo "[F10-CONTRACT] referencias obrigatorias de runtime_inventory.v1/runtime_merge_plan.v1 nao encontradas."
  exit 1
fi

if ! rg -n "EPIC-F10-01|EPIC-F10-02|EPIC-F10-03" PM/PHASES/F10-CONVERGENCIA-PRD-RUNTIME-SEM-REGRESSAO/EPICS.md >/dev/null; then
  echo "[F10-EPICS] EPICS.md sem referencias completas dos 3 epicos F10."
  exit 1
fi

echo "check-phase-f10-runtime-convergence: PASS"
