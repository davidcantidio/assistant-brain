---
doc_id: "EPIC-F7-03-S2-ESCALA-E-PROMOCAO.md"
version: "1.1"
status: "done"
owner: "PM"
last_updated: "2026-03-01"
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
- checklist de pre-live revisado com estado real preservado.
- decisao de fase registrada com evidencias (`promote|hold`).

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F7-03-01 - Validar criterios minimos de promocao para escala
**User story**  
Como operador, quero criterios minimos objetivos para promover `S1 -> S2` sem ambiguidade de risco.

**Metadata da issue**
- **Owner**: `tech-lead-trading`
- **Estimativa**: `1d`
- **Dependencias**: `assistant-brain/artifacts/trading/pre_live_checklist/CHECKLIST-F7-02-S1-20260301-01.json`, `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`, `assistant-brain/artifacts/phase-f7/epic-f7-03-issue-01-s2-promotion-criteria-hold.md`
- **Mapped requirements**: `R10`
- **Prioridade**: `P0`
- **Checklist QA/Repro**:
  1. validar presenca literal de `30 dias`, `SEV-1/SEV-2`, violacao hard-risk e reconciliacao sem duplicidade;
  2. validar em `assistant-brain/artifacts/phase-f7/epic-f7-03-issue-01-s2-promotion-criteria-hold.md` que o resultado atual permanece `hold`;
  3. conferir o checklist canonico `CHECKLIST-F7-02-S1-20260301-01` para confirmar que os `fail` de `S1` ainda impedem escala;
  4. rodar `make eval-trading` e confirmar `PASS`.
- **Evidence refs**: `assistant-brain/VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md:156-163`, `assistant-brain/artifacts/phase-f7/epic-f7-03-issue-01-s2-promotion-criteria-hold.md`

**Plano TDD**
1. `Red`: considerar promocao sem cumprir janela minima e sem evidencia de estabilidade.
2. `Green`: exigir 30 dias em `S1`, zero `SEV-1/SEV-2`, sem violacao hard-risk e reconciliacao sem duplicidade.
3. `Refactor`: consolidar referencias de evidencias no artifact da fase.

**Criterios de aceitacao**
- Given criterio minimo de promocao nao atendido, When revisao de escala ocorre, Then resultado deve ser `hold`.
- Given todos os criterios minimos atendidos, When revisao de escala ocorre, Then promocao para `S2` pode ser avaliada.

### ISSUE-F7-03-02 - Validar obrigatoriedade de decision R3 para promocao com limites explicitos
**User story**  
Como operador, quero decisao formal `R3` para escalar risco com limites explicitos e rastreaveis, sem confundir a `decision_id` de readiness de `S1` com a decisao de promocao `S1 -> S2`.

**Metadata da issue**
- **Owner**: `security-lead + tech-lead-trading`
- **Estimativa**: `1d`
- **Dependencias**: `PM/DECISION-PROTOCOL.md`, `assistant-brain/artifacts/trading/pre_live_checklist/CHECKLIST-F7-02-S1-20260301-01.json`, `assistant-brain/artifacts/phase-f7/epic-f7-03-issue-02-s2-r3-decision-required-hold.md`
- **Mapped requirements**: `R11`, `R13`
- **Prioridade**: `P0`
- **Checklist QA/Repro**:
  1. validar que `decision_id=DEC-F7-02-S1-20260301-01` do checklist de `S1` nao substitui a decisao de promocao `S1 -> S2`;
  2. validar que nao existe decisao `R3` com limites explicitos do novo nivel em `artifacts/`, `PM/` e `PRD/`;
  3. validar que a escala para `S2` nao remove aprovacao humana por ordem;
  4. rodar `make eval-trading` e confirmar `PASS` com resultado operacional ainda em `hold`.
- **Evidence refs**: `assistant-brain/PM/DECISION-PROTOCOL.md:197-204`, `assistant-brain/artifacts/phase-f7/epic-f7-03-issue-02-s2-r3-decision-required-hold.md`

**Plano TDD**
1. `Red`: permitir promocao para `S2` sem decision `R3`.
2. `Green`: exigir decision `R3` com limites explicitos de novo nivel.
3. `Refactor`: alinhar rastreabilidade da decisao com protocolo de governanca.

