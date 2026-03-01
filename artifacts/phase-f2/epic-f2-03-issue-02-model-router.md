# EPIC-F2-03 ISSUE-F2-03-02 Model Router Requested/Effective Validation

- data/hora: 2026-02-26 10:11:53 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F2-03-02` (trilha auditavel de roteamento requested/effective)
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md`, `ARC/ARC-MODEL-ROUTING.md`, `PM/DECISION-PROTOCOL.md`

## Red
- cenario: run sem `requested_model` deve falhar.
- cenario: run sem `effective_model` deve falhar.
- cenario: run sem `effective_provider` deve falhar.
- cenario: run sem `fallback_step` ou sem `reason` deve falhar.
- cenario: `fallback_reason` divergente de `reason` deve falhar.
- validacao executavel: `scripts/ci/eval_models.sh` (fixtures invalidas inline em Python para `router_decision`).
- resultado: cenarios invalidos bloqueados.

## Green
- acao: novo contrato executavel `ARC/schemas/router_decision.schema.json`.
- acao: `ARC/ARC-MODEL-ROUTING.md` alinhado para exigir trilha de decisao + policy aplicada + `fallback_step/reason`.
- acao: `PM/DECISION-PROTOCOL.md` atualizado para incluir `requested_provider` no payload de decision.
- comando: `make eval-models`
- resultado: `eval-models: PASS`.

## Auditoria complementar
- `reason` vira campo canonico do contrato; `fallback_reason` permanece apenas por compatibilidade.
- ausencia de trilha requested/effective/fallback agora caracteriza falha de compliance, nao apenas lacuna documental.

## Refactor
- comando: `make phase-f2-gate`
- resultado:
  - `quality-check: PASS`
  - `security-check: PASS`
  - `eval-gates: PASS`
  - `phase-f2-gate: PASS`

## Rastreabilidade
- Roadmap: `B0-09`.
- Source refs:
  - `felixcraft.md` (routing explicavel e fallback auditavel).
  - `felix-openclaw-pontos-relevantes.md` (governanca de runtime com rastreabilidade por run).
