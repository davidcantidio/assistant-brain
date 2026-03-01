---
doc_id: "EPIC-F6-02-CHALLENGE-IDEMPOTENCIA-E-AUDITORIA.md"
version: "1.2"
status: "active"
owner: "PM"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-015", "RFC-040", "RFC-050", "RFC-060"]
---

# EPIC-F6-02 Challenge idempotencia e auditoria

## Objetivo
Formalizar operacao segura dos comandos HITL (`approve/reject/kill`) com challenge, idempotencia e trilha auditavel de seguranca.

## Resultado de Negocio Mensuravel
- risco de comando critico sem segundo fator ou sem trilha auditavel e reduzido.
- eventos de replay/autenticacao invalida viram bloqueio e incidente rastreavel.

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- `make ci-security` executado com sucesso.
- evidencias de challenge/idempotencia/auditoria registradas no artifact do epico.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F6-02-01 - Validar lifecycle do challenge para comando critico
**User story**  
Como operador, quero challenge com TTL e invalidacao para garantir segundo fator efetivo em comandos criticos.

**Metadata da issue**
- **Owner**: `security-lead`
- **Estimativa**: `1d`
- **Dependencias**: `PM/DECISION-PROTOCOL.md`, `SEC/SEC-SECRETS.md`, `scripts/ci/check_security.sh`
- **Mapped requirements**: `R6`
- **Prioridade**: `P0`
- **Checklist QA/Repro**:
  1. executar teste negativo sem challenge valido;
  2. executar teste negativo de expiracao com `TTL=5 minutos`;
  3. executar teste negativo de reutilizacao (single-use);
  4. executar testes negativos de invalidacao por `3 falhas` e `rotacao de chave`;
  5. executar teste positivo de aprovacao no prazo com trilha auditavel.
- **Evidence refs**: `assistant-brain/PM/DECISION-PROTOCOL.md:166-180`, `assistant-brain/PM/PHASES/feito/F6-OPERACAO-HUMANA-HITL/EPIC-F6-02-CHALLENGE-IDEMPOTENCIA-E-AUDITORIA.md:26-38`

**Plano TDD**
1. `Red`: simular comando critico sem challenge valido, challenge expirado, challenge reutilizado, com 3 falhas e apos rotacao de chave.
2. `Green`: validar fluxo completo de challenge com `TTL=5 minutos`, uso unico e invalidacao completa.
3. `Refactor`: revisar consistencia do lifecycle com o protocolo de decisao e trilha auditavel de invalidacao.

**Criterios de aceitacao**
- Given comando critico sem challenge valido, When tentativa de aprovacao ocorre, Then a operacao deve ser bloqueada.
- Given challenge valido no tempo correto (`TTL=5 minutos`), When aprovacao critica ocorre, Then a operacao pode prosseguir com trilha auditavel.
- Given challenge consumido com sucesso, When o mesmo token for reutilizado, Then status deve ser `INVALIDATED` e o comando deve ser bloqueado.
- Given challenge expirado, com `3 falhas` ou apos `rotacao de chave`, When validacao ocorre, Then status deve ser `INVALIDATED` e o comando deve ser bloqueado.

### ISSUE-F6-02-02 - Validar idempotencia de comando command_id unico e replay auditado
**User story**  
Como operador, quero que comandos repetidos sejam no-op para evitar duplicidade de efeito.

**Metadata da issue**
- **Owner**: `tech-lead-trading`
- **Estimativa**: `3d`
- **Dependencias**: `PM/DECISION-PROTOCOL.md`, `scripts/ci/check_security.sh`
- **Mapped requirements**: `R7`
- **Prioridade**: `P1`
- **Checklist QA/Repro**:
  1. reenviar comando com mesmo `command_id` e confirmar `no-op`;
  2. validar evento de replay registrado na auditoria;
  3. anexar hash do evento de replay no artifact da issue.
- **Evidence refs**: `assistant-brain/PM/DECISION-PROTOCOL.md:188-190`, `assistant-brain/artifacts/phase-f6/epic-f6-02-issue-02-command-id-idempotency-replay-audit.md`

