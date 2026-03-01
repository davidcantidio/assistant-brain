# EPIC-F8-01 ISSUE-F8-01-01 ciclo semanal do trio de gates com registro timestamp

- data/hora: 2026-03-01 00:22:54 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F8-01-01`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/PHASE-USABILITY-GUIDE.md`, `PM/PHASES/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPIC-F8-01-CADENCIA-SEMANAL-DE-GATES.md`, `Makefile`

## Red
- cenario A: executar a governanca semanal sem rodar os tres comandos obrigatorios no mesmo ciclo.
- resultado esperado: `hold`.
- cenario B: manter evidencias dos gates dispersas, sem `week_id` e sem `executed_at` unificados.
- resultado esperado: `hold`.

## Green
- acao:
  - criar entrypoint `make phase-f8-weekly-governance`;
  - implementar runner semanal para executar `eval-gates`, `ci-quality` e `ci-security` em sequencia fixa;
  - capturar logs timestampados por semana e publicar artifact autoritativo da rodada.
- comandos:
  1. `make phase-f8-weekly-governance`
- resultado:
  - `eval-gates: PASS`
  - `quality-check: PASS`
  - `security-check: PASS`
  - relatorio semanal publicado em `artifacts/phase-f8/weekly-governance/2026-W09.md`

## Refactor
- manter `contract_review_status=FAIL` por default ate a execucao de `F8-02`, para evitar `promote` sem revisao contratual semanal.
- preservar logs brutos em `artifacts/phase-f8/weekly-governance/logs/2026-W09/` para reruns futuros da mesma semana.

## Evidencia objetiva
- `week_id`: `2026-W09`
- `executed_at`: `2026-03-01T00:22:54-0300`
- status da rodada:
  - `eval_gates_status=PASS`
  - `ci_quality_status=PASS`
  - `ci_security_status=PASS`
  - `contract_review_status=FAIL`
  - `critical_drifts_open=0`
  - `decision=hold`
- arquivos publicados:
  - `artifacts/phase-f8/weekly-governance/2026-W09.md`
  - `artifacts/phase-f8/weekly-governance/logs/2026-W09/20260301T002254-eval-gates.log`
  - `artifacts/phase-f8/weekly-governance/logs/2026-W09/20260301T002254-ci-quality.log`
  - `artifacts/phase-f8/weekly-governance/logs/2026-W09/20260301T002254-ci-security.log`

## Alteracoes da issue
- `Makefile`
- `scripts/ci/run_phase_f8_weekly_governance.sh`
- `artifacts/phase-f8/weekly-governance/2026-W09.md`
- `artifacts/phase-f8/weekly-governance/logs/2026-W09/20260301T002254-eval-gates.log`
- `artifacts/phase-f8/weekly-governance/logs/2026-W09/20260301T002254-ci-quality.log`
- `artifacts/phase-f8/weekly-governance/logs/2026-W09/20260301T002254-ci-security.log`
- `artifacts/phase-f8/epic-f8-01-issue-01-weekly-gates-timestamp.md`
- `PRD/CHANGELOG.md`
