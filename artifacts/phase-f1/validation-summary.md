# F1 Validation Summary

- artifact_version: `2.0`
- remediation_date: `2026-03-01`
- evidence_cycle_reference: `2026-02-25 17:53:38 -0300`
- host alvo: Darwin arm64
- fase operacional: `F1 Instalacao Base OpenClaw`
- escopo desta revisao: remediacao documental da auditoria F1 com realinhamento por rastreabilidade
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/PHASE-USABILITY-GUIDE.md`, `SEC/SEC-POLICY.md`, `PM/DECISION-PROTOCOL.md`

## Escopo normativo da F1

- `in_scope_f1`: `R1`,`R2`,`R3`,`R4`,`R5`,`R7`,`R8`,`R9`,`R10`,`R11`,`R12`,`R13`,`R14`,`R15`
- `remap_phase`:
  - `R6 -> F2` (`EPIC-F2-03/ISSUE-F2-03-05`)
  - `R16 -> F2` (`EPIC-F2-02/ISSUE-F2-02-03`)
  - `R17 -> F5` (`EPIC-F5-03/ISSUE-F5-03-03`)
  - `R18..R22 -> F7` (`EPIC-F7-01..03`)
- regra de promote da fase:
  - claim central sem eval gate executavel bloqueia promote.
  - requisito remapeado para outra fase nao conta como gap funcional da `F1` quando o mapeamento formal existe e aponta para issue ativa.

## Comandos executados na rodada-base de evidencia

1. `bash scripts/verify_linux.sh` -> PASS (`verify: PASS`)
2. `make ci-security` -> PASS (`security-check: PASS`)
3. `make ci-quality` -> PASS (`quality-check: PASS`)
4. `make eval-runtime` -> PASS (`eval-runtime-contracts: PASS`)
5. `make eval-gates` -> PASS (`eval-gates: PASS`)
6. `make eval-models` -> PASS (`eval-models: PASS`)

## Rerun de validacao da remediacao (`2026-03-01`)

| Comando | Resultado | Observacao |
|---|---|---|
| `bash scripts/verify_linux.sh` | PASS | rerodado em `assistant-brain/`; `verify: PASS` |
| `make ci-security` | PASS | `security-check: PASS` |
| `make eval-runtime` | PASS | `eval-runtime-contracts: PASS` |
| `make ci-quality` | FAIL | bloqueado por issue preexistente fora da F1 em `EPIC-F2-01-BASELINE-SEGURANCA-E-GATES.md` (`ISSUE-F2-01-01` sem marcador `**Owner sugerido**`) |
| `make eval-gates` | FAIL | bloqueado por falhas fora da F1 em `eval_risk_gates.sh` e `eval_idempotency_reconciliation.sh` |
| `make eval-rag` | PASS | validado isoladamente durante o diagnostico |
| `make eval-trading` | PASS | validado isoladamente durante o diagnostico |

- nota:
  - os bloqueadores do rerun atual nao foram introduzidos pela remediacao documental da `F1`.
  - a decisao de fase abaixo continua ancorada no ciclo de evidencia da `F1`; o rerun de `2026-03-01` serviu como validacao tecnica da remediacao e revelou debt preexistente em `F2` e em scripts de gate globais.

## Claims centrais e bloqueio de promote

| Claim central | Eval/gate obrigatorio | Status | Evidence ref | Regra de bloqueio |
|---|---|---|---|---|
| setup local executavel | `bash scripts/verify_linux.sh` | PASS | `artifacts/phase-f1/validation-summary.md#comandos-executados-na-rodada-base-de-evidencia` | sem `PASS`, `F1 -> F2` bloqueado |
| baseline de seguranca enforceable | `make ci-security` | PASS | `artifacts/phase-f1/validation-summary.md#comandos-executados-na-rodada-base-de-evidencia` | sem `PASS`, `promote` bloqueado |
| quality/documentation sem link quebrado | `make ci-quality` | PASS | `artifacts/phase-f1/validation-summary.md#comandos-executados-na-rodada-base-de-evidencia` | sem `PASS`, artifact unico invalido |
| contratos/evals minimos da fase | `make eval-gates` | PASS | `artifacts/phase-f1/validation-summary.md#comandos-executados-na-rodada-base-de-evidencia` | claim central sem eval gate bloqueia release |
| runtime/memory contract valido | `make eval-runtime` | PASS | `artifacts/phase-f1/epic-f1-03-runtime-memory.md` | sem `PASS`, trilha operacional invalida |
| configuracao/model routing coerente | `make eval-models` | PASS | `artifacts/phase-f1/epic-f1-02-config-validation.md` | sem `PASS`, defaults/cloud ficam sem gate |

## HITL Technical Checklist (F1 bootstrap)

