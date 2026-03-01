---
doc_id: "EPIC-F9-01-HIGIENE-PM-E-AUTORIDADE-NORMATIVA.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-010", "RFC-015", "RFC-040", "RFC-050"]
---

# EPIC-F9-01 Higiene PM e autoridade normativa

## Objetivo
Eliminar inconsistencias de path/rastreabilidade no pacote PM e fechar a ambiguidade de autoridade arquitetural, preservando historico e melhorando confiabilidade de auditoria.

## Resultado de Negocio Mensuravel
- `PM/audit/*` deixa de apontar para caminhos inexistentes de `F7` fora de `feito`.
- a governanca documental passa a explicitar uma fonte normativa unica para decisao arquitetural.
- o repositorio ganha secao permanente de auditoria arquitetural com criterio de encerramento objetivo.

## Definition of Done (Scrum)
- todas as issues do epic em estado `Done`.
- nenhuma referencia quebrada de `F7` em `PM/audit/*`.
- rastreabilidade da auditoria arquitetural publicada e validada no pacote PM.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F9-01-01 - Canonizar paths PM concluidos e corrigir links quebrados em PM/audits
**User story**
Como owner de governanca, quero referencias PM canonicamente resolviveis para reduzir falsos positivos e retrabalho de auditoria.

**Metadata da issue**
- **Owner**: `pm`
- **Estimativa**: `0.5d`
- **Dependencias**: `PM/audit/F7-TRADING-POR-ESTAGIOS-EPICS-ISSUES-AUDIT.json`, `PM/audit/fase-f1-epicos-issues-audit.json`, `PM/PHASES/feito/F7-TRADING-POR-ESTAGIOS/EPIC-F7-03-S2-ESCALA-E-PROMOCAO.md`
- **Mapped requirements**: `R1`
- **Prioridade**: `P0`
- **Checklist QA/Repro**:
  1. executar `bash scripts/ci/check_pm_audit_paths.sh` e validar `PASS`;
  2. validar que as referencias migradas apontam para `PM/PHASES/feito/F7-TRADING-POR-ESTAGIOS/*`;
  3. validar que os arquivos de auditoria continuam parseaveis apos a troca.
- **Evidence refs**: `assistant-brain/artifacts/architecture/2026-03-01-architectural-consistency-audit.md:31-66`, `assistant-brain/PM/audit/F7-TRADING-POR-ESTAGIOS-EPICS-ISSUES-AUDIT.json`, `assistant-brain/PM/audit/fase-f1-epicos-issues-audit.json`

**Plano TDD**
1. `Red`: manter referencias para `PM/PHASES/F7-...` inexistente.
2. `Green`: migrar todas as refs necessarias para `PM/PHASES/feito/F7-...`.
3. `Refactor`: validar consistencia de paths com checker dedicado em CI.

**Criterios de aceitacao**
- Given referencias antigas para `PM/PHASES/F7-...`, When auditoria PM roda, Then caminho deve ser canonicamente resolvivel em `feito`.
- Given repositorio com paths canonicos, When rastreabilidade for revisada, Then nao deve existir link quebrado nos arquivos auditados.

### ISSUE-F9-01-02 - Converter conflito de autoridade em regra explicita de governanca
**User story**
Como owner de arquitetura, quero uma regra explicita de autoridade para evitar governanca paralela entre PRD, Felix e contratos operacionais.

**Metadata da issue**
- **Owner**: `pm + architecture`
- **Estimativa**: `1d`
- **Dependencias**: `PRD/PRD-MASTER.md`, `META/DOCUMENT-HIERARCHY.md`, `README.md`, `workspaces/main/AGENTS.md`
- **Mapped requirements**: `R2`
- **Prioridade**: `P0`
- **Checklist QA/Repro**:
  1. revisar hierarquia vigente e identificar trecho com autoridade ambigua;
  2. publicar regra explicita: `PRD + SEC + ARC` como nucleo normativo;
  3. manter Felix como referencia conceitual com trilha de changelog/traceability.
- **Evidence refs**: `assistant-brain/artifacts/architecture/2026-03-01-architectural-consistency-audit.md:31-41`, `assistant-brain/artifacts/architecture/2026-03-01-architectural-consistency-audit.md:140-176`

**Plano TDD**
1. `Red`: manter autoridade dupla sem regra objetiva.
2. `Green`: declarar regra de precedencia unica e rastreavel.
3. `Refactor`: alinhar terminologia da regra com documentacao de fase.

**Criterios de aceitacao**
- Given conflito entre fonte externa e PRD, When regra de autoridade for aplicada, Then decisao normativa deve seguir precedencia explicita e auditavel.
- Given override conceitual vindo de Felix, When for aceito, Then deve existir trilha em issue + changelog + traceability.

### ISSUE-F9-01-03 - Criar secao permanente de auditoria arquitetural com criterio de encerramento
**User story**
Como PM, quero uma secao permanente de auditoria arquitetural para medir convergencia e fechar drift com criterio objetivo.

**Metadata da issue**
- **Owner**: `pm`
- **Estimativa**: `0.5d`
- **Dependencias**: `artifacts/architecture/2026-03-01-architectural-consistency-audit.md`, `PM/TRACEABILITY/ARCHITECTURE-AUDIT-COVERAGE.md`
- **Mapped requirements**: `R3`
- **Prioridade**: `P1`
- **Checklist QA/Repro**:
  1. publicar criterio de encerramento com indicadores objetivos;
  2. publicar metrica de convergencia arquitetural com formula e limites;
  3. mapear responsaveis por dominio de remediacao.
- **Evidence refs**: `assistant-brain/artifacts/architecture/2026-03-01-architectural-consistency-audit.md:168-182`, `assistant-brain/PM/TRACEABILITY/ARCHITECTURE-AUDIT-COVERAGE.md`

**Plano TDD**
1. `Red`: manter auditoria pontual sem criterio de encerramento.
2. `Green`: definir criterio permanente com score de convergencia.
3. `Refactor`: consolidar owner e ciclo de revisao no backlog da fase.

**Criterios de aceitacao**
- Given auditoria recorrente, When novo ciclo iniciar, Then criterio de encerramento deve estar explicito e mensuravel.
- Given conflito critico aberto, When score for calculado, Then resultado deve bloquear fechamento da auditoria.

## Artifact Minimo do Epico
- publicar consolidado em `PM/TRACEABILITY/ARCHITECTURE-AUDIT-COVERAGE.md` com:
  - conflitos e failure modes mapeados para issues F9;
  - status por item (`planned|in_progress|done`);
  - responsavel e prioridade de remediacao.

## Dependencias
- [Auditoria Arquitetural](../../../artifacts/architecture/2026-03-01-architectural-consistency-audit.md)
- [Decision Protocol](../../DECISION-PROTOCOL.md)
- [PRD Master](../../../PRD/PRD-MASTER.md)
