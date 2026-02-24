---
doc_id: "EPIC-F6-01-IDENTIDADE-E-CANAL-CONFIAVEL.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-02-24"
rfc_refs: ["RFC-001", "RFC-015", "RFC-040", "RFC-050", "RFC-060"]
---

# EPIC-F6-01 Identidade e canal confiavel

## Objetivo
Garantir identidade de operador e contrato de canal confiavel para comandos HITL criticos (`approve/reject/kill`), mantendo Telegram como primario e Slack apenas fallback validado.

## Resultado de Negocio Mensuravel
- operacao humana critica fica bloqueada quando identidade/canal nao cumprem policy.
- equipe possui criterio objetivo para validar prontidao de operador/canal antes de promover fase.

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- `make ci-security` executado com sucesso.
- evidencia de identidade/canal registrada no artifact do epico.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F6-01-01 - Validar OPERATORS.yaml como fonte de verdade para aprovadores HITL
**User story**  
Como operador, quero validar `OPERATORS.yaml` como fonte unica de aprovadores para impedir aprovacao por identidade nao autorizada.

**Plano TDD**
1. `Red`: remover ou invalidar campo obrigatorio de operador e executar `make ci-security`.
2. `Green`: restaurar os campos obrigatorios de operador no formato canonicamente definido.
3. `Refactor`: rerodar `make ci-security` para confirmar estabilidade do baseline.

**Criterios de aceitacao**
- Given operador sem identificador obrigatorio, When `make ci-security` roda, Then o gate falha.
- Given operadores com contrato minimo valido, When `make ci-security` roda, Then retorna `security-check: PASS`.

### ISSUE-F6-01-02 - Validar regra de canal confiavel Telegram primario e email nao confiavel
**User story**  
Como operador, quero regra explicita de canal confiavel para evitar execucao por origem nao autorizada.

**Plano TDD**
1. `Red`: introduzir linguagem ambigua que permita email como canal confiavel.
2. `Green`: restaurar regra de Telegram primario e email como canal nao confiavel para comando.
3. `Refactor`: revisar consistencia em policy e protocolos de decisao.

**Criterios de aceitacao**
- Given regra ambigua de canal, When revisao de fase ocorre, Then promocao fica bloqueada.
- Given regra explicita de Telegram primario e email nao confiavel, When checklist HITL e revisado, Then o item de canal confiavel fica `pass`.

### ISSUE-F6-01-03 - Validar criterio de fallback Slack somente com IDs preenchidos e canal autorizado
**User story**  
Como operador, quero fallback Slack bloqueado por default ate validacao completa para evitar bypass de autenticacao.

**Plano TDD**
1. `Red`: considerar fallback Slack habilitado com `slack_user_ids`/`slack_channel_ids` vazios.
2. `Green`: manter fallback Slack permitido somente com IDs preenchidos e canal autorizado por policy.
3. `Refactor`: registrar evidencia de readiness do fallback no artifact da fase.

**Criterios de aceitacao**
- Given fallback Slack sem IDs validos, When checklist HITL e avaliado, Then resultado deve ser `hold`.
- Given fallback Slack com IDs/canal validos, When checklist HITL e avaliado, Then item de fallback pode ser marcado como `pass`.

## Artifact Minimo do Epico
- registrar resumo em `artifacts/phase-f6/epic-f6-01-identity-channel.md` com:
  - operadores habilitados e campos de identidade validados;
  - status do canal primario e fallback;
  - resultado de `make ci-security`.

## Dependencias
- [Operators Allowlist](../../../SEC/allowlists/OPERATORS.yaml)
- [Security Policy](../../../SEC/SEC-POLICY.md)
- [Decision Protocol](../../../PM/DECISION-PROTOCOL.md)
- [CI Security Check](../../../scripts/ci/check_security.sh)
