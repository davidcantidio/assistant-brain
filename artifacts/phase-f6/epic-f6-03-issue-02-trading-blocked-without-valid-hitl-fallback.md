# EPIC-F6-03 ISSUE-F6-03-02 pre-condicao de live com fallback HITL invalido permanece TRADING_BLOCKED

- data/hora: 2026-03-01 10:35:00 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F6-03-02`
- fonte de verdade: `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`, `VERTICALS/TRADING/TRADING-PRD.md`, `PM/DECISION-PROTOCOL.md`, `PRD/PRD-MASTER.md`

## Red
- cenario A: permitir live sem fallback HITL validado.
- resultado esperado: `FAIL` no `make eval-trading`.
- cenario B: permitir remocao de `TRADING_BLOCKED` sem decisao formal registrada.
- resultado esperado: `FAIL` no `make eval-trading`.

## Green
- acao:
  - reforcar `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`, `VERTICALS/TRADING/TRADING-PRD.md` e `PM/DECISION-PROTOCOL.md` com regra explicita:
    - sem fallback HITL validado, live MUST permanecer `TRADING_BLOCKED`;
    - remocao de `TRADING_BLOCKED` por prontidao HITL somente por decisao formal registrada.
  - endurecer `scripts/ci/eval_trading.sh` com checks executaveis dessas duas regras nos tres documentos.
- comandos:
  1. `make eval-trading`
  2. `make ci-security`
  3. `make ci-quality`
- resultado:
  - `eval-trading: PASS`
  - `security-check: PASS`
  - `quality-check: PASS`

## Refactor
- alinhar linguagem de bloqueio e desbloqueio formal entre politica de decisao e criterios de enablement.
- manter o gate textual de trading como validador unico do requisito documental.

## Alteracoes da issue
- `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`
- `VERTICALS/TRADING/TRADING-PRD.md`
- `PM/DECISION-PROTOCOL.md`
- `scripts/ci/eval_trading.sh`
- `PRD/CHANGELOG.md`
- `artifacts/phase-f6/epic-f6-03-issue-02-trading-blocked-without-valid-hitl-fallback.md`
