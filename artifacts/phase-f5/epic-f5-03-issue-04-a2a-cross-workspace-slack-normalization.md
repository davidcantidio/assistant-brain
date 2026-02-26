# EPIC-F5-03 ISSUE-F5-03-04 A2A cross-workspace e Slack event normalizado

- data/hora: 2026-02-26 20:03:00 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F5-03-04`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md` (`B1-R16`, `B1-R17`)

## Red
- cenario A: delegacao A2A sem limites explicitos de concorrencia/custo ou sem fallback serial em conflito.
- resultado esperado: `FAIL` no `make eval-runtime`.
- cenario B: webhook Slack com `thread_context` incompleto (sem `issue_id` ou `microtask_id`).
- resultado esperado: `FAIL` no `make eval-runtime`.

## Green
- acao:
  - endurecer `ARC/schemas/a2a_delegation_event.schema.json` com `source_workspace`, `target_workspace`, `max_concurrency`, `max_cost_usd`, `serial_fallback_on_conflict`;
  - endurecer `ARC/schemas/webhook_ingest_event.schema.json` com `thread_context` tipado;
  - endurecer `scripts/ci/eval_runtime_contracts.sh` para validar os novos requireds e cenarios invalidos;
  - alinhar `ARC/ARC-CORE.md` e `PRD/PRD-MASTER.md` com contrato de delegacao cross-workspace e thread mapping.
- comando: `make eval-runtime`.
- resultado: `eval-runtime-contracts: PASS`.

## Refactor
- comandos:
  1. `make eval-gates`
  2. `make ci-security`
- resultados:
  - `eval-gates: PASS`
  - `security-check: PASS`

## Alteracoes da issue
- `ARC/schemas/a2a_delegation_event.schema.json`
- `ARC/schemas/webhook_ingest_event.schema.json`
- `scripts/ci/eval_runtime_contracts.sh`
- `ARC/ARC-CORE.md`
- `PRD/PRD-MASTER.md`
- `PRD/CHANGELOG.md`
- `artifacts/phase-f5/epic-f5-03-issue-04-a2a-cross-workspace-slack-normalization.md`
