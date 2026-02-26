# EPIC-F5-02 ISSUE-F5-02-05 Runbook de degradacao com posicao aberta

- data/hora: 2026-02-26 18:48:22 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F5-02-05`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md` (`B1-08`)

## Red
- cenario A: degradacao com posicao aberta sem regra explicita de `TRADING_BLOCKED`.
- resultado esperado: `FAIL` no `make eval-trading`.
- cenario B: runbook sem `position_snapshot`/`open_orders_snapshot` e sem criterio de reconciliacao de retorno seguro.
- resultado esperado: `FAIL` no `make eval-trading`.

## Green
- acao:
  - endurecer `scripts/ci/eval_trading.sh` para validar requisitos de runbook em:
    - `ARC/ARC-DEGRADED-MODE.md`
    - `INCIDENTS/DEGRADED-MODE-PROCEDURE.md`
  - exigir no gate: `TRADING_BLOCKED`, snapshots, reconciliacao e criterio de saida sem exposicao nao gerenciada.
- comando: `make eval-trading`.
- resultado: `eval-trading: PASS`.

## Refactor
- comandos:
  1. `make eval-integrations`
  2. `make ci-quality`
- resultados:
  - `eval-integrations: PASS`
  - `quality-check: PASS`

## Alteracoes da issue
- `scripts/ci/eval_trading.sh`
- `PRD/CHANGELOG.md`
- `PM/PHASES/F5-INTEGRACOES-EXTERNAS-GOVERNADAS/EPIC-F5-02-TRADING-HARDENING-E-PRONTIDAO-LIVE.md`
- `PM/PHASES/F5-INTEGRACOES-EXTERNAS-GOVERNADAS/EPICS.md`
- `artifacts/phase-f5/epic-f5-02-issue-05-degraded-open-position-runbook.md`
- `artifacts/phase-f5/epic-f5-02-trading-hardening.md`
