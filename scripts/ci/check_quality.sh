#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

OUT_DIR="$ROOT/artifacts/generated/ci"
mkdir -p "$OUT_DIR"

"$ROOT/policy-engine" validate \
  --quality \
  --root "$ROOT" \
  --output "$OUT_DIR/policy-engine-quality.json"

"$ROOT/policy-engine" run \
  --domain governance \
  --category governance_contract \
  --format json \
  --root "$ROOT" \
  --output "$OUT_DIR/policy-engine-governance-hard-gates.json"

echo "quality-links: PASS"

bash scripts/ci/check_pm_issue_quality.sh
bash scripts/ci/check_pm_audit_paths.sh
bash scripts/ci/check_policy_convergence.sh
bash scripts/ci/check_governance_kpis.sh
bash scripts/ci/check_pr_governance.sh
bash scripts/ci/check_repo_hygiene.sh
bash scripts/ci/check_architecture_consistency_backlog.sh
bash scripts/ci/check_phase_f8_contract_review.sh
bash scripts/ci/check_phase_f8_weekly_governance.sh
bash scripts/ci/check_phase_f8_multiasset_contracts.sh
bash scripts/ci/check_phase_f8_multiasset_enablement.sh
bash scripts/ci/check_phase_f9_litellm_keygen.sh
bash scripts/ci/check_phase_f10_runtime_convergence.sh

echo "quality-check: PASS"
