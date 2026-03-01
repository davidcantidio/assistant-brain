# EPIC-F8-03 ISSUE-F8-03-02 risco residual rollback e continuidade semanal

- data/hora: 2026-03-01 10:01:40 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F8-03-02`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PM/DECISION-PROTOCOL.md`, `EVALS/SYSTEM-HEALTH-THRESHOLDS.md`, `PM/PHASES/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPIC-F8-03-GOVERNANCA-DE-EVOLUCAO-E-RELEASE.md`

## Red
- cenario A: registrar a rodada semanal sem `release_justification`, `residual_risk_summary` ou `rollback_plan`.
- resultado esperado: `hold`.
- cenario B: manter `decision=promote` mesmo com pacote de continuidade incompleto.
- resultado esperado: `hold`.

## Green
- acao:
  - ampliar o relatorio semanal com `release_review_status`, `release_justification`, `residual_risk_summary` e `rollback_plan`;
  - fechar rollback canonico de `hold` para preservar a baseline vigente de `F7/F8-02`;
  - fechar rollback canonico de `promote` para retorno ao ultimo artifact semanal valido;
  - validar os novos campos no checker da `F8`.
- comandos:
  1. `make phase-f8-weekly-governance`
  2. `make ci-quality`
- resultado:
  - `phase-f8-weekly-governance: decision=hold`
  - `phase-f8-weekly-governance: PASS`
  - `quality-check: PASS`

## Refactor
- o pacote de continuidade vira contrato obrigatorio do artifact semanal, sem alterar o target publico `make phase-f8-weekly-governance`.
- o `hold` da semana atual deixa de ser apenas decisao de bloqueio e passa a registrar trilha de risco residual e rollback explicitos.

## Evidencia objetiva
- o artifact semanal passa a registrar:
  - `release_review_status`
  - `release_justification`
  - `residual_risk_summary`
  - `rollback_plan`
- o checker passa a falhar se qualquer um desses campos estiver ausente, vazio ou inconsistente com a decisao final.
- a rodada real de `2026-W09` deve permanecer `hold` com bloqueio explicito por:
  - `critical_drifts_open=1`
  - `prior_phase_decision=hold`
- logs finais da rodada valida:
  - `artifacts/phase-f8/weekly-governance/logs/2026-W09/20260301T100531-eval-gates.log`
  - `artifacts/phase-f8/weekly-governance/logs/2026-W09/20260301T100531-ci-quality.log`
  - `artifacts/phase-f8/weekly-governance/logs/2026-W09/20260301T100531-ci-security.log`

## Alteracoes da issue
- `scripts/ci/phase_f8_release_governance.py`
- `scripts/ci/run_phase_f8_weekly_governance.sh`
- `scripts/ci/check_phase_f8_weekly_governance.sh`
- `artifacts/phase-f8/weekly-governance/2026-W09.md`
- `artifacts/phase-f8/epic-f8-03-issue-02-residual-risk-rollback.md`
- `PM/PHASES/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPIC-F8-03-GOVERNANCA-DE-EVOLUCAO-E-RELEASE.md`
- `PRD/CHANGELOG.md`
