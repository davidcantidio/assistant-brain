# EPIC-F7-03 S2 escala e promocao consolidado

- data/hora: 2026-03-01 00:34:29 -0300
- host alvo: Darwin arm64
- escopo: `EPIC-F7-03`
- fonte de verdade: `VERTICALS/TRADING/TRADING-PRD.md`, `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`, `PM/DECISION-PROTOCOL.md`, `assistant-brain/artifacts/trading/pre_live_checklist/CHECKLIST-F7-02-S1-20260301-01.json`

## Status por trilha do epic
- `ISSUE-F7-03-01` criterios minimos de promocao `S1 -> S2`: `PASS`
  - evidencia: `assistant-brain/artifacts/phase-f7/epic-f7-03-issue-01-s2-promotion-criteria-hold.md`
- `ISSUE-F7-03-02` decisao `R3` obrigatoria para promocao `S1 -> S2`: `PASS`
  - evidencia: `assistant-brain/artifacts/phase-f7/epic-f7-03-issue-02-s2-r3-decision-required-hold.md`
- `ISSUE-F7-03-03` consolidacao unica da fase e decisao `F7 -> F8`: `PASS`
  - evidencia: `assistant-brain/artifacts/phase-f7/epic-f7-03-issue-03-phase-evidence-promote-hold.md`

## Resumo das 3 issues
- a regra de escala para `S2` exige 30 dias em `S1`, zero `SEV-1/SEV-2`, zero violacao hard-risk e reconciliacao sem duplicidade.
- a `decision_id` do checklist de `S1` nao substitui a decisao `R3` de promocao para `S2`.
- a fase `F7` agora possui artifact unico de decisao e checklist canonico referenciado.

## Decisao do epic
- resultado: `hold`
- justificativa:
  - `credentials_live_no_withdraw=fail`
  - `hitl_channel_ready=fail`
  - `backup_operator_enabled=fail`
  - `explicit_order_approval_active=fail`
  - ausencia de decisao `R3` com limites explicitos para `S2`

## Relacao com o summary da fase
- evidencia consolidada da fase: `assistant-brain/artifacts/phase-f7/validation-summary.md`
- a decisao `F7 -> F8` deve ser lida a partir do summary unico da fase e nao apenas do checklist de `S1`.
