# EPIC-F7-01 ISSUE-F7-01-02 aprovacao humana explicita por ordem de entrada no S0

- data/hora: 2026-02-28 23:16:52 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F7-01-02`
- fonte de verdade: `VERTICALS/TRADING/TRADING-PRD.md`, `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`, `PM/DECISION-PROTOCOL.md`, `scripts/ci/eval_trading.sh`

## Red
- cenario A: considerar entrada em `S0` sem aprovacao humana explicita por ordem.
- resultado esperado: `FAIL` no `make eval-trading`.
- cenario B: manter ambiguidade entre PRD, enablement e protocolo de decisao sobre aprovacao por ordem em `S0`.
- resultado esperado: `FAIL` no `make eval-trading`.

## Green
- acao:
  - reforcar regra normativa em `S0` para cada ordem de entrada com aprovacao humana explicita e auditavel;
  - alinhar PRD, criterios de enablement e Decision Protocol com a mesma linguagem;
  - endurecer `scripts/ci/eval_trading.sh` para exigir a regra nos tres documentos.
- comandos:
  1. `make eval-trading`
  2. `make ci-security`
  3. `make ci-quality`
- resultado:
  - `eval-trading: PASS`
  - `security-check: PASS`
  - `quality-check: PASS`

## Refactor
- manter semantica unica de aprovacao humana por ordem de entrada em `S0`.
- manter a verificacao de coerencia documental centralizada em `eval-trading`.

## Alteracoes da issue
- `VERTICALS/TRADING/TRADING-PRD.md`
- `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`
- `PM/DECISION-PROTOCOL.md`
- `scripts/ci/eval_trading.sh`
- `PRD/CHANGELOG.md`
- `artifacts/phase-f7/epic-f7-01-issue-02-s0-explicit-human-approval-per-order.md`
