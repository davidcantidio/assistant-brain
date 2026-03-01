---
doc_id: "EPIC-F6-03-FALLBACK-CONTINGENCIA-E-PROMOCAO.md"
version: "1.2"
status: "active"
owner: "PM"
last_updated: "2026-03-01"
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

**Metadata da issue**
- **Owner**: `product-owner + tech-lead-trading`
- **Estimativa**: `3d`
- **Dependencias**: `PM/DECISION-PROTOCOL.md`, `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`, `scripts/ci/check_security.sh`
- **Mapped requirements**: `R3`, `R9`
- **Prioridade**: `P1`
- **Checklist QA/Repro**:
  1. simular `Telegram degradado >2 heartbeats`;
  2. validar que fallback Slack sem controles equivalentes resulta em `hold`;
  3. validar aplicacao de assinatura HMAC, anti-replay e challenge equivalente;
  4. validar abertura obrigatoria de `RESTORE_TELEGRAM_CHANNEL` ao entrar em contingencia.
- **Evidence refs**: `assistant-brain/PM/DECISION-PROTOCOL.md:137-140,197`, `assistant-brain/PM/PHASES/feito/F6-OPERACAO-HUMANA-HITL/EPIC-F6-03-FALLBACK-CONTINGENCIA-E-PROMOCAO.md:26-38`

**Plano TDD**
1. `Red`: assumir fallback Slack sem aplicar os mesmos controles de autenticacao/challenge e sem limiar temporal de degradacao.
2. `Green`: aplicar fallback Slack com os mesmos controles de assinatura, anti-replay e challenge somente quando `Telegram degradado >2 heartbeats`.
3. `Refactor`: consolidar procedimento no checklist de prontidao da fase com abertura obrigatoria de `RESTORE_TELEGRAM_CHANNEL`.

**Criterios de aceitacao**
- Given Telegram degradado e fallback sem controles equivalentes, When contingencia e revisada, Then resultado da fase deve ser `hold`.
- Given `Telegram degradado >2 heartbeats` e fallback com controles equivalentes validados, When contingencia e revisada, Then item de fallback pode ser `pass`.
- Given fallback Slack acionado, When operacao entra em contingencia, Then incidente/task `RESTORE_TELEGRAM_CHANNEL` deve ser aberto e referenciado na evidencia da issue.

### ISSUE-F6-03-02 - Validar pre-condicao trading live sem fallback valido permanece TRADING_BLOCKED
**User story**  
Como operador, quero garantir bloqueio de trading live quando canal HITL critico nao estiver pronto.

**Metadata da issue**
- **Owner**: `product-owner + tech-lead-trading`
- **Estimativa**: `3d`
- **Dependencias**: `PM/DECISION-PROTOCOL.md`, `VERTICALS/TRADING/TRADING-PRD.md`, `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`
- **Mapped requirements**: `R10`, `R11`
- **Prioridade**: `P1`
- **Checklist QA/Repro**:
  1. validar que fallback invalido mantem `TRADING_BLOCKED`;
  2. tentar desbloqueio sem `decision_id` e confirmar bloqueio;
  3. validar desbloqueio apenas com `decision_id` formal referenciado na evidencia.
- **Evidence refs**: `assistant-brain/PM/DECISION-PROTOCOL.md:198,203-204`, `assistant-brain/VERTICALS/TRADING/TRADING-PRD.md:186,200`

**Plano TDD**
1. `Red`: permitir live mesmo sem fallback validado.
2. `Green`: manter `TRADING_BLOCKED` quando fallback HITL nao cumprir criterio ou quando o desbloqueio nao possuir `decision_id`.
3. `Refactor`: alinhar regra com criterio de enablement de trading e rastreabilidade de decisao formal.

