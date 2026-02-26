# EPIC-F4-02 ISSUE-F4-02-02 Minimum Required Contract Fields

- data/hora: 2026-02-26 15:28:47 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F4-02-02` (campos minimos obrigatorios em contratos de integracao)
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md` (`B1-21`)

## Red
- ARC/schemas/signal_intent.schema.json sem required `intent_id` -> FAIL como esperado (Schema contract check failed: ARC/schemas/signal_intent.schema.json)
- ARC/schemas/order_intent.schema.json sem required `order_intent_id` -> FAIL como esperado (Schema contract check failed: ARC/schemas/order_intent.schema.json)
- ARC/schemas/execution_report.schema.json sem required `execution_report_id` -> FAIL como esperado (Schema contract check failed: ARC/schemas/execution_report.schema.json)
- ARC/schemas/economic_run.schema.json sem required `run_id` -> FAIL como esperado (Schema contract check failed: ARC/schemas/economic_run.schema.json)

## Green
- comando: `make eval-integrations`
- resultado: `eval-integrations: PASS`

## Refactor
- comando: `make eval-integrations` (segunda execucao para estabilidade)
- resultado: `eval-integrations: PASS`

## Validacao adicional da issue
- comando: `make ci-quality`
- resultado: `quality-check: PASS`

## Alteracoes da issue
- `scripts/ci/eval_integrations.sh`
  - adiciona enforcement estruturado de `required[]` e `properties` minimos para `signal_intent`, `order_intent`, `execution_report` e `economic_run`.
- `artifacts/phase-f4/epic-f4-02-issue-02-min-required-fields.md`
  - evidencia auditavel do ciclo TDD da issue.
