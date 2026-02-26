# EPIC-F3-01 ISSUE-F3-01-02 Runtime Schema A2A/Hooks/Gateway Validation

- data/hora: 2026-02-26 11:52:20 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F3-01-02` (schema/runtime contract + A2A/hooks/gateway)
- fonte de verdade: `PRD/PRD-MASTER.md`

## Red
- cenario: fixtures invalidas no proprio gate removendo campos `required` mandatarios e alterando `gateway.bind.const`.
- cobertura de cenarios invalidos:
  - top-level required sem `hooks`;
  - `tools.agentToAgent.required` sem `allow`;
  - `hooks.required` sem `internal`;
  - `hooks.internal.entries.required` sem `session-memory`;
  - `gateway.bind.const != loopback`;
  - `gateway.control_plane.ws.required` sem `url`;
  - `gateway.http.endpoints.chatCompletions.required` sem `enabled`.
- resultado esperado: todos os cenarios acima devem falhar em `expect_invalid`.

## Green
- acao: validacao executavel adicionada ao `scripts/ci/eval_runtime_contracts.sh` para o schema `ARC/schemas/openclaw_runtime_config.schema.json`.
- comando: `make eval-runtime`.
- resultado: `eval-runtime-contracts: PASS`.

## Refactor
- o gate agora verifica explicitamente a estrutura contratual obrigatoria de runtime (nao apenas JSON sintatico).
- validacoes negativas permanecem encapsuladas como fixtures de regressao no proprio script.

## Alteracoes da issue
- `scripts/ci/eval_runtime_contracts.sh`
  - adiciona bloco Python para validação estrutural de `openclaw_runtime_config`.
  - adiciona cenarios `valid/invalid` para bloquear drift contratual de A2A/hooks/gateway.
