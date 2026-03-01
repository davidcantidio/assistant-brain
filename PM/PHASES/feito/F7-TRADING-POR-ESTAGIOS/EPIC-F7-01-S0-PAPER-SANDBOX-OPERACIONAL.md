---
doc_id: "EPIC-F7-01-S0-PAPER-SANDBOX-OPERACIONAL.md"
version: "1.2"
status: "done"
owner: "PM"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-010", "RFC-050", "RFC-060"]
---

# EPIC-F7-01 S0 paper sandbox operacional

## Objetivo
Consolidar `S0 - Paper/Sandbox` como etapa obrigatoria sem ordem real, com aprovacao humana explicita e evidencias minimas para habilitar avaliacao de `S1`.

## Resultado de Negocio Mensuravel
- trading permanece em risco controlado no estagio inicial sem exposicao financeira real.
- equipe possui trilha objetiva de estabilidade minima antes de avaliar micro-live.

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- `make eval-trading` executado com sucesso.
- evidencias de `S0` registradas no artifact do epico.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F7-01-01 - Validar regra S0 sem ordem real e estado TRADING_BLOCKED para tentativa live
**User story**  
Como operador, quero garantir que `S0` nao permita ordem real para evitar risco financeiro prematuro.

**Metadata da issue**
- **Owner**: `tech-lead-trading`
- **Estimativa**: `1d`
- **Dependencias**: `VERTICALS/TRADING/TRADING-PRD.md`, `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`, `scripts/ci/eval_trading.sh`
- **Mapped requirements**: `R2`, `R4`
- **Prioridade**: `P1`
- **Checklist QA/Repro**:
  1. simular tentativa de ordem live durante `S0`;
  2. rodar `make eval-trading` e confirmar `eval-trading: PASS`;
  3. validar em `assistant-brain/artifacts/phase-f7/epic-f7-01-issue-01-s0-paper-only-trading-blocked.md` que a tentativa live preserva `TRADING_BLOCKED`;
  4. validar que a evidencia registra bloqueio auditavel para a tentativa live.
- **Evidence refs**: `assistant-brain/VERTICALS/TRADING/TRADING-PRD.md:42-44`, `assistant-brain/VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md:58-61`

**Plano TDD**
1. `Red`: simular tentativa de ordem live durante `S0`.
2. `Green`: reforcar bloqueio `TRADING_BLOCKED` para qualquer tentativa fora do escopo paper/sandbox.
3. `Refactor`: rerodar `make eval-trading` e revisar rastreabilidade do bloqueio.

**Criterios de aceitacao**
- Given estagio `S0`, When tentativa de ordem real ocorre, Then o estado deve permanecer `TRADING_BLOCKED`.
- Given bloqueio ativo de ordem real, When `make eval-trading` roda, Then o gate nao reprova por bypass de estagio.

### ISSUE-F7-01-02 - Validar aprovacao humana explicita por ordem de entrada no S0
**User story**  
Como operador, quero aprovacao humana por ordem no `S0` para garantir controle total do risco operacional inicial.

**Metadata da issue**
- **Owner**: `security-lead`
- **Estimativa**: `1d`
- **Dependencias**: `PM/DECISION-PROTOCOL.md`, `VERTICALS/TRADING/TRADING-PRD.md`, `scripts/ci/eval_trading.sh`
- **Mapped requirements**: `R5`
- **Prioridade**: `P1`
- **Checklist QA/Repro**:
  1. validar que uma ordem de entrada sem aprovacao humana explicita por ordem resulta em bloqueio;
  2. validar que a evidencia por ordem esta registrada em `assistant-brain/artifacts/phase-f7/epic-f7-01-issue-02-s0-explicit-human-approval-per-order.md`;
  3. rodar `make eval-trading` e confirmar que a regra de aprovacao humana por ordem permanece conforme.
- **Evidence refs**: `assistant-brain/PM/DECISION-PROTOCOL.md:197-204`, `assistant-brain/VERTICALS/TRADING/TRADING-PRD.md:43`

**Plano TDD**
1. `Red`: considerar ordem de entrada sem aprovacao humana explicita.
2. `Green`: aplicar regra de aprovacao humana por ordem em `S0`.
3. `Refactor`: revisar alinhamento com `Decision Protocol` e criterios de trading.

