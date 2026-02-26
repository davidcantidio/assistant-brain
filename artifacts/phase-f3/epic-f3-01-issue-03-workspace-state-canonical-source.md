# EPIC-F3-01 ISSUE-F3-01-03 Workspace-State Canonical Source Validation

- data/hora: 2026-02-26 11:53:32 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F3-01-03` (unicidade da fonte canonica de workspace state)
- fonte de verdade: `PRD/PRD-MASTER.md`

## Red
- cenario: criar caminho conflitante adicional `workspaces/aux/.openclaw/workspace-state.json`.
- comando: `make eval-runtime`.
- resultado esperado: `FAIL` por conflito de fonte canonica.
- evidencia:
  - `workspace-state invalido: esperado exatamente 1 caminho canonico em workspaces/*/.openclaw/workspace-state.json; encontrados 2.`
  - `workspace-state encontrado: workspaces/aux/.openclaw/workspace-state.json`
  - `workspace-state encontrado: workspaces/main/.openclaw/workspace-state.json`

## Green
- acao: remover caminho conflitante e manter apenas `workspaces/main/.openclaw/workspace-state.json`.
- comando: `make eval-runtime`.
- resultado: `eval-runtime-contracts: PASS`.

## Refactor
- comando: `make eval-runtime` (segunda execucao).
- resultado: `eval-runtime-contracts: PASS`.

## Alteracoes da issue
- `scripts/ci/eval_runtime_contracts.sh`
  - adiciona guarda de unicidade para `workspaces/*/.openclaw/workspace-state.json`.
  - exige caminho canonico unico em `workspaces/main/.openclaw/workspace-state.json`.
  - preserva validacao de conteudo (`version`, `bootstrapSeededAt` ISO-8601 UTC com `Z`).
