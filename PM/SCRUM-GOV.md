---
doc_id: "SCRUM-GOV.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-040", "RFC-050"]
---

# Scrum Governance

## Objetivo
Definir a cadeia PRD -> epicos -> sprints -> tasks com disciplina de escopo, DoD e evidencia.

## Escopo
Inclui:
- fluxo de decomposicao de trabalho
- DoD por tipo de item
- regras anti "jira inflation"

Exclui:
- planejamento sem limite de capacidade
- backlog sem criterio mensuravel

## Regras Normativas
- [RFC-040] MUST aplicar limites de sprint e tamanho de tarefa.
- [RFC-040] MUST converter violacao de limite em decision de override.
- [RFC-050] MUST anexar metrica e evidencias por item concluido.

## Fluxo de Planejamento
1. PRD aprovado (cloud + humano).
2. decompor em epicos com objetivo e metrica.
3. decompor epicos em sprint com capacidade real.
4. decompor sprint em tasks pequenas e verificaveis.

## Definition of Done
- PRD: escopo, risco, KPI e links normativos.
- Epico: resultado de negocio mensuravel + criterios de aceite.
- Sprint: compromisso de entrega dentro de limite.
- Task: artifact auditavel + validacao deterministica.

## No Jira Inflation
- sem tarefa gigante sem quebra.
- sem datas inventadas para "caber no plano".
- sem capacidade ficticia para aumentar output.
- sem epico sem DoD e owner.

## Links Relacionados
- [Sprint Limits](./SPRINT-LIMITS.md)
- [Work Order Spec](./WORK-ORDER-SPEC.md)
- [PRD Master](../PRD/PRD-MASTER.md)
