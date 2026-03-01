---
doc_id: "EPIC-F8-03-GOVERNANCA-DE-EVOLUCAO-E-RELEASE.md"
version: "1.2"
status: "active"
owner: "PM"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-015", "RFC-040", "RFC-050", "RFC-060"]
---

# EPIC-F8-03 Governanca de evolucao e release

## Objetivo
Fechar cada ciclo semanal com decisao formal `promote|hold`, trilha de risco residual e plano de continuidade para evolucao sem regressao.

## Resultado de Negocio Mensuravel
- decisoes semanais de evolucao passam a ser explicitas, auditaveis e reproduziveis.
- risco residual e rollback ficam registrados antes de cada promocao.

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- trio de gates (`eval-gates`, `ci-quality`, `ci-security`) com `PASS` no ciclo semanal.
- decisao semanal registrada com `promote|hold` e justificativa.

## Contexto normativo desta rodada
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md`, `PRD/PHASE-USABILITY-GUIDE.md`, `PM/DECISION-PROTOCOL.md`, `EVALS/SYSTEM-HEALTH-THRESHOLDS.md` e `PRD/CHANGELOG.md`.
- a `F8` permanece em estado `planned` no planejamento da fase, sem novo enum de status.
- a ativacao prematura da `F8` MUST ser recuada documentalmente enquanto a decisao `F7 -> F8` permanecer `hold`.
- este epico consolida a trilha de release e auditoria da `F8`, mas NAO substitui a promocao formal entre fases.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F8-03-01 - Validar criterios de decisao semanal promote hold baseados no trio de gates drifts e decisao da fase anterior
**User story**  
Como operador, quero criterios objetivos de decisao semanal para evitar promocao por percepcao subjetiva.

**Plano TDD**
1. `Red`: considerar promocao sem validar gates, drifts e a decisao `F7 -> F8`.
2. `Green`: decidir `promote|hold` com base no trio de gates, status de drifts criticos e `prior_phase_decision`.
3. `Refactor`: padronizar criterio de decisao no sumario semanal com recuo formal da ativacao da `F8`.

**Criterios de aceitacao**
- Given qualquer gate em `FAIL`, drift critico aberto ou `prior_phase_decision != promote`, When decisao semanal e tomada, Then resultado deve ser `hold`.
- Given trio de gates em `PASS`, sem drift critico pendente e `prior_phase_decision=promote`, When decisao semanal e tomada, Then resultado pode ser `promote`.

### ISSUE-F8-03-02 - Registrar risco residual rollback e acoes da proxima semana
**User story**  
Como operador, quero registrar risco residual e rollback para manter continuidade segura entre ciclos semanais.

**Plano TDD**
1. `Red`: registrar decisao semanal sem risco residual/rollback.
2. `Green`: incluir risco residual, estrategia de rollback e acoes da semana seguinte.
3. `Refactor`: alinhar plano semanal com backlog de remediacao de drift e baseline vigente da `F7/F8-02`.

**Criterios de aceitacao**
- Given decisao semanal sem risco residual ou rollback, When revisao de release ocorre, Then resultado deve ser `hold`.
- Given decisao semanal com risco residual/rollback/next actions, When revisao de release ocorre, Then criterio de continuidade fica `pass`.

### ISSUE-F8-03-03 - Consolidar sumario executivo semanal para auditoria e continuidade operacional
**User story**  
Como operador, quero um sumario executivo semanal para auditoria rapida e handoff sem lacunas.

**Plano TDD**
1. `Red`: manter evidencias semanais dispersas em multiplos locais.
2. `Green`: consolidar sumario unico com status de gates, drifts, decisao e proximos passos.
3. `Refactor`: validar coerencia de links e referencias com `make ci-quality`.

**Criterios de aceitacao**
- Given sumario semanal ausente, When auditoria semanal ocorre, Then resultado deve ser `hold`.
- Given sumario semanal completo e coerente, When auditoria semanal ocorre, Then continuidade operacional fica rastreavel.

## Artifact Minimo do Epico
- registrar sumario em `artifacts/phase-f8/validation-summary-<week_id>.md` com:
  - status de `eval-gates`, `ci-quality`, `ci-security`;
  - status dos epicos `EPIC-F8-01..EPIC-F8-04`;
  - decisao `promote|hold` e justificativa;
  - risco residual, rollback e `next_actions`.

## Resultado desta Rodada
- `make eval-gates` final: `PASS`.
- `make phase-f8-weekly-governance` final: `hold`.
- `make ci-quality` final: `PASS`.
- `make ci-security` final: `PASS`.
- evidencias por issue publicadas:
  - `artifacts/phase-f8/epic-f8-03-issue-01-weekly-decision-criteria.md`;
  - `artifacts/phase-f8/epic-f8-03-issue-02-residual-risk-rollback.md`;
  - `artifacts/phase-f8/epic-f8-03-issue-03-executive-summary-audit.md`.
- evidencias consolidadas:
  - `artifacts/phase-f8/weekly-governance/2026-W09.md`;
  - `artifacts/phase-f8/validation-summary-2026-W09.md`;
  - `artifacts/phase-f8/epic-f8-03-governanca-evolucao-release.md`.
- decisao semanal atual: `hold`.
- justificativa:
  - `critical_drifts_open=1`;
  - `prior_phase_decision=hold`;
  - `phase_transition_status=blocked`.
- conclusao: `EPIC-F8-03` concluido no escopo documental/tdd desta rodada, sem promover automaticamente a fase `F8`.

## Dependencias
- [PRD Master](../../../../PRD/PRD-MASTER.md)
- [Decision Protocol](../../../../PM/DECISION-PROTOCOL.md)
- [Roadmap](../../../../PRD/ROADMAP.md)
- [Phase Usability Guide](../../../../PRD/PHASE-USABILITY-GUIDE.md)
- [System Health Thresholds](../../../../EVALS/SYSTEM-HEALTH-THRESHOLDS.md)