**Criterios de aceitacao**
- Given fallback HITL nao validado, When pre-condicao de live for avaliada, Then estado deve permanecer `TRADING_BLOCKED`.
- Given tentativa de desbloqueio sem `decision_id`, When pre-condicao de live for avaliada, Then estado deve permanecer `TRADING_BLOCKED`.
- Given fallback HITL validado conforme policy e `decision_id` formal referenciado, When pre-condicao de live for avaliada, Then o bloqueio pode ser removido por decisao formal.

### ISSUE-F6-03-03 - Consolidar evidencia unica da fase e registrar decisao promote hold
**User story**  
Como operador, quero artifact unico da F6 para justificar com clareza a decisao de promocao.

**Metadata da issue**
- **Owner**: `pm`
- **Estimativa**: `2d`
- **Dependencias**: `PM/DECISION-PROTOCOL.md`, `PRD/PHASE-USABILITY-GUIDE.md`, `scripts/ci/check_quality.sh`
- **Mapped requirements**: `R12`
- **Prioridade**: `P2`
- **Checklist QA/Repro**:
  1. validar checklist HITL completo com todos os campos obrigatorios;
  2. validar resultado `promote|hold` com justificativa e owner responsavel pela consolidacao;
  3. validar data alvo da revisao final e integridade dos links internos.
- **Evidence refs**: `assistant-brain/PM/PHASES/feito/F6-OPERACAO-HUMANA-HITL/EPICS.md:15-25`, `assistant-brain/PRD/PHASE-USABILITY-GUIDE.md:39`

**Plano TDD**
1. `Red`: manter evidencias dispersas sem resultado final de fase.
2. `Green`: consolidar evidencias em artifact unico com decisao `promote|hold`, owner responsavel e data alvo da revisao final.
3. `Refactor`: validar links internos e consistencia com `make ci-quality`.

**Criterios de aceitacao**
- Given evidencia de fase incompleta, When revisao final for realizada, Then resultado deve ser `hold`.
- Given checklist completo com `ci-security: PASS`, owner de consolidacao definido e data alvo registrada, When revisao final for realizada, Then decisao final pode ser `promote`.
- Given artifact final publicado, When auditoria de fase ocorrer, Then resultado `promote|hold`, justificativa, owner responsavel e data alvo devem estar explicitamente registrados.

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

## Resultado desta Rodada
- `make ci-security` final: `PASS` (`security-check: PASS`).
- `make eval-trading` final: `PASS` (`eval-trading: PASS`).
- `make ci-quality` final: `PASS` (`quality-check: PASS`).
- `make eval-gates` final: `PASS` (`eval-gates: PASS`).
- evidencias por issue publicadas:
  - `artifacts/phase-f6/epic-f6-03-issue-01-telegram-degraded-slack-fallback-controlled.md`;
  - `artifacts/phase-f6/epic-f6-03-issue-02-trading-blocked-without-valid-hitl-fallback.md`;
  - `artifacts/phase-f6/epic-f6-03-issue-03-phase-evidence-promote-hold.md`.
- evidencias consolidadas:
  - `artifacts/phase-f6/hitl-readiness-checklist.md`;
  - `artifacts/phase-f6/validation-summary.md`;
  - `artifacts/phase-f6/epic-f6-03-fallback-contingencia-promocao.md`.
- decisao final de fase (`F6 -> F7`): `hold`.
- justificativa: `live_ready: false` em `SEC/allowlists/OPERATORS.yaml` e fallback Slack nao validado para operador habilitado.
- conclusao: `EPIC-F6-03` concluido no escopo documental/tdd desta rodada.
- remediacao de auditoria aplicada: fallback condicionado a `>2 heartbeats`, `RESTORE_TELEGRAM_CHANNEL` obrigatorio e desbloqueio live somente com `decision_id`.

## Dependencias
- [Phase Usability Guide](../../../../PRD/PHASE-USABILITY-GUIDE.md)
- [Trading Enablement Criteria](../../../../VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md)
- [Decision Protocol](../../../../PM/DECISION-PROTOCOL.md)
- [Security Policy](../../../../SEC/SEC-POLICY.md)
- [CI Security Check](../../../../scripts/ci/check_security.sh)
