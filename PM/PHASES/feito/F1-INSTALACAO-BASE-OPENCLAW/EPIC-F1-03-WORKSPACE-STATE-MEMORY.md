---
doc_id: "EPIC-F1-03-WORKSPACE-STATE-MEMORY.md"
version: "1.2"
status: "active"
owner: "PM"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-010", "RFC-040", "RFC-050"]
---

# EPIC-F1-03 Workspace state e memoria operacional minima

## Objetivo
Garantir que o estado canonico do workspace e o baseline de memoria diaria estejam prontos para uso humano real na F1.

## Resultado de Negocio Mensuravel
- operador passa a ter fonte de verdade operacional valida para estado e memoria.
- reducao de perda de contexto no fechamento e reabertura de sessoes.

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- `make eval-runtime` executado com sucesso.
- evidencias de estado e memoria registradas no artifact do epico.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F1-03-01 - Validar estado canonico do workspace
**User story**  
Como operador, quero confirmar a presenca e consistencia do estado canonico para evitar ambiguidade operacional.

**Metadados de governanca (DoR/DoD)**
- objetivo_verificavel: `workspace-state canonico presente, valido e explicitamente vinculado ao gate operacional`
- risk_tier: `R1`
- owner_issue: `Tech Lead`
- estimativa: `0.5 dia util`
- dependencias: `workspaces/main/.openclaw/workspace-state.json`, `make eval-runtime`, `PRD/PHASE-USABILITY-GUIDE.md`, `PRD/PRD-MASTER.md`
- inputs_minimos: arquivo `workspace-state.json` valido, referencia normativa de fonte de verdade operacional
- gate_path: `Ready -> Decomposed -> InProgress -> Verify -> Done`
- evidence_refs_obrigatorios:
  - `artifacts/phase-f1/epic-f1-03-runtime-memory.md`
  - `stdout://make eval-runtime`
- vinculo_normativo_explicito:
  - `PRD/PHASE-USABILITY-GUIDE.md` define `F1` como ambiente local operacional e `F3` como rotina operacional minima baseada em estado/memoria.
  - `PRD/PRD-MASTER.md` define `output.json/status.json/verify.log` como fonte de verdade operacional e exige contratos verificaveis para promote/release.

**Plano TDD**
1. `Red`: remover/invalidar referencia de estado e executar `make eval-runtime`.
2. `Green`: restaurar `workspaces/main/.openclaw/workspace-state.json` conforme contrato.
3. `Refactor`: rerodar `make eval-runtime` para garantir estabilidade.

**Criterios de aceitacao**
- Given estado canonico ausente/invalido, When `make eval-runtime` roda, Then o check falha por contrato de runtime.
- Given estado canonico valido, When `make eval-runtime` roda, Then nao ha falha por ausencia de estado.
- Given issue encerrada, When a rastreabilidade e auditada, Then existe referencia normativa explicita que conecta `workspace-state` ao gate operacional desta trilha de fases.

### ISSUE-F1-03-02 - Validar estrutura minima de memoria operacional
**User story**  
Como operador, quero manter `MEMORY.md` e `memory/YYYY-MM-DD.md` no formato esperado para preservacao de contexto.

**Metadados de governanca (DoR/DoD)**
- objetivo_verificavel: `memoria operacional minima valida e trilha completa de auditoria do ciclo noturno`
- risk_tier: `R2`
- owner_issue: `Tech Lead`
- estimativa: `1 dia util`
- dependencias: `workspaces/main/MEMORY.md`, `workspaces/main/memory/YYYY-MM-DD.md`, `make eval-runtime`, `memory_contract`
- inputs_minimos: nota diaria existente, campos de auditoria `scheduled_at`, `executed_at`, `status`, `incident_ref`
- gate_path: `Ready -> Decomposed -> InProgress -> Verify -> Review/Gate -> Done`
- evidence_refs_obrigatorios:
  - `artifacts/phase-f1/epic-f1-03-runtime-memory.md`
  - `stdout://make eval-runtime`

