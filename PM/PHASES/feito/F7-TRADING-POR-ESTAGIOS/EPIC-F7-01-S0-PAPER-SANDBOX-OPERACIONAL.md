---
doc_id: "EPIC-F7-01-S0-PAPER-SANDBOX-OPERACIONAL.md"
version: "1.1"
status: "active"
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

**Plano TDD**
1. `Red`: considerar ordem de entrada sem aprovacao humana explicita.
2. `Green`: aplicar regra de aprovacao humana por ordem em `S0`.
3. `Refactor`: revisar alinhamento com `Decision Protocol` e criterios de trading.

**Criterios de aceitacao**
- Given ordem de entrada sem aprovacao humana, When revisao do estagio e executada, Then a operacao deve ser bloqueada.
- Given aprovacao humana explicita por ordem, When revisao do estagio e executada, Then o criterio de HITL em `S0` fica conforme.

### ISSUE-F7-01-03 - Validar evidencias minimas de janela S0 e status operacional para habilitar avaliacao de S1
**User story**  
Como operador, quero evidencias minimas de estabilidade em `S0` para decidir com criterio se `S1` pode ser avaliado.

**Plano TDD**
1. `Red`: registrar janela `S0` sem evidencias minimas.
2. `Green`: consolidar evidencias de janela e status operacional conforme criterio.
3. `Refactor`: integrar evidencias ao artifact de fase.

**Criterios de aceitacao**
- Given evidencias insuficientes da janela `S0`, When gate de fase e revisado, Then resultado deve ser `hold`.
- Given evidencias minimas completas de `S0`, When gate de fase e revisado, Then fase fica apta a avaliar `S1`.

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
