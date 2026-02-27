---
doc_id: "EPIC-F5-01-INTEGRACOES-GOVERNADAS-E-ANTI-BYPASS.md"
version: "1.1"
status: "active"
owner: "PM"
last_updated: "2026-02-26"
rfc_refs: ["RFC-001", "RFC-010", "RFC-015", "RFC-050", "RFC-060"]
---

# EPIC-F5-01 Integracoes governadas e anti-bypass

## Objetivo
Fechar contratos de integracao externa com bloqueio tecnico de ordem direta, governanca explicita por modo permitido e trilha de auditoria ponta a ponta.

## Resultado de Negocio Mensuravel
- frameworks externos deixam de ter qualquer caminho direto para exchange.
- modo permitido de cada integracao fica verificavel por gate, sem ambiguidade.

## Cobertura ROADMAP
- `B1-01`, `B1-02`, `B1-03`, `B1-11`, `B1-20`, `B1-21`, `B1-22`, `B1-23`, `B1-24`.

## Source refs (felix)
- `felixcraft.md`: OpenClaw as gateway platform, hooks/transforms, channelized trust model.
- `felix-openclaw-pontos-relevantes.md`: separacao de chats/sessoes, anti-injection por canal, operacao multi-projeto sem mistura de contexto.

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- `make eval-integrations` e `make eval-trading` em `PASS`.
- evidencias anti-bypass consolidadas no artifact do epico.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F5-01-01 - Validar adapter TradingAgents signal_intent com normalizacao e deduplicacao
**User story**
Como operador, quero sinais tipados e deduplicados para evitar ruido operacional e perda de rastreabilidade.

**Plano TDD**
1. `Red`: aceitar payload sem contrato `signal_intent` ou sem trace de origem.
2. `Green`: exigir adapter canonical + normalizacao + deduplicacao.
3. `Refactor`: consolidar trilha de origem no artifact do epico.

**Criterios de aceitacao**
- Given payload sem contrato canonical, When validacao roda, Then o gate falha.
- Given payload normalizado e deduplicado com trace, When validacao roda, Then o gate passa.

### ISSUE-F5-01-02 - Validar bloqueio tecnico de ordem direta externa e allowlist de venue
**User story**
Como operador, quero bloqueio hard de ordem direta para exchange para impedir bypass de risco.

**Plano TDD**
1. `Red`: permitir tentativa de ordem direta fora do execution gateway.
2. `Green`: bloquear tecnicamente e exigir venue em allowlist.
3. `Refactor`: consolidar testes de bloqueio no gate de trading.

**Criterios de aceitacao**
- Given caminho de ordem direta externa, When validacao ocorre, Then resultado deve ser `FAIL`.
- Given fluxo apenas via gateway e dominio permitido, When validacao ocorre, Then resultado deve ser `PASS`.

### ISSUE-F5-01-03 - Validar contratos versionados de integracao e compatibilidade dual do runtime
**User story**
Como operador, quero contratos versionados para manter integracao estavel e auditavel.

**Plano TDD**
1. `Red`: remover versao ou campos minimos de contratos de integracao.
2. `Green`: restaurar schemas versionados + compatibilidade `ws` canonico e `chatCompletions` opcional.
3. `Refactor`: alinhar links de contrato com matriz de integracoes.

**Criterios de aceitacao**
- Given contrato sem versionamento/campo minimo, When `make eval-integrations` roda, Then o gate falha.
- Given contratos completos e compatibilidade dual valida, When `make eval-integrations` roda, Then o gate passa.

### ISSUE-F5-01-04 - Validar modo permitido por integracao sem ambiguidade operacional
**User story**
Como operador, quero regras explicitas de modo permitido para AI-Trader e ClawWork sem interpretacao ad hoc.

**Plano TDD**
1. `Red`: manter linguagem ambigua sobre modo permitido por integracao.
2. `Green`: explicitar AI-Trader `signal_only` e ClawWork `lab_isolated` default + `governed` com gateway-only.
3. `Refactor`: consolidar checklist de conformidade por integracao.

**Criterios de aceitacao**
- Given regra ambigua de modo permitido, When revisao ocorre, Then resultado deve ser `hold`.
- Given regra explicita e testada por gate, When revisao ocorre, Then resultado deve ser `pass`.

## Artifact Minimo do Epico
- registrar em `artifacts/phase-f5/epic-f5-01-integrations-anti-bypass.md`:
  - status do adapter de sinais;
  - evidencias de bloqueio de ordem direta;
  - status de contratos versionados e compatibilidade dual;
  - referencias `B*` cobertas.

## Resultado desta Rodada
- `make eval-integrations` final: `PASS` (`eval-integrations: PASS`).
- `make eval-trading` final: `PASS` (`eval-trading: PASS`).
- `make ci-quality` final: `PASS` (`quality-check: PASS`).
- evidencias por issue publicadas:
  - `artifacts/phase-f5/epic-f5-01-issue-01-tradingagents-signal-intent.md`;
  - `artifacts/phase-f5/epic-f5-01-issue-02-direct-order-block-venue-allowlist.md`;
  - `artifacts/phase-f5/epic-f5-01-issue-03-versioned-contracts-runtime-dual.md`;
  - `artifacts/phase-f5/epic-f5-01-issue-04-allowed-modes-no-ambiguity.md`.
- evidencia consolidada do epico:
  - `artifacts/phase-f5/epic-f5-01-integrations-anti-bypass.md`.
- conclusao: `EPIC-F5-01` concluido no escopo documental/tdd desta rodada.

## Dependencias
- [Integrations Readme](../../../../INTEGRATIONS/README.md)
- [Trading Enablement Criteria](../../../../VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md)
- [Roadmap](../../../../PRD/ROADMAP.md)
- [Felixcraft Architecture](../../../../felixcraft.md)
- [Felix OpenClaw Pontos Relevantes](../../../../felix-openclaw-pontos-relevantes.md)
