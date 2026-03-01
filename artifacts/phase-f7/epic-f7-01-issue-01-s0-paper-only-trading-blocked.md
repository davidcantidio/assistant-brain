# EPIC-F7-01 ISSUE-F7-01-01 regra S0 paper-only com TRADING_BLOCKED para tentativa live

- data/hora: 2026-02-28 23:15:31 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F7-01-01`
- fonte de verdade: `VERTICALS/TRADING/TRADING-PRD.md`, `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`, `scripts/ci/eval_trading.sh`

## Red
- cenario A: considerar `S0` sem bloqueio explicito para tentativa de ordem live.
- resultado esperado: `FAIL` no `make eval-trading`.
- cenario B: permitir ambiguidade de bloqueio de tentativa live em `S0`.
- resultado esperado: `FAIL` no `make eval-trading`.

## Green
- acao:
  - reforcar em docs normativos de trading que tentativa de ordem live em `S0` MUST manter `TRADING_BLOCKED`;
  - endurecer `scripts/ci/eval_trading.sh` para exigir essa regra nos documentos de PRD e enablement.
- comandos:
  1. `make eval-trading`
  2. `make ci-quality`
- resultado:
  - `eval-trading: PASS`
  - `quality-check: PASS`

## Refactor
- manter regra de bloqueio de tentativa live em `S0` com linguagem simetrica entre PRD e criterios de enablement.
- manter validacao executavel centralizada no harness `eval-trading`.

## Alteracoes da issue
- `VERTICALS/TRADING/TRADING-PRD.md`
- `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`
- `scripts/ci/eval_trading.sh`
- `PRD/CHANGELOG.md`
- `artifacts/phase-f7/epic-f7-01-issue-01-s0-paper-only-trading-blocked.md`
