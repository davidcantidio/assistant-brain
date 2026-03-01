---
doc_id: "EPIC-F9-02-CADEIA-PLANEJAMENTO-E-GOVERNANCA-CODIGO.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-010", "RFC-040", "RFC-050", "RFC-060"]
---

# EPIC-F9-02 Cadeia de planejamento e governanca de codigo

## Objetivo
Convergir a cadeia estrutural de planejamento e reclassificar o pipeline multi-modelo de codigo para evitar sobreposicao normativa enquanto governanca de PR/branch/ownership nao estiver completamente harmonizada.

## Resultado de Negocio Mensuravel
- cadeia de planejamento unica e explicitamente canonica.
- pipeline multi-modelo sai de status normativo pleno para proposta controlada.
- contrato de governanca de PR/branch/ownership fica explicitado com criterio de adocao.

## Definition of Done (Scrum)
- todas as issues do epic em estado `Done`.
- cadeia `PRD -> Fases -> Epicos -> Issues -> Microtasks` publicada sem ambiguidade operacional.
- dependencia de governance de PR formalizada antes de qualquer promocao normativa de pipeline.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F9-02-01 - Alinhar cadeia canonica PRD -> Fases -> Epicos -> Issues -> Microtasks
**User story**
Como PM, quero cadeia de planejamento unica para reduzir perda de rastreabilidade entre backlog, execucao e auditoria.

**Metadata da issue**
- **Owner**: `pm`
- **Estimativa**: `1d`
- **Dependencias**: `PRD/ROADMAP.md`, `PRD/PRD-MASTER.md`, `PM/SCRUM-GOV.md`
- **Mapped requirements**: `R4`
- **Prioridade**: `P0`
- **Checklist QA/Repro**:
  1. validar que `SCRUM-GOV` nao conflita com a cadeia canonica do PRD;
  2. manter sprint como capacidade e nao como estrutura concorrente de backlog;
  3. validar consistencia terminologica entre `Issue` e `Microtask` nos contratos.
- **Evidence refs**: `assistant-brain/artifacts/architecture/2026-03-01-architectural-consistency-audit.md:34-36`, `assistant-brain/artifacts/architecture/2026-03-01-architectural-consistency-audit.md:90-99`

**Plano TDD**
1. `Red`: manter cadeias concorrentes (`epico/sprint/task` vs `issue/microtask`).
2. `Green`: definir cadeia unica e escopo de sprint como capacidade.
3. `Refactor`: padronizar nomenclatura entre PRD e PM.

**Criterios de aceitacao**
- Given documento de governanca scrum, When cadeia for revisada, Then o fluxo deve refletir a cadeia canonica do PRD.
- Given item de planejamento, When decomposicao for feita, Then a trilha deve preservar fase/epico/issue/microtask sem perda de rastreabilidade.

### ISSUE-F9-02-02 - Rebaixar pipeline M30 -> M14-Code -> Codex 5 para proposta ate harmonizacao
**User story**
Como architecture lead, quero tratar o pipeline multi-modelo como proposta enquanto contratos transversais nao forem atualizados no mesmo ciclo.

**Metadata da issue**
- **Owner**: `pm + architecture`
- **Estimativa**: `1d`
- **Dependencias**: `PRD/PRD-MASTER.md`, `PRD/CHANGELOG.md`, `ARC/ARC-MODEL-ROUTING.md`, `DEV/DEV-TECH-LEAD-SPEC.md`, `PM/DECISION-PROTOCOL.md`
- **Mapped requirements**: `R5`
- **Prioridade**: `P0`
- **Checklist QA/Repro**:
  1. identificar trechos onde o pipeline esta normativo sem harmonizacao transversal;
  2. marcar o bloco como proposta/RFC com condicoes de promocao;
  3. referenciar explicitamente os contratos dependentes para promocao de proposta.
- **Evidence refs**: `assistant-brain/artifacts/architecture/2026-03-01-architectural-consistency-audit.md:37-39`, `assistant-brain/artifacts/architecture/2026-03-01-architectural-consistency-audit.md:53-59`

**Plano TDD**
1. `Red`: manter pipeline como norma ativa sem enforcement completo.
2. `Green`: reclassificar bloco como proposta condicionada.
3. `Refactor`: explicitar gatilhos de promocao da proposta.

**Criterios de aceitacao**
- Given pipeline sem contratos transversais harmonizados, When status for avaliado, Then classificacao deve permanecer `proposta`.
- Given harmonizacao completa dos contratos dependentes, When revisao formal ocorrer, Then pipeline pode ser promovido com decision registrada.

### ISSUE-F9-02-03 - Formalizar governanca de PR/branch/ownership como contrato explicito
**User story**
Como engineering lead, quero contrato explicito de governanca de PR/branch/ownership para evitar regras implicitas nao enforceaveis.

**Metadata da issue**
- **Owner**: `tech-lead + pm`
- **Estimativa**: `1d`
- **Dependencias**: `.github/CODEOWNERS`, `DEV/DEV-CI-RULES.md`, `.github/workflows/*`, `PRD/PRD-MASTER.md`
- **Mapped requirements**: `R6`
- **Prioridade**: `P1`
- **Checklist QA/Repro**:
  1. documentar branch policy canonica (incluindo necessidade ou nao de `staging`);
  2. documentar ownership e gate de merge com criterio de excecao por decision;
  3. definir criterio de conformidade para policy de PR no pacote PM.
- **Evidence refs**: `assistant-brain/artifacts/architecture/2026-03-01-architectural-consistency-audit.md:40-41`, `assistant-brain/artifacts/architecture/2026-03-01-architectural-consistency-audit.md:60-66`

**Plano TDD**
1. `Red`: manter policy de branch/ownership implicita e parcial.
2. `Green`: consolidar contrato explicito com fonte de verdade versionada.
3. `Refactor`: alinhar contrato com gates de CI e trilha de decisao.

**Criterios de aceitacao**
- Given alteracao de codigo por PR, When governanca for avaliada, Then branch policy e ownership devem estar explicitamente documentados.
- Given excecao de policy, When aplicada, Then deve existir decision referenciada e auditavel.

## Artifact Minimo do Epico
- publicar consolidado de convergencia em `PM/audit/F9-NORMALIZACAO-ARQUITETURAL-EPICS-ISSUES-AUDIT.json` com:
  - status de cobertura para `R4`, `R5`, `R6`;
  - riscos residuais de harmonizacao;
  - plano de acao com owner e due_days.

## Dependencias
- [PRD Master](../../../PRD/PRD-MASTER.md)
- [Roadmap](../../../PRD/ROADMAP.md)
- [Scrum Gov](../../SCRUM-GOV.md)
- [Architecture Audit](../../../artifacts/architecture/2026-03-01-architectural-consistency-audit.md)