**Criterios de aceitacao**
- Given promocao sem decision `R3`, When revisao de fase ocorre, Then promocao deve ser bloqueada.
- Given `decision_id` de readiness de `S1`, When revisao de fase ocorre, Then ela nao substitui a decision `R3` de promocao para `S2`.
- Given escala para `S2`, When revisao de fase ocorre, Then aprovacao humana por ordem permanece mandatória.
- Given decision `R3` com limites explicitos, When revisao de fase ocorre, Then criterio formal de decisao fica `pass`.

### ISSUE-F7-03-03 - Consolidar evidencias da fase em artifact unico e registrar decisao promote hold de F7 para F8
**User story**  
Como operador, quero artifact unico da fase para justificar claramente a decisao de promocao.

**Metadata da issue**
- **Owner**: `pm + tech-lead-trading`
- **Estimativa**: `1d`
- **Dependencias**: `assistant-brain/artifacts/phase-f7/validation-summary.md`, `assistant-brain/artifacts/trading/pre_live_checklist/CHECKLIST-F7-02-S1-20260301-01.json`, `scripts/ci/check_quality.sh`
- **Mapped requirements**: `R3`, `R12`
- **Prioridade**: `P0`
- **Checklist QA/Repro**:
  1. rodar `make eval-trading` e confirmar `eval-trading: PASS`;
  2. validar existencia de `assistant-brain/artifacts/phase-f7/validation-summary.md`;
  3. validar referencia ao checklist `CHECKLIST-F7-02-S1-20260301-01` no resumo unico da fase;
  4. validar decisao final `F7 -> F8: hold` com justificativa explicita.
- **Evidence refs**: `assistant-brain/PM/PHASES/feito/F7-TRADING-POR-ESTAGIOS/EPICS.md:12-37`, `assistant-brain/PRD/PHASE-USABILITY-GUIDE.md:39-57`

**Plano TDD**
1. `Red`: manter evidencias dispersas sem decisao final explicita.
2. `Green`: consolidar em `validation-summary.md` com status de gates, checklist e decisao de fase.
3. `Refactor`: validar links e coerencia documental com `make ci-quality`.

**Criterios de aceitacao**
- Given evidencia incompleta de fase, When revisao final e feita, Then resultado deve ser `hold`.
- Given evidencia completa com gate verde e checklist revisado, When revisao final e feita, Then decisao `promote|hold` fica registrada com justificativa unica de fase.

## Artifact Minimo do Epico
- registrar resumo em `artifacts/phase-f7/validation-summary.md` com:
  - status de `make eval-trading`;
  - status dos epicos `EPIC-F7-01..EPIC-F7-03`;
  - `checklist_id` de pre-live;
  - decisao `promote|hold` e justificativa.

## Resultado desta Rodada
- `make eval-trading` final: `PASS` (`eval-trading: PASS`).
- evidencias por issue publicadas:
  - `artifacts/phase-f7/epic-f7-03-issue-01-s2-promotion-criteria-hold.md`;
  - `artifacts/phase-f7/epic-f7-03-issue-02-s2-r3-decision-required-hold.md`;
  - `artifacts/phase-f7/epic-f7-03-issue-03-phase-evidence-promote-hold.md`.
- evidencias consolidadas:
  - `artifacts/phase-f7/validation-summary.md`;
  - `artifacts/phase-f7/epic-f7-03-s2-escala-e-promocao.md`.
- decisao final de fase (`F7 -> F8`): `hold`.
- justificativa:
  - checklist `CHECKLIST-F7-02-S1-20260301-01` ainda tem `credentials_live_no_withdraw=fail`, `hitl_channel_ready=fail`, `backup_operator_enabled=fail`, `explicit_order_approval_active=fail`;
  - nao existe decisao `R3` de promocao `S1 -> S2` com limites explicitos.
- conclusao: `EPIC-F7-03` concluido no escopo documental/tdd desta rodada.
- remediacao de auditoria aplicada:
  - issue metadata obrigatoria em todas as 9 issues da F7;
  - `S0` quantificado com `4 semanas` e `zero SEV-1/SEV-2`;
  - `ISSUE-F7-02-03` expandida para a matriz completa de 8 itens;
  - artifact unico de fase publicado.

## Dependencias
- [Trading Enablement Criteria](../../../../VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md)
- [Trading PRD](../../../../VERTICALS/TRADING/TRADING-PRD.md)
- [Decision Protocol](../../../../PM/DECISION-PROTOCOL.md)
- [Phase Usability Guide](../../../../PRD/PHASE-USABILITY-GUIDE.md)
