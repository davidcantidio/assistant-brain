---
doc_id: "EPIC-F6-03-FALLBACK-CONTINGENCIA-E-PROMOCAO.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-02-24"
rfc_refs: ["RFC-001", "RFC-015", "RFC-040", "RFC-050", "RFC-060"]
---

# EPIC-F6-03 Fallback contingencia e promocao

## Objetivo
Fechar F6 com checklist operacional humano de contingencia e decisao de promocao `F6 -> F7`, sem bypass de seguranca em canal critico.

## Resultado de Negocio Mensuravel
- promocao de fase ocorre apenas com evidencias de prontidao HITL validadas.
- indisponibilidade de canal/operador critico tem resposta previsivel e fail-safe.

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- `make ci-security` executado com sucesso.
- checklist de prontidao HITL preenchido com resultado final `promote|hold`.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F6-03-01 - Validar runbook de contingencia Telegram degradado com fallback Slack controlado
**User story**  
Como operador, quero runbook de contingencia claro para manter controle quando Telegram degradar.

**Plano TDD**
1. `Red`: assumir fallback Slack sem aplicar os mesmos controles de autenticacao/challenge.
2. `Green`: aplicar fallback Slack com os mesmos controles de assinatura, anti-replay e challenge.
3. `Refactor`: consolidar procedimento no checklist de prontidao da fase.

**Criterios de aceitacao**
- Given Telegram degradado e fallback sem controles equivalentes, When contingencia e revisada, Then resultado da fase deve ser `hold`.
- Given Telegram degradado e fallback com controles equivalentes validados, When contingencia e revisada, Then item de fallback pode ser `pass`.

### ISSUE-F6-03-02 - Validar pre-condicao trading live sem fallback valido permanece TRADING_BLOCKED
**User story**  
Como operador, quero garantir bloqueio de trading live quando canal HITL critico nao estiver pronto.

**Plano TDD**
1. `Red`: permitir live mesmo sem fallback validado.
2. `Green`: manter `TRADING_BLOCKED` quando fallback HITL nao cumprir criterio.
3. `Refactor`: alinhar regra com criterio de enablement de trading.

**Criterios de aceitacao**
- Given fallback HITL nao validado, When pre-condicao de live for avaliada, Then estado deve permanecer `TRADING_BLOCKED`.
- Given fallback HITL validado conforme policy, When pre-condicao de live for avaliada, Then o bloqueio pode ser removido por decisao formal.

### ISSUE-F6-03-03 - Consolidar evidencia unica da fase e registrar decisao promote hold
**User story**  
Como operador, quero artifact unico da F6 para justificar com clareza a decisao de promocao.

**Plano TDD**
1. `Red`: manter evidencias dispersas sem resultado final de fase.
2. `Green`: consolidar evidencias em artifact unico com decisao `promote|hold`.
3. `Refactor`: validar links internos e consistencia com `make ci-quality`.

**Criterios de aceitacao**
- Given evidencia de fase incompleta, When revisao final for realizada, Then resultado deve ser `hold`.
- Given checklist completo com `ci-security: PASS`, When revisao final for realizada, Then decisao final pode ser `promote`.

## Artifact Minimo do Epico
- registrar resumo em `artifacts/phase-f6/validation-summary.md` com:
  - status de `make ci-security`;
  - status dos epicos `EPIC-F6-01..EPIC-F6-03`;
  - decisao de fase (`promote|hold`) e justificativa.
- registrar checklist em `artifacts/phase-f6/hitl-readiness-checklist.md` contendo obrigatoriamente:
  - `checklist_id`
  - `operator_id`
  - `primary_channel`
  - `fallback_channel`
  - `telegram_identity_validated`
  - `slack_fallback_validated`
  - `challenge_flow_validated`
  - `command_idempotency_validated`
  - `ci_security_status`
  - `decision_protocol_ref`
  - `result` (`promote|hold`)
  - `justification`

## Dependencias
- [Phase Usability Guide](../../../PRD/PHASE-USABILITY-GUIDE.md)
- [Trading Enablement Criteria](../../../VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md)
- [Decision Protocol](../../../PM/DECISION-PROTOCOL.md)
- [Security Policy](../../../SEC/SEC-POLICY.md)
- [CI Security Check](../../../scripts/ci/check_security.sh)
