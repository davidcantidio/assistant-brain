#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

WEEK_ID="${WEEK_ID:-$(date +%G-W%V)}"
EXECUTED_AT="${EXECUTED_AT:-$(date '+%Y-%m-%dT%H:%M:%S%z')}"
SOURCE_OF_TRUTH="${SOURCE_OF_TRUTH:-PRD/PRD-MASTER.md}"
EVAL_GATES_CMD="${EVAL_GATES_CMD:-make eval-gates}"
CI_QUALITY_CMD="${CI_QUALITY_CMD:-make ci-quality}"
CI_SECURITY_CMD="${CI_SECURITY_CMD:-make ci-security}"
CONTRACT_REVIEW_DIR="${CONTRACT_REVIEW_DIR:-artifacts/phase-f8/contract-review}"
F7_SUMMARY_PATH="${F7_SUMMARY_PATH:-artifacts/phase-f7/validation-summary.md}"
EPICS_PATH_PRIMARY="PM/PHASES/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPICS.md"
EPICS_PATH_FALLBACK="PM/PHASES/feito/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPICS.md"
EPICS_PATH="${EPICS_PATH:-$EPICS_PATH_PRIMARY}"
if [[ ! -f "$EPICS_PATH" && -f "$EPICS_PATH_FALLBACK" ]]; then
  EPICS_PATH="$EPICS_PATH_FALLBACK"
fi

ARTIFACT_DIR="${ARTIFACT_DIR:-artifacts/phase-f8/weekly-governance}"
LOG_DIR="${ARTIFACT_DIR}/logs/${WEEK_ID}"
REPORT_PATH="${ARTIFACT_DIR}/${WEEK_ID}.md"
SUMMARY_ARTIFACT="${SUMMARY_ARTIFACT:-artifacts/phase-f8/validation-summary-${WEEK_ID}.md}"
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

if [[ -n "${CONTRACT_REVIEW_STATUS+x}" ]]; then
  CONTRACT_REVIEW_STATUS="${CONTRACT_REVIEW_STATUS}"
  CRITICAL_DRIFTS_OPEN="${CRITICAL_DRIFTS_OPEN:-0}"
else
  if REVIEW_ENV="$(WEEK_ID="$WEEK_ID" CONTRACT_REVIEW_DIR="$CONTRACT_REVIEW_DIR" bash scripts/ci/read_phase_f8_contract_review.sh 2>/dev/null)"; then
    eval "$REVIEW_ENV"
  else
    CONTRACT_REVIEW_STATUS="FAIL"
    CRITICAL_DRIFTS_OPEN="0"
  fi
fi

if [[ -n "${PRIOR_PHASE_DECISION+x}" && -n "${PHASE_TRANSITION_STATUS+x}" && -n "${BLOCKING_REASON+x}" ]]; then
  PRIOR_PHASE_DECISION="${PRIOR_PHASE_DECISION}"
  PHASE_TRANSITION_STATUS="${PHASE_TRANSITION_STATUS}"
  BLOCKING_REASON="${BLOCKING_REASON}"
else
  PHASE_ENV="$(
    python3 scripts/ci/phase_f8_release_governance.py read-prior-phase-status \
      --summary-path "$F7_SUMMARY_PATH"
  )"
  eval "$PHASE_ENV"
fi

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
if [[ "$EVAL_GATES_STATUS" == "PASS" && "$CI_QUALITY_STATUS" == "PASS" && "$CI_SECURITY_STATUS" == "PASS" && "$CONTRACT_REVIEW_STATUS" == "PASS" && "$CRITICAL_DRIFTS_OPEN" == "0" && "$PRIOR_PHASE_DECISION" == "promote" ]]; then
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

if [[ "$PHASE_TRANSITION_STATUS" != "ready" ]]; then
  risk_notes_parts+=("${BLOCKING_REASON}")
  next_actions_parts+=("recuar a ativacao da F8 e preservar hold ate F7 -> F8=promote")
fi

