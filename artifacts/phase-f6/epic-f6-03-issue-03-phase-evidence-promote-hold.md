# EPIC-F6-03 ISSUE-F6-03-03 consolidacao de evidencia de fase e decisao promote hold

- data/hora: 2026-03-01 11:00:00 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F6-03-03`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/PHASE-USABILITY-GUIDE.md`, `PM/DECISION-PROTOCOL.md`, `SEC/allowlists/OPERATORS.yaml`

## Red
- cenario A: evidencias da fase dispersas sem artifact unico de decisao.
- resultado esperado: `hold`.
- cenario B: checklist HITL sem campos obrigatorios ou sem justificativa da decisao final.
- resultado esperado: `hold`.

## Green
- acao:
  - consolidar checklist de prontidao HITL em `artifacts/phase-f6/hitl-readiness-checklist.md`;
  - consolidar resumo final da fase em `artifacts/phase-f6/validation-summary.md`;
  - consolidar status do epico em `artifacts/phase-f6/epic-f6-03-fallback-contingencia-promocao.md`;
  - registrar decisao final `hold` com base no estado atual de `SEC/allowlists/OPERATORS.yaml`.
- comandos:
  1. `make ci-security`
  2. `make eval-trading`
  3. `make ci-quality`
  4. `make eval-gates`
- resultado:
  - `security-check: PASS`
  - `eval-trading: PASS`
  - `quality-check: PASS`
  - `eval-gates: PASS`

## Refactor
- garantir consistencia de links internos apos mover fase F6 para `PM/PHASES/feito/F6-OPERACAO-HUMANA-HITL/`.
- manter rastreabilidade da decisao de fase (`hold`) em artifact unico.

## Alteracoes da issue
- `artifacts/phase-f6/hitl-readiness-checklist.md`
- `artifacts/phase-f6/validation-summary.md`
- `artifacts/phase-f6/epic-f6-03-fallback-contingencia-promocao.md`
- `artifacts/phase-f6/epic-f6-03-issue-03-phase-evidence-promote-hold.md`
- `PM/PHASES/feito/F6-OPERACAO-HUMANA-HITL/EPIC-F6-03-FALLBACK-CONTINGENCIA-E-PROMOCAO.md`
- `PM/PHASES/feito/F6-OPERACAO-HUMANA-HITL/EPICS.md`
- `PRD/PHASE-USABILITY-GUIDE.md`
- `PRD/CHANGELOG.md`
