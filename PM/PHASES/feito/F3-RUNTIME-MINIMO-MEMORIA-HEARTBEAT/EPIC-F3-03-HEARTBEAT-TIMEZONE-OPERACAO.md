---
doc_id: "EPIC-F3-03-HEARTBEAT-TIMEZONE-OPERACAO.md"
version: "1.2"
status: "active"
owner: "PM"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-015", "RFC-030", "RFC-040", "RFC-050", "RFC-060"]
---

# EPIC-F3-03 Heartbeat timezone e operacao critica

## Objetivo
Validar a coerencia operacional do heartbeat baseline, timezone canonico e regras criticas de seguranca/risco verificadas no gate de runtime.

## Resultado de Negocio Mensuravel
- operador trabalha com cadencia previsivel de heartbeat e extracao noturna.
- regras criticas de canal e aprovacao financeira permanecem ativas sem drift.

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- `make eval-runtime` executado com sucesso.
- evidencias de heartbeat/timezone e regras criticas registradas no artifact do epico.
- todas as issues do epico com DoR completo (`owner`, `estimate_hours`, `estimate_points`, `risk_class`, `risk_tier`, `dependencies`, `required_inputs`).

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F3-03-01 - Validar baseline de 15 minutos em docs canonicos
**User story**
Como operador, quero baseline unico de heartbeat para evitar comportamento operacional divergente.

**Metadados DoR (obrigatorio)**
- owner: `Tech Lead`
- estimate_hours: `8`
- estimate_points: `5`
- risk_class: `alto`
- risk_tier: `R2`
- dependencies:
  - `ARC/ARC-HEARTBEAT.md`
  - `workspaces/main/HEARTBEAT.md`
  - `scripts/ci/eval_runtime_contracts.sh`
  - `ARC/schemas/ops_autonomy_contract.schema.json`
- required_inputs:
  - baseline canonico em ARC/workspace
  - fixture de baseline divergente
  - output de `make eval-runtime`

**Plano TDD**
1. `Red`: introduzir divergencia de baseline em documento canonico e executar `make eval-runtime`.
2. `Green`: restaurar baseline oficial de 15 minutos em todos os pontos exigidos.
3. `Refactor`: rerodar `make eval-runtime` para confirmar consistencia.

**Criterios de aceitacao**
- Given baseline divergente, When `make eval-runtime` roda, Then o gate falha com mensagem assertiva do campo divergente.
- Given baseline alinhado em 15 minutos, When `make eval-runtime` roda, Then a verificacao passa.
- Given `stalled_threshold_checks != 2` no contrato de autonomia, When validar runtime, Then o gate falha explicitamente.

**Checklist QA (DoD da issue)**
- executar `Red-A/Red-B/Green/Refactor` e anexar logs assertivos.
- validar cobertura explicita de `ops_autonomy_contract` no artifact.

### ISSUE-F3-03-02 - Validar America Sao_Paulo e nightly extraction as 23:00
**User story**
Como operador, quero timezone e horario noturno padronizados para manter ciclo diario consistente.

**Metadados DoR (obrigatorio)**
- owner: `PO`
- estimate_hours: `4`
- estimate_points: `2`
- risk_class: `alto`
- risk_tier: `R2`
- dependencies:
  - `ARC/ARC-HEARTBEAT.md`
  - `workspaces/main/HEARTBEAT.md`
  - `ARC/schemas/nightly_memory_cycle.schema.json`
  - `scripts/ci/eval_runtime_contracts.sh`
- required_inputs:
  - cron canonico da extracao noturna
  - timezone canonico `America/Sao_Paulo`
  - fixture de horario divergente

**Plano TDD**
1. `Red`: simular timezone ou horario noturno divergente e executar `make eval-runtime`.
2. `Green`: restaurar `America/Sao_Paulo` e `nightly-extraction` as 23:00.
3. `Refactor`: rerodar `make eval-runtime` e registrar evidencia de alinhamento.