if [[ ${#risk_notes_parts[@]} -eq 0 ]]; then
  risk_notes_parts+=("none")
fi

if [[ ${#next_actions_parts[@]} -eq 0 ]]; then
  next_actions_parts+=("manter cadencia semanal do trio de gates")
fi

RISK_NOTES="$(IFS='; '; echo "${risk_notes_parts[*]}")"
NEXT_ACTIONS="$(IFS='; '; echo "${next_actions_parts[*]}")"

release_justification_parts=()
residual_risk_parts=()

if [[ "$DECISION" == "promote" ]]; then
  release_justification_parts+=("trio de gates em PASS")
  release_justification_parts+=("contract_review_status=PASS")
  release_justification_parts+=("critical_drifts_open=0")
  release_justification_parts+=("prior_phase_decision=promote")
  residual_risk_parts+=("none")
  ROLLBACK_PLAN="retornar ao ultimo artifact semanal valido com decision=hold e rerodar a governanca da F8 ao primeiro sinal de regressao."
else
  if [[ -n "$FAILED_GATE" ]]; then
    release_justification_parts+=("release bloqueado por ${FAILED_GATE}=FAIL")
    residual_risk_parts+=("falha de gate semanal em ${FAILED_GATE}")
  fi
  if [[ "$CONTRACT_REVIEW_STATUS" != "PASS" ]]; then
    release_justification_parts+=("release bloqueado por contract_review_status=${CONTRACT_REVIEW_STATUS}")
    residual_risk_parts+=("contract_review_status=${CONTRACT_REVIEW_STATUS}")
  fi
  if [[ "$CRITICAL_DRIFTS_OPEN" != "0" ]]; then
    release_justification_parts+=("release bloqueado por critical_drifts_open=${CRITICAL_DRIFTS_OPEN}")
    residual_risk_parts+=("critical_drifts_open=${CRITICAL_DRIFTS_OPEN}")
  fi
  if [[ "$PHASE_TRANSITION_STATUS" != "ready" ]]; then
    release_justification_parts+=("${BLOCKING_REASON}")
    residual_risk_parts+=("${BLOCKING_REASON}")
  fi
  if [[ ${#release_justification_parts[@]} -eq 0 ]]; then
    release_justification_parts+=("release mantido em hold por ausencia de pacote minimo de continuidade")
  fi
  if [[ ${#residual_risk_parts[@]} -eq 0 ]]; then
    residual_risk_parts+=("hold sem risco residual adicional")
  fi
  ROLLBACK_PLAN="manter a baseline vigente de F7/F8-02, sem promover F8, preservar hold e rerodar a semana apos remediacao."
fi

RELEASE_JUSTIFICATION="$(IFS='; '; echo "${release_justification_parts[*]}")"
RESIDUAL_RISK_SUMMARY="$(IFS='; '; echo "${residual_risk_parts[*]}")"
RELEASE_REVIEW_STATUS="PASS"

for value in "$RELEASE_JUSTIFICATION" "$RESIDUAL_RISK_SUMMARY" "$ROLLBACK_PLAN" "$NEXT_ACTIONS"; do
  if [[ -z "${value// }" ]]; then
    RELEASE_REVIEW_STATUS="FAIL"
    DECISION="hold"
  fi
done

python3 scripts/ci/phase_f8_release_governance.py render-weekly-report \
  --report-path "$REPORT_PATH" \
  --week-id "$WEEK_ID" \
  --executed-at "$EXECUTED_AT" \
  --source-of-truth "$SOURCE_OF_TRUTH" \
  --prior-phase-decision "$PRIOR_PHASE_DECISION" \
  --phase-transition-status "$PHASE_TRANSITION_STATUS" \
  --blocking-reason "$BLOCKING_REASON" \
  --eval-gates-status "$EVAL_GATES_STATUS" \
  --ci-quality-status "$CI_QUALITY_STATUS" \
  --ci-security-status "$CI_SECURITY_STATUS" \
  --contract-review-status "$CONTRACT_REVIEW_STATUS" \
  --critical-drifts-open "$CRITICAL_DRIFTS_OPEN" \
  --decision "$DECISION" \
  --release-review-status "$RELEASE_REVIEW_STATUS" \
  --release-justification "$RELEASE_JUSTIFICATION" \
  --residual-risk-summary "$RESIDUAL_RISK_SUMMARY" \
  --rollback-plan "$ROLLBACK_PLAN" \
  --summary-artifact "$SUMMARY_ARTIFACT" \
  --risk-notes "$RISK_NOTES" \
  --next-actions "$NEXT_ACTIONS" \
  --eval-log-path "$EVAL_LOG_PATH" \
  --quality-log-path "$QUALITY_LOG_PATH" \
  --security-log-path "$SECURITY_LOG_PATH"

python3 scripts/ci/phase_f8_release_governance.py render-validation-summary \
  --summary-path "$SUMMARY_ARTIFACT" \
  --weekly-report-path "$REPORT_PATH" \
  --epics-path "$EPICS_PATH"

echo "phase-f8-weekly-governance: REPORT=${REPORT_PATH}"
echo "phase-f8-weekly-governance: decision=${DECISION}"
exit 0