**Plano TDD**
1. `Red`: processar repeticao de comando com mesmo `command_id` como nova acao.
2. `Green`: tratar repeticao como no-op e registrar evento como replay.
3. `Refactor`: confirmar contrato de idempotencia no protocolo HITL com referencia de hash de replay.

**Criterios de aceitacao**
- Given comando com `command_id` repetido, When for reenviado, Then nao deve gerar nova transicao de estado.
- Given replay detectado, When auditoria for consultada, Then deve existir registro explicito de replay.
- Given replay auditado, When evidencia da issue for consolidada, Then deve existir `replay_event_hash` referenciado no artifact.

### ISSUE-F6-02-03 - Validar bloqueio e incidente para falha de autenticacao ou canal
**User story**  
Como operador, quero que falhas de autenticacao/canal disparem bloqueio e incidente para evitar acao insegura.

**Metadata da issue**
- **Owner**: `security-lead`
- **Estimativa**: `3d`
- **Dependencias**: `PM/DECISION-PROTOCOL.md`, `SEC/SEC-INCIDENT-RESPONSE.md`, `scripts/ci/check_security.sh`
- **Mapped requirements**: `R8`
- **Prioridade**: `P1`
- **Checklist QA/Repro**:
  1. simular identidade invalida e validar bloqueio;
  2. simular canal invalido e validar bloqueio;
  3. validar abertura de incidente `SECURITY_VIOLATION_REVIEW`;
  4. anexar hash do payload bloqueado com referencia do incidente.
- **Evidence refs**: `assistant-brain/PM/DECISION-PROTOCOL.md:159-162`, `assistant-brain/SEC/SEC-INCIDENT-RESPONSE.md`

**Plano TDD**
1. `Red`: aceitar comando com identidade/canal invalidos.
2. `Green`: bloquear comando invalido e abrir trilha de incidente (`SECURITY_VIOLATION_REVIEW`).
3. `Refactor`: consolidar criterio de resposta no runbook de incidente com rastreabilidade de payload.

**Criterios de aceitacao**
- Given autenticacao/canal invalido, When comando HITL for recebido, Then execucao deve ser bloqueada.
- Given bloqueio por falha de autenticacao/canal, When evidencia for revisada, Then incidente deve estar registrado.
- Given incidente aberto por bloqueio, When auditoria de seguranca for executada, Then `blocked_payload_hash` deve estar presente na evidencia.

## Artifact Minimo do Epico
- registrar resumo em `artifacts/phase-f6/epic-f6-02-challenge-audit.md` com:
  - status de challenge (TTL, invalidacao, uso unico);
  - status de idempotencia por `command_id`;
  - bloqueios/incidentes registrados.

## Resultado desta Rodada
- `make ci-security` final: `PASS` (`security-check: PASS`).
- `make eval-idempotency` final: `PASS` (`eval-idempotency: PASS`).
- `make ci-quality` final: `PASS` (`quality-check: PASS`).
- evidencias por issue publicadas:
  - `artifacts/phase-f6/epic-f6-02-issue-01-challenge-lifecycle-ttl-single-use.md`;
  - `artifacts/phase-f6/epic-f6-02-issue-02-command-id-idempotency-replay-audit.md`;
  - `artifacts/phase-f6/epic-f6-02-issue-03-auth-channel-block-security-incident.md`.
- evidencia consolidada do epico:
  - `artifacts/phase-f6/epic-f6-02-challenge-audit.md`.
- conclusao: `EPIC-F6-02` concluido no escopo documental/tdd desta rodada.
- remediacao de auditoria aplicada: lifecycle normativo de challenge (`TTL=5 minutos`) e rastreabilidade reforcada para replay/incidentes.

## Dependencias
- [Decision Protocol](../../../../PM/DECISION-PROTOCOL.md)
- [Security Secrets](../../../../SEC/SEC-SECRETS.md)
- [Incident Response](../../../../SEC/SEC-INCIDENT-RESPONSE.md)
- [CI Security Check](../../../../scripts/ci/check_security.sh)
