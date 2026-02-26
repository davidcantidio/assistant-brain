# EPIC-F5-01 ISSUE-F5-01-03 Contratos versionados + compatibilidade dual runtime

- data/hora: 2026-02-26 18:28:17 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F5-01-03`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md` (`B1-21`, `B1-24`)

## Red
- cenario A: remover metadata de versionamento (`schema_version`) de qualquer contrato de integracao.
- resultado esperado: `FAIL` no gate `eval-integrations` por ausencia de metadata obrigatoria.
- cenario B: remover metadados estruturais de schema (`$schema`, `$id`) em contrato de integracao.
- resultado esperado: `FAIL` no gate por contrato nao versionado de forma auditavel.

## Green
- acao:
  - adicionar `schema_version` obrigatorio nos contratos:
    - `signal_intent.schema.json`
    - `order_intent.schema.json`
    - `execution_report.schema.json`
    - `economic_run.schema.json`
  - endurecer `scripts/ci/eval_integrations.sh` com `schema_assert_version_metadata` para exigir:
    - `$schema` e `$id`;
    - `required[]` contendo `schema_version`;
    - `properties.schema_version` com `type=string` e `const=1.0`.
- comando: `make eval-integrations`.
- resultado: `eval-integrations: PASS`.

## Refactor
- comandos:
  1. `make eval-trading`
  2. `make ci-quality`
- resultados:
  - `eval-trading: PASS`
  - `quality-check: PASS`

## Alteracoes da issue
- `ARC/schemas/signal_intent.schema.json`
- `ARC/schemas/order_intent.schema.json`
- `ARC/schemas/execution_report.schema.json`
- `ARC/schemas/economic_run.schema.json`
  - adicionam metadata minima de versionamento (`schema_version`).
- `scripts/ci/eval_integrations.sh`
  - adiciona `schema_assert_version_metadata` e enforcement nos quatro contratos de integracao.
- `PRD/CHANGELOG.md`
  - registra execucao normativa da `ISSUE-F5-01-03`.
- `artifacts/phase-f5/epic-f5-01-issue-03-versioned-contracts-runtime-dual.md`
  - evidencia auditavel do ciclo da issue.
