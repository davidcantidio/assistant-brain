# EPIC-F8-03 ISSUE-F8-03-01 criterios de decisao semanal e recuo formal da F8

- data/hora: 2026-03-01 09:59:07 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F8-03-01`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md`, `PRD/PHASE-USABILITY-GUIDE.md`, `PM/DECISION-PROTOCOL.md`, `EVALS/SYSTEM-HEALTH-THRESHOLDS.md`, `PM/PHASES/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPIC-F8-03-GOVERNANCA-DE-EVOLUCAO-E-RELEASE.md`

## Red
- cenario A: promover a rodada semanal da `F8` olhando apenas trio de gates + drifts, sem considerar a decisao `F7 -> F8`.
- resultado esperado: `hold`.
- cenario B: manter a `F8` ativa no relatorio semanal mesmo com `artifacts/phase-f7/validation-summary.md` registrando `hold`.
- resultado esperado: `hold`.

## Green
- acao:
  - adicionar helper `scripts/ci/phase_f8_release_governance.py` para ler a decisao da fase anterior e renderizar o relatorio semanal;
  - ampliar o runner da `F8` com `source_of_truth`, `prior_phase_decision`, `phase_transition_status` e `blocking_reason`;
  - endurecer a formula de `promote|hold` para exigir tambem `prior_phase_decision=promote`;
  - validar cenario mockado com `prior_phase_decision=hold` no checker semanal.
- comandos:
  1. `make phase-f8-weekly-governance`
  2. `make ci-quality`
- resultado:
  - `phase-f8-weekly-governance: decision=hold`
  - `phase-f8-weekly-governance: PASS`
  - `quality-check: PASS`

## Refactor
- o bloqueio da transicao `F7 -> F8` fica expresso no artifact semanal, sem criar novo enum de status na tabela de epics.
- o recuo da ativacao prematura da `F8` fica tratado como restauracao de coerencia documental, nao como `risk_exception`.

## Evidencia objetiva
- o artifact semanal passa a registrar:
  - `source_of_truth`
  - `prior_phase_decision`
  - `phase_transition_status`
  - `blocking_reason`
- a regra semanal passa a exigir `prior_phase_decision=promote` para qualquer `decision=promote`.
- o caso real de `2026-W09` deve permanecer `hold` por:
  - `critical_drifts_open=1`
  - `F7 -> F8 = hold`
- logs finais da rodada valida:
  - `artifacts/phase-f8/weekly-governance/logs/2026-W09/20260301T100140-eval-gates.log`
  - `artifacts/phase-f8/weekly-governance/logs/2026-W09/20260301T100140-ci-quality.log`
  - `artifacts/phase-f8/weekly-governance/logs/2026-W09/20260301T100140-ci-security.log`

## Alteracoes da issue
- `scripts/ci/phase_f8_release_governance.py`
- `scripts/ci/run_phase_f8_weekly_governance.sh`
- `scripts/ci/check_phase_f8_weekly_governance.sh`
- `artifacts/phase-f8/weekly-governance/2026-W09.md`
- `artifacts/phase-f8/epic-f8-03-issue-01-weekly-decision-criteria.md`
- `PM/PHASES/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPICS.md`
- `PM/PHASES/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPIC-F8-03-GOVERNANCA-DE-EVOLUCAO-E-RELEASE.md`
- `PRD/CHANGELOG.md`
