---
doc_id: "EPIC-F3-03-HEARTBEAT-TIMEZONE-OPERACAO.md"
version: "1.1"
status: "active"
owner: "PM"
last_updated: "2026-02-26"
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

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F3-03-01 - Validar baseline de 15 minutos em docs canonicos
**User story**  
Como operador, quero baseline unico de heartbeat para evitar comportamento operacional divergente.

**Plano TDD**
1. `Red`: introduzir divergencia de baseline em documento canonico e executar `make eval-runtime`.
2. `Green`: restaurar baseline oficial de 15 minutos em todos os pontos exigidos.
3. `Refactor`: rerodar `make eval-runtime` para confirmar consistencia.

**Criterios de aceitacao**
- Given baseline divergente, When `make eval-runtime` roda, Then o gate falha.
- Given baseline alinhado em 15 minutos, When `make eval-runtime` roda, Then a verificacao passa.

### ISSUE-F3-03-02 - Validar America Sao_Paulo e nightly extraction as 23:00
**User story**  
Como operador, quero timezone e horario noturno padronizados para manter ciclo diario consistente.

**Plano TDD**
1. `Red`: simular timezone ou horario noturno divergente e executar `make eval-runtime`.
2. `Green`: restaurar `America/Sao_Paulo` e `nightly-extraction` as 23:00.
3. `Refactor`: rerodar `make eval-runtime` e registrar evidencia de alinhamento.

**Criterios de aceitacao**
- Given timezone/horario divergente, When `make eval-runtime` roda, Then o gate falha.
- Given timezone `America/Sao_Paulo` e ciclo noturno as 23:00 alinhados, When `make eval-runtime` roda, Then retorna `PASS`.

### ISSUE-F3-03-03 - Validar coerencia de regras criticas de canal e side effect financeiro
**User story**  
Como operador, quero garantir que regras criticas de seguranca e aprovacao financeira nao sofram regressao no runtime.

**Plano TDD**
1. `Red`: remover ou ambiguar regra de canal confiavel e aprovacao humana explicita em docs normativos.
2. `Green`: restaurar regra explicita de email nao confiavel para comando e aprovacao humana para side effect financeiro.
3. `Refactor`: rerodar `make eval-runtime` para confirmar bloqueio de drift.

**Criterios de aceitacao**
- Given regra critica ausente ou ambigua, When `make eval-runtime` roda, Then o gate falha.
- Given regra critica explicita e coerente, When `make eval-runtime` roda, Then a validacao retorna `PASS`.

## Artifact Minimo do Epico
- registrar resumo em `artifacts/phase-f3/epic-f3-03-heartbeat-timezone-operation.md` com:
  - status de baseline heartbeat e timezone;
  - status das regras criticas de canal/aprovacao;
  - resultado final de `make eval-runtime`;
  - decisao de fase (`promote|hold`) com justificativa.

## Resultado desta Rodada
- `make eval-runtime` final: `PASS` (`eval-runtime-contracts: PASS`).
- evidencias por issue publicadas:
  - `artifacts/phase-f3/epic-f3-03-issue-01-heartbeat-baseline.md`;
  - `artifacts/phase-f3/epic-f3-03-issue-02-timezone-nightly.md`;
  - `artifacts/phase-f3/epic-f3-03-issue-03-channel-financial-rules.md`.
- evidencia consolidada do epico:
  - `artifacts/phase-f3/epic-f3-03-heartbeat-timezone-operation.md`.
- decisao de fase: `promote` (gate `eval-runtime` verde com `F3-01..03` em `done`).
- conclusao: `EPIC-F3-03` concluido no escopo documental/tdd desta rodada.

## Dependencias
- [ARC Heartbeat](../../../ARC/ARC-HEARTBEAT.md)
- [Workspace Heartbeat](../../../workspaces/main/HEARTBEAT.md)
- [PRD Master](../../../PRD/PRD-MASTER.md)
- [Security Policy](../../../SEC/SEC-POLICY.md)
- [Decision Protocol](../../../PM/DECISION-PROTOCOL.md)
- [Trading PRD](../../../VERTICALS/TRADING/TRADING-PRD.md)
- [Trading Risk Rules](../../../VERTICALS/TRADING/TRADING-RISK-RULES.md)
- [Trading Enablement Criteria](../../../VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md)
