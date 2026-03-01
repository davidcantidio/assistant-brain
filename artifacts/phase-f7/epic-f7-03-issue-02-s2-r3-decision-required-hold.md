# EPIC-F7-03 ISSUE-F7-03-02 decision `R3` obrigatoria para promocao `S1 -> S2`

- data/hora: 2026-03-01 00:18:57 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F7-03-02`
- fonte de verdade: `VERTICALS/TRADING/TRADING-PRD.md`, `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`, `PM/DECISION-PROTOCOL.md`, `artifacts/trading/pre_live_checklist/CHECKLIST-F7-02-S1-20260301-01.json`

## Red
- cenario A: permitir promocao para `S2` sem decision formal de risco para aumento de capital e limites.
- resultado esperado: `hold`.
- cenario B: aceitar uma `decision_id` de prontidao de `S1` como se fosse a decisao de promocao para `S2`.
- resultado esperado: `hold`.

## Green
- acao:
  - confirmar nas fontes de verdade que a promocao `S1 -> S2` exige decision `R3` com limites explicitos do novo nivel;
  - verificar se existe evidencia operacional atual dessa decisao de promocao;
  - registrar resultado `hold` pela ausencia da decisao exigida.
- comandos:
  1. `make eval-trading`
- resultado:
  - `eval-trading: PASS`

## Refactor
- manter separacao entre a `decision_id` do checklist de `S1` e a decision formal de promocao para `S2`.
- manter bloqueio de promocao enquanto nao houver payload/registro de decisao com limites explicitos do novo nivel.

## Evidencia objetiva
- regra normativa confirmada:
  - `S2 - Escala gradual`: promocao de limite/capital somente por `decision R3`;
  - gate de promocao exige decisao `R3` com limites explicitos de novo nivel.
- estado atual observado:
  - o checklist `CHECKLIST-F7-02-S1-20260301-01` contem `decision_id=DEC-F7-02-S1-20260301-01`, associado ao readiness de `S1`, nao a uma promocao `S1 -> S2`;
  - a busca em `artifacts/`, `PM/` e `PRD/` nao encontrou evidencia de decisao de promocao `S1 -> S2` com limites explicitos de capital/risco do novo nivel.
- decisao da issue: `hold`.

## Alteracoes da issue
- `artifacts/phase-f7/epic-f7-03-issue-02-s2-r3-decision-required-hold.md`
- `PRD/CHANGELOG.md`
