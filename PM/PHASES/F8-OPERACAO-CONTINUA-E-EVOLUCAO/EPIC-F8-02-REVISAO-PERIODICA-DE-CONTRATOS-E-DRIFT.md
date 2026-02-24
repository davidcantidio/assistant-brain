---
doc_id: "EPIC-F8-02-REVISAO-PERIODICA-DE-CONTRATOS-E-DRIFT.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-02-24"
rfc_refs: ["RFC-001", "RFC-015", "RFC-030", "RFC-050", "RFC-060"]
---

# EPIC-F8-02 Revisao periodica de contratos e drift

## Objetivo
Identificar e tratar drift normativo/contratual de forma recorrente para preservar coerencia entre runtime, integracoes, trading e seguranca.

## Resultado de Negocio Mensuravel
- drifts criticos passam a ter detecao recorrente e tratamento rastreavel.
- promocao semanal fica condicionada ao fechamento efetivo de pendencias criticas.

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- `make eval-gates` executado com sucesso no ciclo semanal.
- revisao semanal sem drift critico pendente sem owner/prazo.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F8-02-01 - Revisar contratos criticos e registrar conformidade
**User story**  
Como operador, quero revisar contratos criticos periodicamente para detectar incoerencias antes de virarem incidente.

**Plano TDD**
1. `Red`: executar ciclo semanal sem revisao explicita de contratos criticos.
2. `Green`: revisar contratos de runtime, integracoes, trading e seguranca e registrar conformidade.
3. `Refactor`: padronizar formato de registro para comparacao semanal.

**Criterios de aceitacao**
- Given revisao contratual ausente, When fechamento semanal ocorre, Then resultado deve ser `hold`.
- Given revisao contratual concluida com evidencias, When fechamento semanal ocorre, Then item de conformidade fica `pass`.

### ISSUE-F8-02-02 - Abrir backlog de remediacao para cada drift encontrado com owner e prazo
**User story**  
Como operador, quero que cada drift detectado tenha dono e prazo para evitar pendencia cronica sem acao.

**Plano TDD**
1. `Red`: registrar drift sem owner/prazo.
2. `Green`: abrir backlog de remediacao com owner, prazo e referencia de evidencia.
3. `Refactor`: agrupar drifts por severidade e impacto no gate semanal.

**Criterios de aceitacao**
- Given drift sem owner ou prazo, When revisao semanal ocorre, Then resultado deve ser `hold`.
- Given drifts com owner/prazo definidos, When revisao semanal ocorre, Then backlog de remediacao fica conforme.

### ISSUE-F8-02-03 - Validar fechamento de drifts da semana anterior antes de nova promocao
**User story**  
Como operador, quero validar fechamento dos drifts anteriores para evitar acumulacao de risco residual.

**Plano TDD**
1. `Red`: permitir promocao com drift critico herdado da semana anterior.
2. `Green`: bloquear promocao ate fechamento ou excecao formal de risco.
3. `Refactor`: registrar status de fechamento no relatorio da semana atual.

**Criterios de aceitacao**
- Given drift critico anterior aberto, When promocao semanal e avaliada, Then resultado deve ser `hold`.
- Given drifts criticos anteriores fechados, When promocao semanal e avaliada, Then item de continuidade fica `pass`.

## Artifact Minimo do Epico
- registrar revisao em `artifacts/phase-f8/contract-review/<week_id>.md` com:
  - lista de contratos revisados;
  - drifts detectados por severidade;
  - owner/prazo por drift;
  - status de fechamento da semana anterior.

## Dependencias
- [PRD Master](../../../PRD/PRD-MASTER.md)
- [Integrations README](../../../INTEGRATIONS/README.md)
- [Trading Enablement Criteria](../../../VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md)
- [Security Policy](../../../SEC/SEC-POLICY.md)
- [System Health Thresholds](../../../EVALS/SYSTEM-HEALTH-THRESHOLDS.md)
