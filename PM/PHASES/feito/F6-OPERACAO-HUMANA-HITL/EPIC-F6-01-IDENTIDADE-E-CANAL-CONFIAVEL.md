---
doc_id: "EPIC-F6-01-IDENTIDADE-E-CANAL-CONFIAVEL.md"
version: "1.2"
status: "active"
owner: "PM"
last_updated: "2026-03-01"
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
Como operador, quero validar `OPERATORS.yaml` como fonte unica de aprovadores e vinculo com canal confiavel para impedir aprovacao por identidade/origem nao autorizada.

**Metadata da issue**
- **Owner**: `security-lead`
- **Estimativa**: `3d`
- **Dependencias**: `SEC/allowlists/OPERATORS.yaml`, `PM/DECISION-PROTOCOL.md`, `scripts/ci/check_security.sh`
- **Mapped requirements**: `R1`
- **Prioridade**: `P1`
- **Checklist QA/Repro**:
  1. invalidar campo obrigatorio de operador e executar `make ci-security`;
  2. restaurar operador valido e evidenciar canal confiavel no checklist HITL no mesmo ciclo de `make ci-security`;
  3. remover evidencia de canal e confirmar resultado final `hold`.
- **Evidence refs**: `assistant-brain/PRD/PHASE-USABILITY-GUIDE.md:39`, `assistant-brain/PM/PHASES/feito/F6-OPERACAO-HUMANA-HITL/EPICS.md:22-25`

**Plano TDD**
1. `Red`: remover ou invalidar campo obrigatorio de operador e executar `make ci-security`.
2. `Green`: restaurar os campos obrigatorios de operador e vincular operador aprovado a canal confiavel no checklist HITL no mesmo ciclo.
3. `Refactor`: rerodar `make ci-security` para confirmar estabilidade do baseline e rastreabilidade operador+canal.

**Criterios de aceitacao**
- Given operador sem identificador obrigatorio, When `make ci-security` roda, Then o gate falha.
- Given operadores com contrato minimo valido e canal confiavel referenciado no checklist HITL no mesmo ciclo, When `make ci-security` roda, Then retorna `security-check: PASS`.
- Given falta de evidencia de canal confiavel no ciclo de validacao, When revisao final da fase ocorre, Then o resultado obrigatorio e `hold`.

### ISSUE-F6-01-02 - Validar regra de canal confiavel Telegram primario e email nao confiavel
**User story**  
Como operador, quero regra explicita de canal confiavel para evitar execucao por origem nao autorizada.

**Metadata da issue**
- **Owner**: `security-lead`
- **Estimativa**: `3d`
- **Dependencias**: `PM/DECISION-PROTOCOL.md`, `PRD/PHASE-USABILITY-GUIDE.md`, `scripts/ci/check_security.sh`
- **Mapped requirements**: `R1`, `R2`, `R4`
- **Prioridade**: `P1`
- **Checklist QA/Repro**:
  1. introduzir texto ambiguo que permita email como confiavel e validar bloqueio (`hold`);
  2. restaurar regra explicita `Telegram primario` + `email nao confiavel` e executar `make ci-security`;
  3. anexar checklist HITL com item de canal em `pass` e log `security-check: PASS`.
- **Evidence refs**: `assistant-brain/PM/DECISION-PROTOCOL.md:136-145`, `assistant-brain/PRD/PHASE-USABILITY-GUIDE.md:39`

**Plano TDD**
1. `Red`: introduzir linguagem ambigua que permita email como canal confiavel e remover amarracao com gate de seguranca.
2. `Green`: restaurar regra de Telegram primario e email como canal nao confiavel para comando, vinculando ao ciclo de `make ci-security`.
3. `Refactor`: revisar consistencia em policy e protocolos de decisao para evitar ambiguidade de gate.

**Criterios de aceitacao**
- Given regra ambigua de canal, When revisao de fase ocorre, Then promocao fica bloqueada.
- Given regra explicita de Telegram primario e email nao confiavel e `security-check: PASS` no mesmo ciclo, When checklist HITL e revisado, Then o item de canal confiavel fica `pass`.
- Given ausencia de `security-check: PASS` no ciclo da revisao, When gate F6 e avaliado, Then o resultado final permanece `hold`.

### ISSUE-F6-01-03 - Validar criterio de fallback Slack somente com IDs preenchidos e canal autorizado
**User story**  
Como operador, quero fallback Slack bloqueado por default ate validacao completa para evitar bypass de autenticacao.

**Metadata da issue**
- **Owner**: `product-owner`
- **Estimativa**: `3d`
- **Dependencias**: `PM/DECISION-PROTOCOL.md`, `SEC/allowlists/OPERATORS.yaml`
- **Mapped requirements**: `R5`
- **Prioridade**: `P1`
- **Checklist QA/Repro**:
  1. validar que `slack_user_ids`/`slack_channel_ids` vazios resultam em `hold`;
  2. validar fallback apenas com IDs preenchidos e canal autorizado por policy;
  3. registrar evidencias com `operator_id`, canal autorizado e referencia de checklist HITL.
- **Evidence refs**: `assistant-brain/PM/DECISION-PROTOCOL.md:139`, `assistant-brain/VERTICALS/TRADING/TRADING-PRD.md:198`

**Plano TDD**
1. `Red`: considerar fallback Slack habilitado com `slack_user_ids`/`slack_channel_ids` vazios.
2. `Green`: manter fallback Slack permitido somente com IDs preenchidos e canal autorizado por policy.
3. `Refactor`: registrar evidencia de readiness do fallback no artifact da fase com rastreabilidade de operador e canal.

**Criterios de aceitacao**
- Given fallback Slack sem IDs validos, When checklist HITL e avaliado, Then resultado deve ser `hold`.
- Given fallback Slack com IDs/canal validos, When checklist HITL e avaliado, Then item de fallback pode ser marcado como `pass`.
- Given issue concluida com fallback `pass`, When auditoria de evidencias ocorrer, Then `operator_id`, canal autorizado e referencia de policy devem estar anexados.

## Artifact Minimo do Epico
- registrar resumo em `artifacts/phase-f6/epic-f6-01-identity-channel.md` com:
  - operadores habilitados e campos de identidade validados;
  - status do canal primario e fallback;
  - resultado de `make ci-security`.

## Resultado desta Rodada
- `make ci-security` final: `PASS` (`security-check: PASS`).
- `make ci-quality` final: `PASS` (`quality-check: PASS`).
- evidencias por issue publicadas:
  - `artifacts/phase-f6/epic-f6-01-issue-01-operators-source-of-truth.md`;
  - `artifacts/phase-f6/epic-f6-01-issue-02-trusted-channel-telegram-primary-email-untrusted.md`;
  - `artifacts/phase-f6/epic-f6-01-issue-03-slack-fallback-ids-and-authorized-channel.md`.
- evidencia consolidada do epico:
  - `artifacts/phase-f6/epic-f6-01-identity-channel.md`.
- conclusao: `EPIC-F6-01` concluido no escopo documental/tdd desta rodada.
- remediacao de auditoria aplicada: metadata obrigatoria por issue + gate operador/canal com `security-check: PASS` no mesmo ciclo.

## Dependencias
- [Operators Allowlist](../../../../SEC/allowlists/OPERATORS.yaml)
- [Security Policy](../../../../SEC/SEC-POLICY.md)
- [Decision Protocol](../../../../PM/DECISION-PROTOCOL.md)
- [CI Security Check](../../../../scripts/ci/check_security.sh)