**Criterios de aceitacao**
- Given ordem de entrada sem aprovacao humana, When revisao do estagio e executada, Then a operacao deve ser bloqueada.
- Given aprovacao humana explicita por ordem, When revisao do estagio e executada, Then o criterio de HITL em `S0` fica conforme e auditavel por ordem.

### ISSUE-F7-01-03 - Validar evidencias minimas de janela S0 e status operacional para habilitar avaliacao de S1
**User story**  
Como operador, quero evidencias minimas de estabilidade em `S0`, com janela minima: 4 semanas e zero `SEV-1/SEV-2`, para decidir com criterio se `S1` pode ser avaliado.

**Metadata da issue**
- **Owner**: `product-owner + tech-lead-trading`
- **Estimativa**: `2d`
- **Dependencias**: `VERTICALS/TRADING/TRADING-PRD.md`, `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`, `assistant-brain/artifacts/phase-f7/epic-f7-01-s0-summary.md`
- **Mapped requirements**: `R6`
- **Prioridade**: `P1`
- **Checklist QA/Repro**:
  1. validar presenca literal de `4 semanas` e `SEV-1/SEV-2` neste documento;
  2. validar em `assistant-brain/artifacts/phase-f7/epic-f7-01-issue-03-s0-window-evidence-s1-evaluation-ready.md` a consolidacao da janela minima de `S0`;
  3. validar em `assistant-brain/artifacts/phase-f7/epic-f7-01-s0-summary.md` que o desfecho permanece `hold` quando a evidencia for incompleta e `apto para avaliar S1` apenas com criterio completo.
- **Evidence refs**: `assistant-brain/VERTICALS/TRADING/TRADING-PRD.md:44`, `assistant-brain/VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md:60-61`

**Plano TDD**
1. `Red`: registrar janela `S0` sem evidencias minimas.
2. `Green`: consolidar evidencias de janela e status operacional conforme criterio.
3. `Refactor`: integrar evidencias ao artifact de fase.

**Criterios de aceitacao**
- Given evidencias insuficientes da janela `S0` ou ausencia de janela minima de 4 semanas e zero `SEV-1/SEV-2`, When gate de fase e revisado, Then resultado deve ser `hold`.
- Given evidencias minimas completas da janela `S0`, incluindo 4 semanas e zero `SEV-1/SEV-2`, When gate de fase e revisado, Then fase fica apta a avaliar `S1`.

## Artifact Minimo do Epico
- registrar resumo em `artifacts/phase-f7/epic-f7-01-s0-summary.md` com:
  - status do bloqueio `TRADING_BLOCKED` em `S0`;
  - evidencias de aprovacao humana por ordem;
  - resultado de `make eval-trading`.

## Resultado desta Rodada
- `make eval-trading` final: `PASS` (`eval-trading: PASS`).
- `make ci-quality` final: `PASS` (`quality-check: PASS`).
- `make eval-gates` final: `PASS` (`eval-gates: PASS`).
- evidencias por issue publicadas:
  - `artifacts/phase-f7/epic-f7-01-issue-01-s0-paper-only-trading-blocked.md`;
  - `artifacts/phase-f7/epic-f7-01-issue-02-s0-explicit-human-approval-per-order.md`;
  - `artifacts/phase-f7/epic-f7-01-issue-03-s0-window-evidence-s1-evaluation-ready.md`.
- evidencias consolidadas:
  - `artifacts/phase-f7/epic-f7-01-s0-summary.md`;
  - `artifacts/phase-f7/epic-f7-01-s0-paper-sandbox-operacional.md`.
- decisao final no escopo do epic: `S0` apto para avaliar `S1` (sem liberacao automatica de live).
- conclusao: `EPIC-F7-01` concluido no escopo documental/tdd desta rodada.

## Dependencias
- [Trading PRD](../../../../VERTICALS/TRADING/TRADING-PRD.md)
- [Trading Enablement Criteria](../../../../VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md)
- [Decision Protocol](../../../../PM/DECISION-PROTOCOL.md)
- [Eval Trading Script](../../../../scripts/ci/eval_trading.sh)