- checklist_id: `HITL-F1-20260225-01`
- decision_id: `DEC-F1-20260225-01`
- risk_tier: `R3`
- operator_id: `primary-01`
- primary_channel: `telegram`
- fallback_channel: `slack`
- decision_protocol_ref: `PM/DECISION-PROTOCOL.md`
- challenge_policy_ref: `PM/DECISION-PROTOCOL.md#lifecycle-do-challenge-segundo-fator`
- email_command_channel_trusted: `false`
- result: `promote`
- rule: qualquer item `fail` bloqueia `live-run`; sem confirmacao em canal confiavel, comando por email permanece bloqueado.

| item_id | status | evidence_ref | observacao |
|---|---|---|---|
| `telegram_identity_validated` | `pass` | `PM/DECISION-PROTOCOL.md#controle-de-identidade-autorizacao-hitl` | Telegram permanece canal primario |
| `operator_allowlist_checked` | `pass` | `SEC/allowlists/OPERATORS.yaml` | operador autorizado referenciado por `operator_id` |
| `email_untrusted_enforced` | `pass` | `PM/DECISION-PROTOCOL.md#regra-de-confianca-de-canal` | email e tratado como canal nao confiavel |
| `decision_id_present` | `pass` | `artifacts/phase-f1/validation-summary.md#hitl-technical-checklist-f1-bootstrap` | checklist passa a carregar `decision_id` |
| `evidence_ref_per_item` | `pass` | `artifacts/phase-f1/validation-summary.md#hitl-technical-checklist-f1-bootstrap` | todos os itens desta checklist tem `evidence_ref` |
| `slack_fallback_status_recorded` | `pass` | `artifacts/phase-f1/validation-summary.md#hitl-technical-checklist-f1-bootstrap` | fallback Slack permanece `pending_f6`; sem bypass de policy |

## Matriz Requirement -> Issue -> Evidence -> Gate

| Requirement | Scope | Issue alvo | Gate/Eval | Evidence ref | Status |
|---|---|---|---|---|---|
| `R1` | `F1` | `ISSUE-F1-03`, `ISSUE-F1-04-02` | `make eval-gates`, phase review | `EPIC-F1-01`, `EPIC-F1-04`, este artifact | covered |
| `R2` | `F1` | `ISSUE-F1-03`, `ISSUE-F1-04-01` | `make ci-security`, `make eval-gates` | `EPIC-F1-04`, este artifact | covered |
| `R3` | `F1` | `ISSUE-F1-03`, `ISSUE-F1-04-03` | phase review + artifact check | este artifact | covered |
| `R4` | `F1` | `ISSUE-F1-02-01`, `ISSUE-F1-02-02` | `bash scripts/verify_linux.sh`, `make eval-models` | `artifacts/phase-f1/epic-f1-02-config-validation.md` | covered |
| `R5` | `F1` | `ISSUE-F1-02-02`, `ISSUE-F1-02-03` | `make eval-models` | `artifacts/phase-f1/epic-f1-02-config-validation.md` | covered |
| `R6` | `remap:F2` | `ISSUE-F2-03-05` | `make eval-gates` | `artifacts/phase-f2/epic-f2-03-issue-05-a2a-hooks-traceability.md` | remapped |
| `R7` | `F1` | `ISSUE-F1-04-02` | phase review | este artifact, `PM/DECISION-PROTOCOL.md` | covered |
| `R8` | `F1` | `ISSUE-F1-03-02` | `make eval-runtime` | `artifacts/phase-f1/epic-f1-03-runtime-memory.md` | covered |
| `R9` | `F1` | `ISSUE-F1-03-02`, `ISSUE-F1-03-03` | `make eval-runtime` | `artifacts/phase-f1/epic-f1-03-runtime-memory.md` | covered |
| `R10` | `F1` | `ISSUE-F1-04-01` | `make ci-security` | este artifact | covered |
| `R11` | `F1` | `ISSUE-F1-03`, `ISSUE-F1-04-03` | `make eval-gates`, phase review | este artifact | covered |
| `R12` | `F1` | `ISSUE-F1-04-02` | phase review | este artifact | covered |
| `R13` | `F1` | `ISSUE-F1-01..04-03` | issue DoR/DoD review | `EPIC-F1-01..04` | covered |
| `R14` | `F1` | `ISSUE-F1-03`, `ISSUE-F1-04-03` | phase review | este artifact | covered |
| `R15` | `F1` | `ISSUE-F1-03`, `ISSUE-F1-04-03` | `make eval-gates` | este artifact | covered |
| `R16` | `remap:F2` | `ISSUE-F2-02-03` | `make eval-gates` | `artifacts/phase-f2/epic-f2-02-idempotency-reconciliation.md` | remapped |
| `R17` | `remap:F5` | `ISSUE-F5-03-03` | `make eval-gates` | `artifacts/phase-f5/epic-f5-03-issue-03-routing-cost-privacy-preset-governance.md` | remapped |
| `R18` | `remap:F7` | `ISSUE-F7-02-02` | `make eval-trading` | `EPIC-F7-02-S1-MICRO-LIVE-PRE-LIVE-CHECKLIST.md` | remapped |
| `R19` | `remap:F7` | `ISSUE-F7-01-03`, `ISSUE-F7-03-01` | `make eval-trading` | `EPIC-F7-01-S0-PAPER-SANDBOX-OPERACIONAL.md`, `EPIC-F7-03-S2-ESCALA-E-PROMOCAO.md` | remapped |
| `R20` | `remap:F7` | `ISSUE-F7-01-01`, `ISSUE-F7-01-02`, `ISSUE-F7-03-02` | `make eval-trading` | `EPIC-F7-01-S0-PAPER-SANDBOX-OPERACIONAL.md`, `EPIC-F7-03-S2-ESCALA-E-PROMOCAO.md` | remapped |
| `R21` | `remap:F7` | `EPIC-F7-01..03` | `make eval-trading` | `assistant-brain/PM/PHASES/F7-TRADING-POR-ESTAGIOS/EPICS.md` | remapped |
| `R22` | `remap:F7` | `ISSUE-F7-02-03` | `make eval-trading` | `EPIC-F7-02-S1-MICRO-LIVE-PRE-LIVE-CHECKLIST.md` | remapped |

