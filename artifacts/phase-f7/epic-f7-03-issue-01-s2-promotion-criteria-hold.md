# EPIC-F7-03 ISSUE-F7-03-01 criterios minimos de promocao `S1 -> S2`

- data/hora: 2026-03-01 00:16:24 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F7-03-01`
- fonte de verdade: `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`, `PRD/ROADMAP.md`, `VERTICALS/TRADING/TRADING-PRD.md`, `artifacts/trading/pre_live_checklist/CHECKLIST-F7-02-S1-20260301-01.json`

## Red
- cenario A: avaliar promocao `S1 -> S2` sem evidenciar a janela minima de 30 dias em `S1`.
- resultado esperado: `hold`.
- cenario B: avaliar promocao `S1 -> S2` com itens criticos ainda em `fail` no checklist operacional de `S1`.
- resultado esperado: `hold`.

## Green
- acao:
  - validar os criterios minimos de promocao ja definidos no PRD e no enablement de trading;
  - confrontar os criterios com o estado operacional atual de `S1`;
  - registrar evidencia unica da issue com decisao `hold`.
- comandos:
  1. `make eval-trading`
- resultado:
  - `eval-trading: PASS`

## Refactor
- manter a norma de promocao inalterada, porque os criterios objetivos ja existem como fonte de verdade.
- manter `hold` enquanto nao houver evidencia da janela minima de 30 dias e enquanto o checklist de `S1` permanecer com itens criticos em `fail`.

## Evidencia objetiva
- criterios minimos obrigatorios para `S1 -> S2` confirmados:
  - minimo de 30 dias corridos em `S1` com capital minimo;
  - zero incidentes `SEV-1/SEV-2` no periodo;
  - sem violacao hard de risco no periodo;
  - reconciliacao sem duplicidade no periodo.
- estado atual observado:
  - o checklist `CHECKLIST-F7-02-S1-20260301-01` ainda registra `credentials_live_no_withdraw=fail`;
  - o checklist `CHECKLIST-F7-02-S1-20260301-01` ainda registra `hitl_channel_ready=fail`;
  - o checklist `CHECKLIST-F7-02-S1-20260301-01` ainda registra `backup_operator_enabled=fail`;
  - o checklist `CHECKLIST-F7-02-S1-20260301-01` ainda registra `explicit_order_approval_active=fail`.
- decisao da issue: `hold`.

## Alteracoes da issue
- `artifacts/phase-f7/epic-f7-03-issue-01-s2-promotion-criteria-hold.md`
- `PRD/CHANGELOG.md`
