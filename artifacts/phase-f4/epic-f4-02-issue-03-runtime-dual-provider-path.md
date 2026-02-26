# EPIC-F4-02 ISSUE-F4-02-03 Runtime Dual Contract and Provider Path Shape

- data/hora: 2026-02-26 15:30:01 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F4-02-03` (runtime dual + shape de `provider_path`)
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md` (`B1-24`)

## Red
- runtime sem gateway.control_plane.ws em required -> FAIL como esperado (Runtime dual contract check failed: ARC/schemas/openclaw_runtime_config.schema.json)
- runtime sem trilha chatCompletions.enabled -> FAIL como esperado (Runtime dual contract check failed: ARC/schemas/openclaw_runtime_config.schema.json)
- economic_run com provider_path.type=string -> FAIL como esperado (provider_path shape check failed: ARC/schemas/economic_run.schema.json)
- economic_run com provider_path.minItems=0 -> FAIL como esperado (provider_path shape check failed: ARC/schemas/economic_run.schema.json)
- economic_run com provider_path.items.minLength=0 -> FAIL como esperado (provider_path shape check failed: ARC/schemas/economic_run.schema.json)

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
  - adiciona checks estruturais de contrato dual para `openclaw_runtime_config` (WS canonico + trilha `chatCompletions.enabled` sem tornar `http` obrigatorio global).
  - adiciona check estrutural do schema `economic_run` para `provider_path` (array com `minItems >= 1` e itens string com `minLength >= 1`).
- `artifacts/phase-f4/epic-f4-02-issue-03-runtime-dual-provider-path.md`
  - evidencia auditavel do ciclo TDD da issue.
