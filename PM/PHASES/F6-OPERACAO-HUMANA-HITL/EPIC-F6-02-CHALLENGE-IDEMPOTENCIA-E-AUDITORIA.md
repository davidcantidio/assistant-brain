---
doc_id: "EPIC-F6-02-CHALLENGE-IDEMPOTENCIA-E-AUDITORIA.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-02-24"
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

**Plano TDD**
1. `Red`: simular comando critico sem challenge valido ou com challenge expirado.
2. `Green`: validar fluxo completo de challenge com TTL, uso unico e invalidacao.
3. `Refactor`: revisar consistencia do lifecycle com o protocolo de decisao.

**Criterios de aceitacao**
- Given comando critico sem challenge valido, When tentativa de aprovacao ocorre, Then a operacao deve ser bloqueada.
- Given challenge valido no tempo correto, When aprovacao critica ocorre, Then a operacao pode prosseguir com trilha auditavel.

### ISSUE-F6-02-02 - Validar idempotencia de comando command_id unico e replay auditado
**User story**  
Como operador, quero que comandos repetidos sejam no-op para evitar duplicidade de efeito.

**Plano TDD**
1. `Red`: processar repeticao de comando com mesmo `command_id` como nova acao.
2. `Green`: tratar repeticao como no-op e registrar evento como replay.
3. `Refactor`: confirmar contrato de idempotencia no protocolo HITL.

**Criterios de aceitacao**
- Given comando com `command_id` repetido, When for reenviado, Then nao deve gerar nova transicao de estado.
- Given replay detectado, When auditoria for consultada, Then deve existir registro explicito de replay.

### ISSUE-F6-02-03 - Validar bloqueio e incidente para falha de autenticacao ou canal
**User story**  
Como operador, quero que falhas de autenticacao/canal disparem bloqueio e incidente para evitar acao insegura.

**Plano TDD**
1. `Red`: aceitar comando com identidade/canal invalidos.
2. `Green`: bloquear comando invalido e abrir trilha de incidente (`SECURITY_VIOLATION_REVIEW`).
3. `Refactor`: consolidar criterio de resposta no runbook de incidente.

**Criterios de aceitacao**
- Given autenticacao/canal invalido, When comando HITL for recebido, Then execucao deve ser bloqueada.
- Given bloqueio por falha de autenticacao/canal, When evidencia for revisada, Then incidente deve estar registrado.

## Artifact Minimo do Epico
- registrar resumo em `artifacts/phase-f6/epic-f6-02-challenge-audit.md` com:
  - status de challenge (TTL, invalidacao, uso unico);
  - status de idempotencia por `command_id`;
  - bloqueios/incidentes registrados.

## Dependencias
- [Decision Protocol](../../../PM/DECISION-PROTOCOL.md)
- [Security Secrets](../../../SEC/SEC-SECRETS.md)
- [Incident Response](../../../SEC/SEC-INCIDENT-RESPONSE.md)
- [CI Security Check](../../../scripts/ci/check_security.sh)
