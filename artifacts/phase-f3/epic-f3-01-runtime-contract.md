# EPIC-F3-01 Runtime Contract - Consolidated Validation

- data/hora: 2026-02-26 11:53:32 -0300
- host alvo: Darwin arm64
- escopo: fechamento consolidado do `EPIC-F3-01`
- fonte de verdade: `PRD/PRD-MASTER.md`

## Status por issue
- `ISSUE-F3-01-01` concluida com endurecimento de `required_files`:
  - bloqueio de caminhos duplicados;
  - agregacao de todos os ausentes no mesmo run.
  - evidencia: `artifacts/phase-f3/epic-f3-01-issue-01-required-files.md`.
- `ISSUE-F3-01-02` concluida com validacao executavel do schema `openclaw_runtime_config`:
  - cobertura obrigatoria de A2A/hooks/gateway;
  - fixtures `valid/invalid` para bloquear drift estrutural.
  - evidencia: `artifacts/phase-f3/epic-f3-01-issue-02-runtime-schema-a2a-hooks-gateway.md`.
- `ISSUE-F3-01-03` concluida com guarda de unicidade de fonte canonica de `workspace-state`.
  - evidencia: `artifacts/phase-f3/epic-f3-01-issue-03-workspace-state-canonical-source.md`.

## Validacao final
1. `make eval-runtime` -> `PASS`
2. `make eval-runtime` (estabilidade/refactor) -> `PASS`

## Contrato de runtime endurecido
- required files: duplicidade e faltantes agregados.
- runtime schema contract: required estrutural para `agents/tools/channels/hooks/memory/gateway`, A2A/hooks internos e gateway (`bind=loopback`, `control_plane.ws`, `chatCompletions.enabled`).
- workspace state: unica fonte canonica permitida em `workspaces/main/.openclaw/workspace-state.json`.