**Criterios de aceitacao**
- Given timezone/horario divergente, When `make eval-runtime` roda, Then o gate falha com assert explicito.
- Given timezone `America/Sao_Paulo` e ciclo noturno as 23:00 alinhados, When `make eval-runtime` roda, Then retorna `PASS`.
- Given alteracao do ciclo noturno, When issue for atualizada, Then risco/dependencias/estimativa devem ser revisados.

**Checklist QA (DoD da issue)**
- executar `Red-A/Red-B/Green/Refactor`.
- anexar log com `actual_assert_message` por cenario.

### ISSUE-F3-03-03 - Validar coerencia de regras criticas de canal e side effect financeiro
**User story**
Como operador, quero garantir que regras criticas de seguranca e aprovacao financeira nao sofram regressao no runtime.

**Metadados DoR (obrigatorio)**
- owner: `Compliance`
- estimate_hours: `12`
- estimate_points: `8`
- risk_class: `alto`
- risk_tier: `R3`
- dependencies:
  - `PRD/PRD-MASTER.md`
  - `SEC/SEC-POLICY.md`
  - `PM/DECISION-PROTOCOL.md`
  - `VERTICALS/TRADING/TRADING-PRD.md`
  - `VERTICALS/TRADING/TRADING-RISK-RULES.md`
  - `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`
  - `scripts/ci/eval_runtime_contracts.sh`
- required_inputs:
  - contrato `approval_policy` vigente
  - payloads simulados de execucao (invalido/valido)
  - referencia de trilha com `trace_id`

**Plano TDD**
1. `Red-A`: validar payload simulado com `input_channel=email` e sem confirmacao em canal confiavel; deve bloquear.
2. `Red-B`: validar payload simulado com `financial_side_effect=true` e `explicit_human_approval=false`; deve bloquear.
3. `Green`: validar payload simulado com canal confiavel + aprovacao explicita + `trace_id`; deve passar.
4. `Refactor`: rerodar `make eval-runtime` para garantir estabilidade do enforcement.

**Criterios de aceitacao**
- Given instrucao por email sem confirmacao em canal confiavel, When tentativa de execucao ocorrer, Then bloqueio deterministico com codigo assertivo.
- Given side effect financeiro sem aprovacao humana explicita, When tentativa ocorrer, Then bloqueio deterministico com codigo assertivo.
- Given aprovacao explicita em canal confiavel, When execucao ocorrer, Then fluxo permitido com rastreabilidade por `trace_id`.

**Checklist QA (DoD da issue)**
- executar cenarios simulados Red-A/Red-B/Green no gate.
- validar mensagens assertivas e registrar no artifact.
- confirmar `make eval-runtime` em `PASS` apos os cenarios.

## Artifact Minimo do Epico
- registrar resumo em `artifacts/phase-f3/epic-f3-03-heartbeat-timezone-operation.md` com:
  - status de baseline heartbeat e timezone;
  - status das regras criticas de canal/aprovacao;
  - resultado final de `make eval-runtime`;
  - decisao de fase (`promote|hold`) com justificativa.

## Resultado desta Rodada (Pos-Audit)
- escopo documental atualizado com contrato DoR/DoD nas 3 issues.
- `ISSUE-F3-03-03` redefinida para enforcement simulado executavel no gate.
- conclusao: `EPIC-F3-03` pronto para reauditoria de cobertura F3.

## Dependencias
- [ARC Heartbeat](../../../../ARC/ARC-HEARTBEAT.md)
- [Workspace Heartbeat](../../../../workspaces/main/HEARTBEAT.md)
- [PRD Master](../../../../PRD/PRD-MASTER.md)
- [Security Policy](../../../../SEC/SEC-POLICY.md)
- [Decision Protocol](../../../../PM/DECISION-PROTOCOL.md)
- [Trading PRD](../../../../VERTICALS/TRADING/TRADING-PRD.md)
- [Trading Risk Rules](../../../../VERTICALS/TRADING/TRADING-RISK-RULES.md)
- [Trading Enablement Criteria](../../../../VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md)
