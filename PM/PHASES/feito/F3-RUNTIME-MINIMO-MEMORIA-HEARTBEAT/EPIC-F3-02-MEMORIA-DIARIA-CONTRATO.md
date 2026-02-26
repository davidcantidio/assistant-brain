---
doc_id: "EPIC-F3-02-MEMORIA-DIARIA-CONTRATO.md"
version: "1.1"
status: "active"
owner: "PM"
last_updated: "2026-02-26"
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
- evidencia de memoria diaria valida registrada no artifact do epico.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F3-02-01 - Validar MEMORY.md e nota diaria YYYY-MM-DD
**User story**  
Como operador, quero garantir presenca dos arquivos canonicos de memoria para manter continuidade operacional.

**Plano TDD**
1. `Red`: simular ausencia de `MEMORY.md` ou da nota diaria e executar `make eval-runtime`.
2. `Green`: restaurar `workspaces/main/MEMORY.md` e `workspaces/main/memory/YYYY-MM-DD.md`.
3. `Refactor`: rerodar `make eval-runtime` para confirmar baseline.

**Criterios de aceitacao**
- Given arquivo canonico de memoria ausente, When `make eval-runtime` roda, Then o gate falha.
- Given memoria canonica presente, When `make eval-runtime` roda, Then nao ha falha por ausencia de arquivo.

### ISSUE-F3-02-02 - Validar header e secoes obrigatorias da nota diaria
**User story**  
Como operador, quero padrao unico de nota diaria para facilitar leitura, auditoria e validacao automatica.

**Plano TDD**
1. `Red`: quebrar header ou remover secao obrigatoria e executar `make eval-runtime`.
2. `Green`: restaurar formato `# YYYY-MM-DD` e secoes obrigatorias.
3. `Refactor`: rerodar `make eval-runtime` para validar consistencia.

**Criterios de aceitacao**
- Given header invalido ou secao obrigatoria ausente, When `make eval-runtime` roda, Then o gate falha.
- Given header e secoes obrigatorias corretas, When `make eval-runtime` roda, Then a nota passa na verificacao estrutural.

### ISSUE-F3-02-03 - Validar bullet minimo em Key Events Decisions Made Facts Extracted
**User story**  
Como operador, quero garantir conteudo minimo util por secao para evitar nota diaria vazia.

**Plano TDD**
1. `Red`: manter secao obrigatoria sem bullet e executar `make eval-runtime`.
2. `Green`: adicionar pelo menos um bullet por secao obrigatoria.
3. `Refactor`: rerodar `make eval-runtime` e registrar evidencia.

**Criterios de aceitacao**
- Given secao obrigatoria sem bullet, When `make eval-runtime` roda, Then o gate falha.
- Given todas as secoes obrigatorias com ao menos um bullet, When `make eval-runtime` roda, Then retorna `eval-runtime-contracts: PASS`.

## Artifact Minimo do Epico
- registrar resumo em `artifacts/phase-f3/epic-f3-02-memory-contract.md` com:
  - status de `MEMORY.md` e nota diaria;
  - conformidade de header/secoes/bullets;
  - resultado final de `make eval-runtime`.

## Resultado desta Rodada
- `make eval-runtime` final: `PASS` (`eval-runtime-contracts: PASS`).
- evidencias por issue publicadas:
  - `artifacts/phase-f3/epic-f3-02-issue-01-memory-daily-files.md`;
  - `artifacts/phase-f3/epic-f3-02-issue-02-daily-header-sections.md`;
  - `artifacts/phase-f3/epic-f3-02-issue-03-daily-bullet-minimum.md`.
- evidencia consolidada do epico:
  - `artifacts/phase-f3/epic-f3-02-memory-contract.md`.
- conclusao: `EPIC-F3-02` concluido no escopo documental/tdd desta rodada.

## Dependencias
- [Workspace Memory Canonico](../../../../workspaces/main/MEMORY.md)
- [Workspace Daily Memory](../../../../workspaces/main/memory/2026-02-24.md)
- [ARC Heartbeat](../../../../ARC/ARC-HEARTBEAT.md)
- [PRD Master](../../../../PRD/PRD-MASTER.md)
- [Eval Runtime Contracts Script](../../../../scripts/ci/eval_runtime_contracts.sh)
