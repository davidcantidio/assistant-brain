---
doc_id: "EPIC-F7-03-S2-ESCALA-E-PROMOCAO.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-02-24"
rfc_refs: ["RFC-001", "RFC-010", "RFC-040", "RFC-050", "RFC-060"]
---

# EPIC-F7-03 S2 escala e promocao

## Objetivo
Formalizar criterios de promocao `S1 -> S2` e encerrar F7 com decisao de fase `promote|hold` baseada em evidencias auditaveis.

## Resultado de Negocio Mensuravel
- escala de capital/limite ocorre somente com historico minimo estavel e decisao formal.
- reduz risco de promover trading sem maturidade operacional comprovada.

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- `make eval-trading` executado com sucesso.
- checklist de pre-live sem item `fail`.
- decisao de fase registrada com evidencias (`promote|hold`).

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F7-03-01 - Validar criterios minimos de promocao para escala
**User story**  
Como operador, quero criterios minimos objetivos para promover `S1 -> S2` sem ambiguidade de risco.

**Plano TDD**
1. `Red`: considerar promocao sem cumprir janela minima e sem evidencia de estabilidade.
2. `Green`: exigir 30 dias em `S1`, zero `SEV-1/SEV-2`, sem violacao hard-risk e reconciliacao sem duplicidade.
3. `Refactor`: consolidar referencias de evidencias no artifact da fase.

**Criterios de aceitacao**
- Given criterio minimo de promocao nao atendido, When revisao de escala ocorre, Then resultado deve ser `hold`.
- Given todos os criterios minimos atendidos, When revisao de escala ocorre, Then promocao para `S2` pode ser avaliada.

### ISSUE-F7-03-02 - Validar obrigatoriedade de decision R3 para promocao com limites explicitos
**User story**  
Como operador, quero decisao formal `R3` para escalar risco com limites explicitos e rastreaveis.

**Plano TDD**
1. `Red`: permitir promocao para `S2` sem decision `R3`.
2. `Green`: exigir decision `R3` com limites explicitos de novo nivel.
3. `Refactor`: alinhar rastreabilidade da decisao com protocolo de governanca.

**Criterios de aceitacao**
- Given promocao sem decision `R3`, When revisao de fase ocorre, Then promocao deve ser bloqueada.
- Given decision `R3` com limites explicitos, When revisao de fase ocorre, Then criterio formal de decisao fica `pass`.

### ISSUE-F7-03-03 - Consolidar evidencias da fase em artifact unico e registrar decisao promote hold de F7 para F8
**User story**  
Como operador, quero artifact unico da fase para justificar claramente a decisao de promocao.

**Plano TDD**
1. `Red`: manter evidencias dispersas sem decisao final explicita.
2. `Green`: consolidar em `validation-summary.md` com status de gates, checklist e decisao de fase.
3. `Refactor`: validar links e coerencia documental com `make ci-quality`.

**Criterios de aceitacao**
- Given evidencia incompleta de fase, When revisao final e feita, Then resultado deve ser `hold`.
- Given evidencia completa com gate verde e checklist sem `fail`, When revisao final e feita, Then decisao pode ser `promote`.

## Artifact Minimo do Epico
- registrar resumo em `artifacts/phase-f7/validation-summary.md` com:
  - status de `make eval-trading`;
  - status dos epicos `EPIC-F7-01..EPIC-F7-03`;
  - `checklist_id` de pre-live;
  - decisao `promote|hold` e justificativa.

## Dependencias
- [Trading Enablement Criteria](../../../VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md)
- [Trading PRD](../../../VERTICALS/TRADING/TRADING-PRD.md)
- [Decision Protocol](../../../PM/DECISION-PROTOCOL.md)
- [Phase Usability Guide](../../../PRD/PHASE-USABILITY-GUIDE.md)
