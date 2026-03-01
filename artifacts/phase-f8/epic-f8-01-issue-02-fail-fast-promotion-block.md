# EPIC-F8-01 ISSUE-F8-01-02 fail-fast e bloqueio formal de promocao

- data/hora: 2026-03-01 00:25:54 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F8-01-02`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/PHASE-USABILITY-GUIDE.md`, `PM/PHASES/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPIC-F8-01-CADENCIA-SEMANAL-DE-GATES.md`, `scripts/ci/run_phase_f8_weekly_governance.sh`

## Red
- cenario A: executar os gates seguintes mesmo quando um gate anterior falhar.
- resultado esperado: `hold`.
- cenario B: considerar `promote` apenas porque o trio tecnico passou, sem olhar `contract_review_status` e `critical_drifts_open`.
- resultado esperado: `hold`.

## Green
- acao:
  - endurecer o runner semanal com fail-fast na ordem `eval-gates -> ci-quality -> ci-security`;
  - marcar gates nao executados como `FAIL` com log explicando o skip por fail-fast;
  - recalcular `decision`, `risk_notes` e `next_actions` com base na formula fechada de promocao.
- comandos:
  1. `make phase-f8-weekly-governance`
- resultado:
  - `eval-gates: PASS`
  - `quality-check: PASS`
  - `security-check: PASS`
  - `contract_review_status: FAIL`
  - `decision: hold`

## Refactor
- manter `exit 0` do runner para preservar a geracao do artifact semanal mesmo em rodadas `hold`.
- preservar logs anteriores da mesma semana e atualizar apenas o markdown autoritativo de `2026-W09`.

## Evidencia objetiva
- regra final do runner:
  - falha em `eval-gates` impede execucao de `ci-quality` e `ci-security`;
  - falha em `ci-quality` impede execucao de `ci-security`;
  - qualquer combinacao diferente de `PASS/PASS/PASS + contract_review_status=PASS + critical_drifts_open=0` resulta em `hold`.
- rerun autoritativo da semana:
  - `artifacts/phase-f8/weekly-governance/2026-W09.md`
  - `executed_at=2026-03-01T00:25:54-0300`
  - `risk_notes=contract review default=FAIL`
  - `next_actions=publicar contract review da semana via F8-02`
- novos logs timestampados:
  - `artifacts/phase-f8/weekly-governance/logs/2026-W09/20260301T002554-eval-gates.log`
  - `artifacts/phase-f8/weekly-governance/logs/2026-W09/20260301T002554-ci-quality.log`
  - `artifacts/phase-f8/weekly-governance/logs/2026-W09/20260301T002554-ci-security.log`

## Alteracoes da issue
- `scripts/ci/run_phase_f8_weekly_governance.sh`
- `artifacts/phase-f8/weekly-governance/2026-W09.md`
- `artifacts/phase-f8/weekly-governance/logs/2026-W09/20260301T002554-eval-gates.log`
- `artifacts/phase-f8/weekly-governance/logs/2026-W09/20260301T002554-ci-quality.log`
- `artifacts/phase-f8/weekly-governance/logs/2026-W09/20260301T002554-ci-security.log`
- `artifacts/phase-f8/epic-f8-01-issue-02-fail-fast-promotion-block.md`
- `PRD/CHANGELOG.md`
