#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

WEEK_ID="${WEEK_ID:-$(date +%G-W%V)}"
EXECUTED_AT="${EXECUTED_AT:-$(date '+%Y-%m-%dT%H:%M:%S%z')}"
EVAL_GATES_CMD="${EVAL_GATES_CMD:-make eval-gates}"
CI_QUALITY_CMD="${CI_QUALITY_CMD:-make ci-quality}"
CI_SECURITY_CMD="${CI_SECURITY_CMD:-make ci-security}"
CONTRACT_REVIEW_STATUS="${CONTRACT_REVIEW_STATUS:-FAIL}"
CRITICAL_DRIFTS_OPEN="${CRITICAL_DRIFTS_OPEN:-0}"

ARTIFACT_DIR="artifacts/phase-f8/weekly-governance"
LOG_DIR="${ARTIFACT_DIR}/logs/${WEEK_ID}"
REPORT_PATH="${ARTIFACT_DIR}/${WEEK_ID}.md"
STAMP="$(date '+%Y%m%dT%H%M%S')"

mkdir -p "$LOG_DIR"

run_and_capture() {
  local label="$1"
  local cmd="$2"
  local log_path="${LOG_DIR}/${STAMP}-${label}.log"

  echo ">>> ${cmd}" >"$log_path"
  if bash -lc "$cmd" >>"$log_path" 2>&1; then
    printf '%s|PASS|%s\n' "$label" "$log_path"
  else
    printf '%s|FAIL|%s\n' "$label" "$log_path"
  fi
}

EVAL_RESULT="$(run_and_capture "eval-gates" "$EVAL_GATES_CMD")"
QUALITY_RESULT="$(run_and_capture "ci-quality" "$CI_QUALITY_CMD")"
SECURITY_RESULT="$(run_and_capture "ci-security" "$CI_SECURITY_CMD")"

IFS='|' read -r _ EVAL_GATES_STATUS EVAL_LOG_PATH <<<"$EVAL_RESULT"
IFS='|' read -r _ CI_QUALITY_STATUS QUALITY_LOG_PATH <<<"$QUALITY_RESULT"
IFS='|' read -r _ CI_SECURITY_STATUS SECURITY_LOG_PATH <<<"$SECURITY_RESULT"

DECISION="hold"
if [[ "$EVAL_GATES_STATUS" == "PASS" && "$CI_QUALITY_STATUS" == "PASS" && "$CI_SECURITY_STATUS" == "PASS" && "$CONTRACT_REVIEW_STATUS" == "PASS" && "$CRITICAL_DRIFTS_OPEN" == "0" ]]; then
  DECISION="promote"
fi

RISK_NOTES="contract review default=${CONTRACT_REVIEW_STATUS}; verificar F8-02 para revisao contratual recorrente."
NEXT_ACTIONS="rerun semanal com trio de gates; publicar contract review da semana; revisar drifts criticos antes de promote."

cat >"$REPORT_PATH" <<EOF
# F8 Weekly Governance ${WEEK_ID}

- week_id: \`${WEEK_ID}\`
- executed_at: \`${EXECUTED_AT}\`
- eval_gates_status: \`${EVAL_GATES_STATUS}\`
- ci_quality_status: \`${CI_QUALITY_STATUS}\`
- ci_security_status: \`${CI_SECURITY_STATUS}\`
- contract_review_status: \`${CONTRACT_REVIEW_STATUS}\`
- critical_drifts_open: \`${CRITICAL_DRIFTS_OPEN}\`
- decision: \`${DECISION}\`
- risk_notes: ${RISK_NOTES}
- next_actions: ${NEXT_ACTIONS}

## Logs

- eval-gates: \`${EVAL_LOG_PATH}\`
- ci-quality: \`${QUALITY_LOG_PATH}\`
- ci-security: \`${SECURITY_LOG_PATH}\`
EOF

echo "phase-f8-weekly-governance: REPORT=${REPORT_PATH}"
echo "phase-f8-weekly-governance: decision=${DECISION}"
exit 0
