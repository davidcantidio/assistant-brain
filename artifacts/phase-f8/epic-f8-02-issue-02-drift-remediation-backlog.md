# EPIC-F8-02 ISSUE-F8-02-02 backlog de remediacao de drift com owner e prazo

- data/hora: 2026-03-01 08:56:33 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F8-02-02`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PM/PHASES/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPIC-F8-02-REVISAO-PERIODICA-DE-CONTRATOS-E-DRIFT.md`, `artifacts/phase-f8/contract-review/2026-W09.md`

## Red
- cenario A: registrar drift sem `owner`.
- resultado esperado: `hold`.
- cenario B: registrar drift sem `due_date`.
- resultado esperado: `hold`.
- cenario C: registrar drift com `status=risk_accepted` sem `risk_exception_ref`.
- resultado esperado: `hold`.

## Green
- acao:
  - endurecer o schema do backlog de drift para exigir `owner`, `due_date` e `risk_exception_ref` quando houver `risk_accepted`;
  - integrar `check_phase_f8_contract_review.sh` em `make ci-quality`;
  - completar o backlog real da `2026-W09` com owner e prazo para o drift critico aberto.
- comandos:
  1. `make phase-f8-contract-review`
  2. `make ci-quality`
- resultado:
  - `phase-f8-contract-review: PASS`
  - `quality-links: PASS`
  - `pm-issue-quality: PASS`
  - `phase-f8-weekly-governance: PASS`
  - `quality-check: PASS`

## Refactor
- manter o backlog canonico dentro do proprio artifact `contract-review`, sem arquivo paralelo para lista de drifts.
- manter `review_validity_status=PASS` quando o artifact estiver valido, mesmo que `operational_conformance_status=FAIL` e `critical_drifts_open > 0`.

## Evidencia objetiva
- validacoes novas do backlog:
  - `owner` obrigatorio por drift;
  - `due_date` obrigatorio por drift;
  - `risk_exception_ref` obrigatorio quando `status=risk_accepted`;
  - mock com drift critico aberto mantendo `decision=hold` mesmo com review valido.
- backlog real da semana `2026-W09`:
  - `drift_id=DRIFT-F8-2026-W09-01`
  - `owner=Sr. Geldmacher`
  - `due_date=2026-03-08`
  - `risk_exception_ref=null`
- gates impactados:
  - `make phase-f8-contract-review`
  - `make ci-quality`

## Alteracoes da issue
- `scripts/ci/phase_f8_contract_review.py`
- `scripts/ci/check_quality.sh`
- `scripts/ci/check_phase_f8_weekly_governance.sh`
- `artifacts/phase-f8/contract-review/2026-W09.md`
- `artifacts/phase-f8/epic-f8-02-issue-02-drift-remediation-backlog.md`
- `PRD/CHANGELOG.md`
