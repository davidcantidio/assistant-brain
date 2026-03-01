---
doc_id: "SCRUM-GOV.md"
version: "1.1"
status: "active"
owner: "PM"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-040", "RFC-050"]
---

# Scrum Governance

## Objetivo
Definir a cadeia canonica `PRD -> Fases -> Epicos -> Issues -> Microtasks`, com sprint operando como janela de capacidade e priorizacao.

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
2. decompor em fases com gates e criterios objetivos.
3. decompor fases em epicos com objetivo e metrica.
4. decompor epicos em issues auditaveis.
5. decompor issues em microtasks atomicas e verificaveis.
6. planejar sprint como recorte de capacidade, sem substituir a cadeia estrutural.

## Definition of Done
- PRD: escopo, risco, KPI e links normativos.
- Fase: gate de saida e evidencia minima definidos.
- Epico: resultado de negocio mensuravel + criterios de aceite.
- Issue: entrega unitaria auditavel com risco e criterios verificaveis.
- Microtask: output tipado, validacao deterministica e trilha de execucao.
- Sprint: compromisso de capacidade, sem redefinir hierarquia de planejamento.

## No Jira Inflation
- sem tarefa gigante sem quebra.
- sem usar sprint como camada estrutural entre epico e issue.
- sem datas inventadas para "caber no plano".
- sem capacidade ficticia para aumentar output.
- sem epico sem DoD e owner.

## Links Relacionados
- [Sprint Limits](./SPRINT-LIMITS.md)
- [Work Order Spec](./WORK-ORDER-SPEC.md)
- [PRD Master](../PRD/PRD-MASTER.md)