**Plano TDD**
1. `Red`: validar nota diaria sem secoes obrigatorias.
2. `Green`: ajustar nota diaria para conter estrutura minima valida.
3. `Refactor`: rerodar `make eval-runtime` para garantir conformidade continua.

**Criterios de aceitacao**
- Given nota diaria sem secoes obrigatorias, When `make eval-runtime` roda, Then o check de memoria falha.
- Given nota diaria com estrutura obrigatoria, When `make eval-runtime` roda, Then retorna `eval-runtime-contracts: PASS`.
- Given execucao do ciclo noturno, When a evidencia e revisada, Then existem `scheduled_at`, `executed_at`, `status` e `daily_note_ref` registrados.
- Given falha ou atraso acima de 24h, When o ciclo noturno e auditado, Then `incident_ref` e obrigatorio.
- Given risco `R2`, When a issue encerra, Then o fechamento exige `Review/Gate` com evidencia consolidada.

### ISSUE-F1-03-03 - Validar heartbeat e ciclo noturno
**User story**  
Como operador, quero confirmar baseline de heartbeat e nightly extraction para operar com rotina previsivel.

**Metadados de governanca (DoR/DoD)**
- objetivo_verificavel: `heartbeat baseline e ciclo noturno alinhados com politica de incidente fail-closed`
- risk_tier: `R2`
- owner_issue: `Tech Lead`
- estimativa: `1 dia util`
- dependencias: `ARC/ARC-HEARTBEAT.md`, `PRD/PRD-MASTER.md`, `make eval-runtime`
- inputs_minimos: heartbeat baseline, timezone `America/Sao_Paulo`, politica de incidente para atraso/falha >24h
- gate_path: `Ready -> Decomposed -> InProgress -> Verify -> Review/Gate -> Done`
- evidence_refs_obrigatorios:
  - `artifacts/phase-f1/epic-f1-03-runtime-memory.md`
  - `stdout://make eval-runtime`

**Plano TDD**
1. `Red`: introduzir divergencia de baseline/timezone em heartbeat.
2. `Green`: alinhar heartbeat/noturno ao contrato canonicamente definido.
3. `Refactor`: executar `make eval-runtime` e registrar evidencia.

**Criterios de aceitacao**
- Given baseline/timezone divergente, When `make eval-runtime` roda, Then o check falha.
- Given baseline/timezone alinhado (`15 minutos`, `America/Sao_Paulo`), When `make eval-runtime` roda, Then retorna `PASS`.
- Given atraso ou falha do ciclo noturno por mais de 24h, When a conformidade e revisada, Then `incident_ref` obrigatorio deve existir e o gate permanece bloqueado ate reconciliacao.
- Given evidencia do ciclo noturno registrada, When a issue e auditada, Then `scheduled_at`, `executed_at`, `status` e `incident_ref` ficam rastreaveis no artifact.

## Artifact Minimo do Epico
- registrar resumo em `artifacts/phase-f1/epic-f1-03-runtime-memory.md` com:
  - estado canonico validado;
  - nota diaria validada;
  - resultado de `make eval-runtime`.

## Resultado desta Rodada
- `make eval-runtime` final: `PASS` (`eval-runtime-contracts: PASS`).
- evidencia consolidada: `artifacts/phase-f1/epic-f1-03-runtime-memory.md`.
- nota diaria operacional criada e validada: `workspaces/main/memory/2026-02-25.md`.
- conclusao: EPIC-F1-03 concluido no escopo documental/tdd desta rodada.

## Dependencias
- [ARC Heartbeat](../../../../ARC/ARC-HEARTBEAT.md)
- [PRD Master](../../../../PRD/PRD-MASTER.md)
- [Phase Usability Guide](../../../../PRD/PHASE-USABILITY-GUIDE.md)
