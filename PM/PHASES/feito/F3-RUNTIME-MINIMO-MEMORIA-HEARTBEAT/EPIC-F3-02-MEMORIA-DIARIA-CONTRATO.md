---
doc_id: "EPIC-F3-02-MEMORIA-DIARIA-CONTRATO.md"
version: "1.2"
status: "active"
owner: "PM"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-030", "RFC-040", "RFC-050"]
---

# EPIC-F3-02 Memoria diaria com contrato minimo

## Objetivo
Garantir que a memoria operacional diaria esteja no formato canonico e com qualidade minima verificavel para continuidade de contexto humano.

## Resultado de Negocio Mensuravel
- operador consegue registrar e retomar contexto diario sem lacuna estrutural.
- gate de runtime bloqueia notas incompletas antes de promover fase.

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- `make eval-runtime` executado com sucesso.
- evidencia de memoria diaria valida registrada no artifact do epico com mensagem assertiva em cenarios Red.
- todas as issues do epico com DoR completo (`owner`, `estimate_hours`, `estimate_points`, `risk_class`, `risk_tier`, `dependencies`, `required_inputs`).

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F3-02-01 - Validar MEMORY.md e nota diaria YYYY-MM-DD
**User story**
Como operador, quero garantir presenca dos arquivos canonicos de memoria para manter continuidade operacional.

**Metadados DoR (obrigatorio)**
- owner: `PO`
- estimate_hours: `3`
- estimate_points: `2`
- risk_class: `medio`
- risk_tier: `R1`
- dependencies:
  - `workspaces/main/MEMORY.md`
  - `workspaces/main/memory/YYYY-MM-DD.md`
  - `scripts/ci/eval_runtime_contracts.sh`
- required_inputs:
  - baseline atual de memoria diaria
  - output vigente de `make eval-runtime`

**Plano TDD**
1. `Red`: simular ausencia de `MEMORY.md` ou da nota diaria e executar `make eval-runtime`.
2. `Green`: restaurar `workspaces/main/MEMORY.md` e `workspaces/main/memory/YYYY-MM-DD.md`.
3. `Refactor`: rerodar `make eval-runtime` para confirmar baseline.

**Criterios de aceitacao**
- Given arquivo canonico de memoria ausente, When `make eval-runtime` roda, Then o gate falha com arquivo faltante explicito.
- Given memoria canonica presente, When `make eval-runtime` roda, Then nao ha falha por ausencia de arquivo.
- Given alteracao de contrato de memoria, When issue atualizar, Then risco e dependencia devem ser revisados.

**Checklist QA (DoD da issue)**
- executar `Red-A/Red-B/Green/Refactor`.
- anexar logs com mensagem assertiva de falha por arquivo ausente.

### ISSUE-F3-02-02 - Validar header e secoes obrigatorias da nota diaria
**User story**
Como operador, quero padrao unico de nota diaria para facilitar leitura, auditoria e validacao automatica.

**Metadados DoR (obrigatorio)**
- owner: `QA Lead`
- estimate_hours: `6`
- estimate_points: `3`
- risk_class: `medio`
- risk_tier: `R2`
- dependencies:
  - `PRD/PRD-MASTER.md`
  - `ARC/ARC-HEARTBEAT.md`
  - `ARC/schemas/nightly_memory_cycle.schema.json`
  - `scripts/ci/eval_runtime_contracts.sh`
- required_inputs:
  - nota diaria canonica de referencia
  - fixture de cabecalho invalido
  - fixture de ciclo noturno com atraso/falha

**Plano TDD**
1. `Red`: quebrar header ou remover secao obrigatoria e executar `make eval-runtime`.
2. `Green`: restaurar formato `# YYYY-MM-DD` e secoes obrigatorias.
3. `Refactor`: rerodar `make eval-runtime` para validar consistencia.

**Criterios de aceitacao**
- Given header invalido ou secao obrigatoria ausente, When `make eval-runtime` roda, Then o gate falha com apontamento da secao.
- Given header e secoes obrigatorias corretas, When `make eval-runtime` roda, Then a nota passa na verificacao estrutural.
- Given falha/atraso >24h no ciclo noturno, When contrato for validado, Then `incident_ref` e obrigatorio e auditavel.

**Checklist QA (DoD da issue)**
- executar fixture invalida de header.
- executar fixture de ciclo noturno sem `incident_ref` para atraso >24h.
- anexar logs do gate por cenario.

### ISSUE-F3-02-03 - Validar bullet minimo em Key Events Decisions Made Facts Extracted
**User story**
Como operador, quero garantir conteudo minimo util por secao para evitar nota diaria vazia.

**Metadados DoR (obrigatorio)**
- owner: `QA Lead`
- estimate_hours: `6`
- estimate_points: `3`
- risk_class: `medio`
- risk_tier: `R2`
- dependencies:
  - `workspaces/main/memory/YYYY-MM-DD.md`
  - `ARC/schemas/nightly_memory_cycle.schema.json`
  - `scripts/ci/eval_runtime_contracts.sh`
- required_inputs:
  - fixture sem bullet em secao obrigatoria
  - fixture de atraso >24h sem `incident_ref`

**Plano TDD**
1. `Red`: manter secao obrigatoria sem bullet e executar `make eval-runtime`.
2. `Green`: adicionar pelo menos um bullet por secao obrigatoria.
3. `Refactor`: rerodar `make eval-runtime` e registrar evidencia.

**Criterios de aceitacao**
- Given secao obrigatoria sem bullet, When `make eval-runtime` roda, Then o gate falha com secao afetada.
- Given todas as secoes obrigatorias com ao menos um bullet, When `make eval-runtime` roda, Then retorna `eval-runtime-contracts: PASS`.
- Given atraso >24h no ciclo noturno, When contrato noturno for validado, Then `incident_ref` e obrigatorio.

**Checklist QA (DoD da issue)**
- executar fixture sem bullet por secao.
- validar cenario de atraso >24h sem `incident_ref`.
- anexar logs com mensagem assertiva por cenario.

## Artifact Minimo do Epico
- registrar resumo em `artifacts/phase-f3/epic-f3-02-memory-contract.md` com:
  - status de `MEMORY.md` e nota diaria;
  - conformidade de header/secoes/bullets;
  - resultado final de `make eval-runtime`.

## Resultado desta Rodada (Pos-Audit)
- escopo documental atualizado com contrato DoR/DoD nas 3 issues.
- cobertura de `incident_ref` para atraso >24h incorporada nos ACs.
- conclusao: `EPIC-F3-02` pronto para reauditoria de cobertura F3.

## Dependencias
- [Workspace Memory Canonico](../../../../workspaces/main/MEMORY.md)
- [Workspace Daily Memory](../../../../workspaces/main/memory/2026-02-24.md)
- [ARC Heartbeat](../../../../ARC/ARC-HEARTBEAT.md)
- [PRD Master](../../../../PRD/PRD-MASTER.md)
- [Eval Runtime Contracts Script](../../../../scripts/ci/eval_runtime_contracts.sh)
