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

ARTIFACT_DIR="${ARTIFACT_DIR:-artifacts/phase-f8/weekly-governance}"
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

write_skip_log() {
  local label="$1"
  local reason="$2"
  local log_path="${LOG_DIR}/${STAMP}-${label}.log"

  {
    echo ">>> SKIPPED"
    echo "$reason"
  } >"$log_path"

  printf '%s|FAIL|%s\n' "$label" "$log_path"
}

FAILED_GATE=""

EVAL_RESULT="$(run_and_capture "eval-gates" "$EVAL_GATES_CMD")"
IFS='|' read -r _ EVAL_GATES_STATUS EVAL_LOG_PATH <<<"$EVAL_RESULT"

if [[ "$EVAL_GATES_STATUS" == "FAIL" ]]; then
  FAILED_GATE="eval-gates"
  QUALITY_RESULT="$(write_skip_log "ci-quality" "fail-fast: ci-quality nao executado porque eval-gates falhou.")"
  SECURITY_RESULT="$(write_skip_log "ci-security" "fail-fast: ci-security nao executado porque eval-gates falhou.")"
else
  QUALITY_RESULT="$(run_and_capture "ci-quality" "$CI_QUALITY_CMD")"
  IFS='|' read -r _ CI_QUALITY_STATUS QUALITY_LOG_PATH <<<"$QUALITY_RESULT"

  if [[ "$CI_QUALITY_STATUS" == "FAIL" ]]; then
    FAILED_GATE="ci-quality"
    SECURITY_RESULT="$(write_skip_log "ci-security" "fail-fast: ci-security nao executado porque ci-quality falhou.")"
  else
    SECURITY_RESULT="$(run_and_capture "ci-security" "$CI_SECURITY_CMD")"
  fi
fi

IFS='|' read -r _ CI_QUALITY_STATUS QUALITY_LOG_PATH <<<"$QUALITY_RESULT"
IFS='|' read -r _ CI_SECURITY_STATUS SECURITY_LOG_PATH <<<"$SECURITY_RESULT"

DECISION="hold"
if [[ "$EVAL_GATES_STATUS" == "PASS" && "$CI_QUALITY_STATUS" == "PASS" && "$CI_SECURITY_STATUS" == "PASS" && "$CONTRACT_REVIEW_STATUS" == "PASS" && "$CRITICAL_DRIFTS_OPEN" == "0" ]]; then
  DECISION="promote"
fi

risk_notes_parts=()
next_actions_parts=()

if [[ -n "$FAILED_GATE" ]]; then
  risk_notes_parts+=("fail-fast disparado por ${FAILED_GATE}")
  next_actions_parts+=("corrigir ${FAILED_GATE} antes de rerodar a semana")
fi

if [[ "$CONTRACT_REVIEW_STATUS" != "PASS" ]]; then
  risk_notes_parts+=("contract review default=${CONTRACT_REVIEW_STATUS}")
  next_actions_parts+=("publicar contract review da semana via F8-02")
fi

if [[ "$CRITICAL_DRIFTS_OPEN" != "0" ]]; then
  risk_notes_parts+=("critical_drifts_open=${CRITICAL_DRIFTS_OPEN}")
  next_actions_parts+=("fechar ou aceitar formalmente os drifts criticos")
fi

if [[ ${#risk_notes_parts[@]} -eq 0 ]]; then
  risk_notes_parts+=("none")
fi

if [[ ${#next_actions_parts[@]} -eq 0 ]]; then
  next_actions_parts+=("manter cadencia semanal do trio de gates")
fi

RISK_NOTES="$(IFS='; '; echo "${risk_notes_parts[*]}")"
NEXT_ACTIONS="$(IFS='; '; echo "${next_actions_parts[*]}")"

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