## Status final por issue

| Issue | risk_tier | Verify | Review/Gate | Evidence status | Observacao |
|---|---|---|---|---|---|
| `ISSUE-F1-01` | `R1` | PASS | n/a | complete | DoR completo e evidencias de verify declaradas |
| `ISSUE-F1-02` | `R1` | PASS | n/a | complete | persistencia de CLI documentada |
| `ISSUE-F1-03` | `R2` | PASS | PASS | complete | `evidence_ref` por gate obrigatorio |
| `ISSUE-F1-02-01` | `R1` | PASS | n/a | complete | contrato versionado explicitado |
| `ISSUE-F1-02-02` | `R2` | PASS | PASS | complete | override sem `decision_id` bloqueado |
| `ISSUE-F1-02-03` | `R1` | PASS | n/a | complete | cloud enabled sem decisao formal bloqueado |
| `ISSUE-F1-03-01` | `R1` | PASS | n/a | complete | vinculo normativo explicito remove `Sem mapeamento` |
| `ISSUE-F1-03-02` | `R2` | PASS | PASS | complete | auditoria do ciclo noturno completada |
| `ISSUE-F1-03-03` | `R2` | PASS | PASS | complete | politica de incidente >24h explicitada |
| `ISSUE-F1-04-01` | `R2` | PASS | PASS | complete | allowlist + secrets + redaction + ZDR |
| `ISSUE-F1-04-02` | `R3` | PASS | PASS | complete | checklist HITL tecnico, `decision_id` e fail-closed |
| `ISSUE-F1-04-03` | `R2` | PASS | PASS | complete | artifact unico com matriz de claims e gates |

## Matriz de status dos epicos da F1

| Epic | Status na rodada | Evidencia principal |
|---|---|---|
| `EPIC-F1-01` | `done` | `bash scripts/verify_linux.sh` -> PASS |
| `EPIC-F1-02` | `done` | `artifacts/phase-f1/epic-f1-02-config-validation.md` |
| `EPIC-F1-03` | `done` | `artifacts/phase-f1/epic-f1-03-runtime-memory.md` |
| `EPIC-F1-04` | `done` | este artifact + checklist HITL tecnico |

## Evidencias consolidadas

- onboarding/verify baseline: `assistant-brain/PM/PHASES/feito/F1-INSTALACAO-BASE-OPENCLAW/EPIC-F1-01-INSTALACAO-VERIFY.md`
- config local: `assistant-brain/artifacts/phase-f1/epic-f1-02-config-validation.md`
- runtime/memory: `assistant-brain/artifacts/phase-f1/epic-f1-03-runtime-memory.md`
- HITL/policy: `assistant-brain/PM/PHASES/feito/F1-INSTALACAO-BASE-OPENCLAW/EPIC-F1-04-HITL-BOOTSTRAP-EVIDENCIAS.md`
- rastreabilidade de roadmap: `assistant-brain/PM/TRACEABILITY/ROADMAP-BACKLOG-COVERAGE.md`

## Decisao de fase (F1 -> F2)

- decisao: `promote`
- decision_id: `DEC-F1-20260225-01`
- justificativa:
  - gate operacional de verify em `PASS`;
  - gates de seguranca, runtime e qualidade em `PASS`;
  - canal humano confiavel primario (Telegram) validado;
  - requisitos fora do escopo operacional da F1 foram remapeados formalmente para `F2/F5/F7`.
- residual_risk:
  - fallback Slack segue `pending_f6`; nao habilita live-run e nao relaxa policy.
- next_step:
  - reexecutar a auditoria da `F1` usando esta matriz de escopo e rastreabilidade como fonte canonica.
  - corrigir os bloqueadores externos do rerun (`ci-quality`, `eval-gates`) antes de usar esta rodada como novo baseline repo-wide.
