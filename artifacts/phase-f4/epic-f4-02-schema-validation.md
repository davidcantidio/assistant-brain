# EPIC-F4-02 Schema Validation - Consolidated Evidence

- data/hora: 2026-02-26 15:30:41 -0300
- host alvo: Darwin arm64
- escopo: fechamento consolidado do `EPIC-F4-02`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md` (`B1-21`, `B1-24`)

## Status por issue
- `ISSUE-F4-02-01` concluida:
  - ausencia de schema obrigatorio e JSON invalido bloqueiam o gate;
  - schemas restaurados validos retornam `PASS`.
  - evidencia: `artifacts/phase-f4/epic-f4-02-issue-01-schema-presence-json-valid.md`.
- `ISSUE-F4-02-02` concluida:
  - ausencia de campo minimo em `required[]` bloqueia o gate para os 4 contratos versionados;
  - restauracao dos campos obrigatorios retorna `PASS`.
  - evidencia: `artifacts/phase-f4/epic-f4-02-issue-02-min-required-fields.md`.
- `ISSUE-F4-02-03` concluida:
  - runtime dual incompleto (sem `control_plane.ws` ou trilha `chatCompletions.enabled`) bloqueia o gate;
  - `provider_path` com shape invalido bloqueia o gate;
  - restauracao estrutural retorna `PASS`.
  - evidencia: `artifacts/phase-f4/epic-f4-02-issue-03-runtime-dual-provider-path.md`.

## Validacao final
1. `make eval-integrations` -> `eval-integrations: PASS`
2. `make ci-quality` -> `quality-check: PASS`

## Decisao do epico
- decisao: `done`.
- justificativa:
  - as 3 issues do epico foram executadas com evidencias Red/Green/Refactor;
  - gate oficial de saida do epico (`eval-integrations: PASS`) confirmado.

## Contratos validados
- presenca e JSON valido dos schemas obrigatorios de integracao.
- campos minimos obrigatorios dos contratos versionados:
  - `signal_intent`, `order_intent`, `execution_report`, `economic_run`.
- contrato dual de runtime e trilha de compatibilidade:
  - `gateway.control_plane.ws` canonico;
  - `gateway.http.endpoints.chatCompletions.enabled` presente sem obrigar `http` globalmente.
- shape de `provider_path` em `economic_run`:
  - array nao vazio, itens string nao vazios.
