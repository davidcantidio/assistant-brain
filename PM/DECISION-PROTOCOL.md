---
doc_id: "DECISION-PROTOCOL.md"
version: "1.6"
status: "active"
owner: "PM"
last_updated: "2026-02-26"
rfc_refs: ["RFC-001", "RFC-010", "RFC-015", "RFC-040", "RFC-050", "RFC-060"]
---

# Decision Protocol

## Objetivo
Definir quando abrir decision, qual formato minimo usar e como executar aprovacao/rejeicao/kill via HITL multi-canal com confianca de canal explicita (Telegram primario, Slack fallback).

## Escopo
Inclui:
- gatilhos de decision obrigatoria
- formato padrao da proposta
- comandos HITL e timeouts de escalacao
- lifecycle completo do challenge de segundo fator

Exclui:
- aprovacao verbal sem trilha
- alteracao critica sem registro em decision

## Regras Normativas
- [RFC-040] MUST abrir decision para excecao de politica, risco alto e override de limite.
- [RFC-010] MUST explicitar classe de risco na proposta.
- [RFC-050] MUST anexar evidencias e custo estimado.
- [RFC-060] MUST usar decision para habilitacao e alteracoes de trading live.
- [RFC-040] MUST versionar o contrato de decision e manter maquina de estados valida.
- [RFC-040] MUST respeitar capacidade humana diaria de aprovacao e limite de fila pendente.
- [RFC-015] MUST validar identidade/autorizacao do aprovador HITL por allowlist de operador e contrato do canal (Telegram ou Slack).
- [RFC-015] MUST exigir desafio adicional (challenge) para `risk_class=alto`/`risk_tier=R3`, `/kill` e trading.
- [RFC-040] MUST tratar comando de aprovacao/rejeicao/kill como evento idempotente (`command_id` unico).
- [RFC-015] MUST explicitar `data_sensitivity` em decisions que envolvam inferencia LLM.
- [RFC-030] MUST registrar `requested_model`, `effective_model` e `effective_provider` em decisions de roteamento critico.
- [RFC-015] MUST validar assinatura e anti-replay de requests Slack (`timestamp` + assinatura HMAC) quando Slack for usado como canal HITL.
- [RFC-060] MUST operar Trading live em `fail-closed` quando canal HITL critico estiver indisponivel sem fallback validado.
- [RFC-015] MUST tratar email como canal nao confiavel para comando.
- [RFC-060] MUST exigir aprovacao humana explicita para toda acao financeira com side effect.

## Taxonomia de Risco Canonica (compatibilidade)
- taxonomia canonica para gates tecnicos:
  - `R0`: sem impacto funcional/side effect (doc-only).
  - `R1`: baixo risco funcional local.
  - `R2`: medio risco com side effect controlado/cross-modulo.
  - `R3`: alto risco critico.
- mapeamento legado `risk_class`:
  - `baixo -> R1` (ou `R0` quando doc-only sem side effect).
  - `medio -> R2`.
  - `alto -> R3`.
- o payload de decision MUST carregar `risk_class` e `risk_tier` para evitar ambiguidade.

## O que vira Decision
- alto risco operacional/financeiro.
- alteracao de politica global.
- override de sprint/budget/model routing.
- habilitacao de vertical de risco elevado.
- uso de `cross_review_codex_claude` fora de classes criticas preaprovadas.
- qualquer ordem financeira real (entrada, saida, ajuste de exposicao) em qualquer fase.

## Formato da Decision
```yaml
schema_version: "1.3"
decision_id: "DEC-YYYYMMDD-XXX"
decision_key: "<scope>:<topic>:<window>"
title: "resumo objetivo"
proposal: "acao proposta"
evidence:
  - "artifact://..."
risk_class: "baixo|medio|alto"
risk_tier: "R0|R1|R2|R3"
execution_pattern: "single_agent|subagent_pod_codex|subagent_pod_claude|cross_review_codex_claude"
preset_id: "preset://...|null"
requested_model: "string|null"
requested_provider: "string|null"
effective_model: "string|null"
effective_provider: "string|null"
data_sensitivity: "public|internal|sensitive"
cost_impact: 120.0
rollback_plan: "como desfazer"
requested_by: "agente"
created_at: "ISO-8601"
timeout_at: "ISO-8601"
status: "PENDING|APPROVED|REJECTED|KILLED|EXPIRED"
decided_by: "operador|modelo|null"
decided_at: "ISO-8601|null"
escalation_count: 0
approver_operator_id: "string|null"
approver_channel: "telegram|slack|null"
approver_telegram_user_id: "int|null"
approver_telegram_chat_id: "int|null"
approver_slack_user_id: "string|null"
approver_slack_channel_id: "string|null"
auth_method: "telegram_allowlist|slack_allowlist|challenge_secret|personal_domain_confirmation|null"
last_command_id: "CMD-UUID|null"
challenge_id: "CHL-UUID|null"
challenge_status: "NOT_REQUIRED|PENDING|VALIDATED|EXPIRED|INVALIDATED"
challenge_expires_at: "ISO-8601|null"
```

## Maquina de Estados
- fluxo valido:
  - `PENDING -> APPROVED`
  - `PENDING -> REJECTED`
  - `PENDING -> KILLED`
  - `PENDING -> EXPIRED`
- qualquer estado terminal MUST impedir execucao adicional sem nova decision.

## SLA de Decisao (inicial)
- risco alto: p95 <= 15 minutos.
- risco medio: p95 <= 60 minutos.
- expiracao MUST abrir task/incident de governanca.

