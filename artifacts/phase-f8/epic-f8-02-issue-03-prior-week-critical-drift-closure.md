# EPIC-F8-02 ISSUE-F8-02-03 fechamento de drifts criticos herdados antes de promocao

- data/hora: 2026-03-01 08:58:01 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F8-02-03`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/PHASE-USABILITY-GUIDE.md`, `PM/PHASES/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPIC-F8-02-REVISAO-PERIODICA-DE-CONTRATOS-E-DRIFT.md`, `artifacts/phase-f8/contract-review/2026-W09.md`

## Red
- cenario A: permitir promocao com drift critico herdado sem classificacao explicita no artifact atual.
- resultado esperado: `hold`.
- cenario B: omitir drift critico herdado do bloco `Previous Week Closure`.
- resultado esperado: `hold`.

## Green
- acao:
  - calcular `previous_week_id` por ISO week no checker de `contract-review`;
  - aceitar `previous_week_id=none` quando nao houver artifact da semana anterior;
  - exigir classificacao `closed|risk_accepted|open` para todo drift critico herdado quando a semana anterior existir;
  - validar cenarios mockados de carry-over `closed`, `risk_accepted`, `open` e omissao.
- comandos:
  1. `make phase-f8-contract-review`
  2. `make phase-f8-weekly-governance`
  3. `make ci-quality`
- resultado:
  - `phase-f8-contract-review: PASS`
  - `phase-f8-weekly-governance: decision=hold`
  - `quality-check: PASS`

## Refactor
- manter o artifact valido mesmo quando houver carry-over `open`; o bloqueio continua ocorrendo pelo `critical_drifts_open`.
- manter o primeiro ciclo (`2026-W09`) com `previous_week_id=none` e `carried_over_drifts=[]`.

## Evidencia objetiva
- regra de carry-over implementada:
  - semana anterior ausente => `previous_week_id=none` aceito;
  - semana anterior presente => todo drift critico `open` herdado precisa aparecer em `carried_over_drifts`;
  - `resolution=open` exige o drift continuar `critical/open` no backlog atual;
  - `resolution=closed` exige evidencia de fechamento;
  - `resolution=risk_accepted` exige `risk_exception_ref`.
- rodada final da semana `2026-W09`:
  - `review_validity_status=PASS`
  - `operational_conformance_status=FAIL`
  - `failed_domains=trading`
  - `critical_drifts_open=1`
  - `decision=hold`
- logs finais da rodada:
  - `artifacts/phase-f8/weekly-governance/logs/2026-W09/20260301T085801-eval-gates.log`
  - `artifacts/phase-f8/weekly-governance/logs/2026-W09/20260301T085801-ci-quality.log`
  - `artifacts/phase-f8/weekly-governance/logs/2026-W09/20260301T085801-ci-security.log`
- fechamento de auditoria:
  - esta issue so fecha operacionalmente apos a rodada real `2026-W10` com `previous_week_id=2026-W09` e classificacao de carry-over publicada.

## Alteracoes da issue
- `scripts/ci/phase_f8_contract_review.py`
- `scripts/ci/check_phase_f8_weekly_governance.sh`
- `artifacts/phase-f8/contract-review/2026-W09.md`
- `artifacts/phase-f8/weekly-governance/2026-W09.md`
- `artifacts/phase-f8/epic-f8-02-issue-03-prior-week-critical-drift-closure.md`
- `artifacts/phase-f8/epic-f8-02-contract-review-drift.md`
- `PM/PHASES/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPICS.md`
- `PM/PHASES/feito/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPIC-F8-02-REVISAO-PERIODICA-DE-CONTRATOS-E-DRIFT.md`
- `PRD/CHANGELOG.md`
