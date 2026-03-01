# EPIC-F2-03 ISSUE-F2-03-04 Budget Governor Run/Task/Day Validation

- data/hora: 2026-02-26 10:17:18 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F2-03-04` (limites por run/task/day + snapshots financeiros obrigatorios)
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md`, `CORE/FINANCIAL-GOVERNANCE.md`, `EVALS/SYSTEM-HEALTH-THRESHOLDS.md`

## Red
- cenario: policy sem `limits` deve falhar.
- cenario: policy sem `limits.day_usd` deve falhar.
- cenario: policy sem `snapshot_contract.required_fields` deve falhar.
- cenario: policy sem `telemetry_source=litellm_aggregated` deve falhar.
- cenario: policy sem `provider_snapshot_source=effective_provider_snapshot` ou sem `burn_rate_policy` deve falhar.
- validacao executavel: `scripts/ci/eval_runtime_contracts.sh` (fixtures invalidas inline em Python para `budget_governor_policy`).
- resultado: contrato incompleto bloqueado.

## Green
- acao: adicao do contrato `ARC/schemas/budget_governor_policy.schema.json`.
- acao: `eval_runtime_contracts.sh` atualizado para validar limites run/task/day, origem de telemetria, snapshot efetivo e vinculo obrigatorio com `credits_snapshots`.
- acao: documentacao reforcada:
  - `CORE/FINANCIAL-GOVERNANCE.md` com bloqueio explicito sem limite run/tarefa/dia.
  - `EVALS/SYSTEM-HEALTH-THRESHOLDS.md` com regra de release bloqueante para baseline de budget.
- comando: `make eval-runtime`
- resultado: `eval-runtime-contracts: PASS`.

## Auditoria complementar
- `telemetry_source` e `provider_snapshot_source` passam a ser parte do contrato, nao apenas observacao de implementacao.
- `burn_rate_policy` com thresholds por hora/dia e `circuit_breaker_action` passa a ser obrigatorio para promover.

## Refactor
- comando: `make phase-f2-gate`
- resultado:
  - `quality-check: PASS`
  - `security-check: PASS`
  - `eval-gates: PASS`
  - `phase-f2-gate: PASS`

## Rastreabilidade
- Roadmap: `B0-13`.
- Source refs:
  - `felixcraft.md` (cost optimization com contratos enforceables).
  - `felix-openclaw-pontos-relevantes.md` (controle operacional progressivo e mitigacao de risco).