## Capacidade Humana e Fila
- capacidade humana inicial:
  - janela diaria de aprovacao: 4 horas (ajustavel por decision).
- limite de fila:
  - `max_pending_decisions_global = 10`.
- regra de saturacao:
  - ao atingir limite, bloquear criacao automatica de decisions nao criticas;
  - consolidar itens em backlog priorizado;
  - manter somente risco alto e incidentes.

## Canais HITL (Telegram primario + Slack fallback)
- Telegram:
  - `/approve <decision_id> [challenge]`: aprova com log de operador.
  - `/reject <decision_id> [motivo]`: rejeita com motivo.
  - `/kill <decision_id|operation_id> [challenge]`: para imediatamente operacao ativa.
- Slack (contingencia/fallback):
  - `/oc-approve <decision_id> [challenge]`
  - `/oc-reject <decision_id> [motivo]`
  - `/oc-kill <decision_id|operation_id> [challenge]`
- regra de fallback:
  - Telegram e canal primario para comandos criticos.
  - indisponibilidade de Telegram por > 2 heartbeats permite fallback em Slack com os mesmos controles de autenticacao, challenge e auditoria.
  - fallback Slack para trading live so e permitido quando operador habilitado tiver `slack_user_ids` e `slack_channel_ids` nao vazios.

## Regra de Confianca de Canal
- email e canal de informacao/triagem, nunca canal confiavel para comando.
- pedido recebido por email MUST ser encaminhado para confirmacao em Telegram (ou Slack fallback validado) antes de executar.
- comando vindo exclusivamente por email MUST ser registrado como `UNTRUSTED_COMMAND_SOURCE`.

## Controle de Identidade/Autorizacao (HITL)
- fonte de verdade de aprovadores: `../SEC/allowlists/OPERATORS.yaml`.
- Telegram:
  - `message.from.id` MUST estar na allowlist.
  - `message.chat.id` MUST estar na allowlist.
  - par (`from.id`, `chat.id`) MUST coincidir com mesmo operador cadastrado.
- Slack:
  - `user_id` MUST estar na allowlist do operador.
  - `channel_id` MUST estar em `slack_channel_ids` do operador ou em canal HITL explicitamente aprovado por decision.
  - assinatura do request MUST validar (`SLACK_SIGNING_SECRET`) com janela anti-replay de 5 minutos.
- para comandos criticos (`/kill`, approve de `risk_class=alto`/`risk_tier=R3`, trading live):
  - MUST exigir challenge valido de uso unico.
- qualquer falha de autenticacao MUST:
  - bloquear comando;
  - abrir `SECURITY_VIOLATION_REVIEW`;
  - registrar hash do payload do update.
- controle de tentativa:
  - 3 falhas consecutivas => lock temporario de 15 minutos para comandos criticos.

## Lifecycle do Challenge (segundo fator)
1. Geracao:
  - runtime gera `challenge_id` unico por comando critico.
  - valor do challenge MUST ser aleatorio e nunca persistido em texto puro.
2. Persistencia:
  - salvar apenas `challenge_hash` (HMAC) e metadados em store transiente (`hitl_challenges`).
  - `ttl_padrao = 5 minutos`.
3. Entrega:
  - challenge enviado ao operador autorizado no canal HITL.
4. Validacao:
  - challenge + `command_id` + identidade do operador MUST casar com registro pendente.
5. Invalidacao:
  - sucesso, expiracao TTL, 3 falhas, rotacao de chave ou revogacao manual => `INVALIDATED`.
6. Auditoria:
  - registrar `challenge_id`, status final, tentativas e motivo de invalidacao.

## Rotacao de Chave do Challenge
- chave HMAC mestre (`HITL_CHALLENGE_HMAC_KEY`) MUST ficar em secret manager do host.
- periodicidade minima de rotacao: 30 dias.
- rotacao emergencial MUST ocorrer apos incidente de seguranca.

## Idempotencia de Comando HITL
- cada comando HITL (Telegram ou Slack) MUST gerar `command_id` unico.
- reenvio do mesmo comando MUST ser no-op (sem transicao adicional de estado).
- comando com `command_id` repetido MUST ser auditado como replay.

## SPOF de Aprovador (politica inicial)
- modo bootstrap permitido: 1 operador primario (`single_primary`).
- regra para Trading live: adicionar `backup_operator` em break-glass antes de habilitar capital real.
- indisponibilidade de Telegram:
  - com fallback Slack validado, MUST ativar fallback com os mesmos controles de auth/challenge.
  - sem fallback Slack validado, MUST operar em `TRADING_BLOCKED` ate restauracao de canal/aprovador.
- indisponibilidade do operador primario por >4h em fila critica MUST abrir incidente de capacidade.
- pre-condicao para Trading live:
  - MUST existir pelo menos 1 `backup_operator` habilitado com permissao de `approve/reject/kill`.
  - sem backup habilitado, sistema MUST operar em `TRADING_BLOCKED`.

## Timeouts e Escalation
- decision PENDING com timeout MUST escalar para humano responsavel.
- apos 2 timeouts, abrir incident de governanca.
- operacao bloqueada nao pode seguir sem estado terminal.

## Links Relacionados
- [Sprint Limits](./SPRINT-LIMITS.md)
- [Trading Enablement](../VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md)
- [Governance Risk](../CORE/GOVERNANCE-RISK.md)
- [SEC Secrets](../SEC/SEC-SECRETS.md)
