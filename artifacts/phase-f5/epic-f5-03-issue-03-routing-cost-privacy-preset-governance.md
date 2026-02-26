# EPIC-F5-03 ISSUE-F5-03-03 governanca de roteamento custo e privacidade por preset

- data/hora: 2026-02-26 19:45:00 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F5-03-03`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md` (`B1-R08`, `B1-R09`, `B1-R10`, `B1-R13`, `B1-R14`)

## Red
- cenario A: `router_decision` sem `preset_id` ou sem metadados de burn-rate/circuit breaker.
- resultado esperado: `FAIL` em `make eval-gates` (via `eval-models`).
- cenario B: rota `sensitive` sem coerencia `no_fallback=true`, `pin_provider=true`, `zdr_enforced=true`.
- resultado esperado: `FAIL` em `make eval-gates`.

## Green
- acao:
  - endurecer `ARC/schemas/router_decision.schema.json` com requireds de preset/governanca (`preset_id`, `pin_provider`, `no_fallback`, `burn_rate_policy`, `privacy_controls`);
  - endurecer `ARC/schemas/models_catalog.schema.json` para exigir `catalog_version`;
  - endurecer `scripts/ci/eval_models.sh` e `scripts/ci/eval_runtime_contracts.sh` para validar os novos requireds e a regra sensivel;
  - alinhar `ARC/ARC-MODEL-ROUTING.md` e `SEC/SEC-POLICY.md` com as regras de preset/custo/privacidade.
- comando: `make eval-gates`.
- resultado: `eval-gates: PASS`.

## Refactor
- comandos:
  1. `make eval-runtime`
  2. `make ci-security`
- resultados:
  - `eval-runtime-contracts: PASS`
  - `security-check: PASS`

## Alteracoes da issue
- `scripts/ci/eval_models.sh`
- `scripts/ci/eval_runtime_contracts.sh`
- `ARC/schemas/router_decision.schema.json`
- `ARC/schemas/models_catalog.schema.json`
- `ARC/ARC-MODEL-ROUTING.md`
- `SEC/SEC-POLICY.md`
- `PRD/CHANGELOG.md`
- `artifacts/phase-f5/epic-f5-03-issue-03-routing-cost-privacy-preset-governance.md`
