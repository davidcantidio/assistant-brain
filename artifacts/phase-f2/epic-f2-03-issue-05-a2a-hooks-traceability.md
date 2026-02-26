# EPIC-F2-03 ISSUE-F2-03-05 A2A and Hooks/Webhooks Traceability Validation

- data/hora: 2026-02-26 10:20:10 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F2-03-05` (A2A allowlist + hooks mappings + `trace_id`)
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md`, `ARC/ARC-CORE.md`, `ARC/schemas/openclaw_runtime_config.schema.json`

## Red
- cenario: delegacao A2A com `allowed=false` (fora de allowlist) deve falhar.
- cenario: webhook sem `mapping_id` deve falhar.
- cenario: webhook sem `trace_id` deve falhar.
- validacao executavel: `scripts/ci/eval_runtime_contracts.sh` (fixtures invalidas inline em Python para contratos A2A/hooks).
- resultado: cenarios opacos/bypass bloqueados.

## Green
- acao: contratos executaveis adicionados:
  - `ARC/schemas/a2a_delegation_event.schema.json`
  - `ARC/schemas/webhook_ingest_event.schema.json`
- acao: `eval_runtime_contracts.sh` reforcado para validar:
  - `tools.agentToAgent.allow[]`
  - `hooks.mappings[]`
  - presenca obrigatoria de `trace_id` e mapping em eventos.
- acao: `ARC/ARC-CORE.md` atualizado com referencias contratuais de A2A/hooks.
- comando: `make eval-runtime`
- resultado: `eval-runtime-contracts: PASS`.

## Refactor
- comando: `make eval-gates`
- resultado: `eval-gates: PASS`.
- comando: `make phase-f2-gate`
- resultado: `phase-f2-gate: PASS`.

## Rastreabilidade
- Roadmap: `B0-17`, `B0-18`.
- Source refs:
  - `felixcraft.md` (multi-agent architecture e hooks/webhooks com contrato).
  - `felix-openclaw-pontos-relevantes.md` (rastreabilidade operacional e memoria de execucao).
