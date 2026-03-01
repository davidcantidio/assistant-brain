# EPIC-F8-01 ISSUE-F8-01-03 consolidacao do relatorio semanal com falhas e acoes corretivas

- data/hora: 2026-03-01 00:29:16 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F8-01-03`
- fonte de verdade: `PRD/PHASE-USABILITY-GUIDE.md`, `PM/PHASES/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPIC-F8-01-CADENCIA-SEMANAL-DE-GATES.md`, `scripts/ci/check_quality.sh`, `scripts/ci/check_phase_f8_weekly_governance.sh`

## Red
- cenario A: relatorio semanal sem validacao automatica de campos obrigatorios, formula de decisao e logs referenciados.
- resultado esperado: `hold`.
- cenario B: manter o epic ativo sem consolidado final, mesmo com o relatorio semanal e o runner ja padronizados.
- resultado esperado: `hold`.

## Green
- acao:
  - adicionar validador `scripts/ci/check_phase_f8_weekly_governance.sh` em `make ci-quality`;
  - validar cenarios mockados de `promote`, `eval-gates FAIL`, `ci-quality FAIL` e `contract_review_status` default `FAIL`;
  - consolidar summary do epic e mover o documento `EPIC-F8-01` para `feito`.
- comandos:
  1. `make ci-quality`
- resultado:
  - `quality-links: PASS`
  - `pm-issue-quality: PASS`
  - `phase-f8-weekly-governance: PASS`
  - `quality-check: PASS`

## Refactor
- manter o validador semanal isolado do artifact real via `ARTIFACT_DIR` temporario, evitando poluicao do repositorio com cenarios mockados.
- fechar o epic em `done`, mas preservar a decisao semanal em `hold` ate a execucao de `F8-02`.

## Evidencia objetiva
- validacoes cobertas no gate:
  - presenca e ordem dos campos obrigatorios do relatorio semanal;
  - coerencia da formula `promote|hold`;
  - existencia dos logs referenciados;
  - cenario `promote` mockado com trio `PASS` + `contract_review_status=PASS` + `critical_drifts_open=0`;
  - cenarios fail-fast mockados para `eval-gates` e `ci-quality`;
  - cenario fail-closed de `contract_review_status` ausente.
- artifacts finais publicados:
  - `artifacts/phase-f8/epic-f8-01-weekly-governance.md`
  - `artifacts/phase-f8/epic-f8-01-issue-03-weekly-report-actions.md`

## Alteracoes da issue
- `scripts/ci/run_phase_f8_weekly_governance.sh`
- `scripts/ci/check_phase_f8_weekly_governance.sh`
- `scripts/ci/check_quality.sh`
- `artifacts/phase-f8/epic-f8-01-weekly-governance.md`
- `artifacts/phase-f8/epic-f8-01-issue-03-weekly-report-actions.md`
- `PM/PHASES/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPICS.md`
- `PM/PHASES/feito/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPIC-F8-01-CADENCIA-SEMANAL-DE-GATES.md`
- `PRD/CHANGELOG.md`
