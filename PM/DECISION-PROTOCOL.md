---
doc_id: "DECISION-PROTOCOL.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-010", "RFC-040", "RFC-050", "RFC-060"]
---

# Decision Protocol

## Objetivo
Definir quando abrir decision, qual formato minimo usar e como executar aprovacao/rejeicao/kill via Telegram.

## Escopo
Inclui:
- gatilhos de decision obrigatoria
- formato padrao da proposta
- comandos HITL e timeouts de escalacao

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
- [RFC-015] MUST validar identidade/autorizacao do aprovador Telegram por allowlist de `from.id` + `chat.id`.
- [RFC-015] MUST exigir desafio adicional (secret/challenge) para `risk_class=alto`, `/kill` e trading.
- [RFC-040] MUST tratar comando de aprovacao/rejeicao/kill como evento idempotente (`command_id` unico).

## O que vira Decision
- alto risco operacional/financeiro.
- alteracao de politica global.
- override de sprint/budget/model routing.
- habilitacao de vertical de risco elevado.
- uso de `cross_review_codex_claude` fora de classes criticas preaprovadas.

## Formato da Decision
```yaml
schema_version: "1.1"
decision_id: "DEC-YYYYMMDD-XXX"
title: "resumo objetivo"
proposal: "acao proposta"
evidence:
  - "artifact://..."
risk_class: "medio|alto"
execution_pattern: "single_agent|subagent_pod_codex|subagent_pod_claude|cross_review_codex_claude"
cost_impact: 120.0
rollback_plan: "como desfazer"
requested_by: "agente"
created_at: "ISO-8601"
timeout_at: "ISO-8601"
status: "PENDING|APPROVED|REJECTED|KILLED|EXPIRED"
decided_by: "operador|modelo|null"
decided_at: "ISO-8601|null"
escalation_count: 0
approver_telegram_user_id: "int|null"
approver_telegram_chat_id: "int|null"
auth_method: "telegram_allowlist|challenge_secret|personal_domain_confirmation|null"
last_command_id: "CMD-UUID|null"
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

## Telegram HITL
- `/approve <decision_id>`: aprova com log de operador.
- `/reject <decision_id>`: rejeita com motivo.
- `/kill <decision_id|operation_id>`: para imediatamente operacao ativa.

## Controle de Identidade/Autorizacao (Telegram)
- fonte de verdade de aprovadores: `../SEC/allowlists/OPERATORS.yaml`.
- regra minima:
  - `message.from.id` MUST estar na allowlist.
  - `message.chat.id` MUST estar na allowlist.
  - par (`from.id`, `chat.id`) MUST coincidir com mesmo operador cadastrado.
- para comandos criticos (`/kill`, approve de `risk_class=alto`, trading live):
  - MUST exigir desafio adicional:
    - opcao A: challenge secret de uso unico com TTL curto;
    - opcao B: confirmacao de informacao pessoal de dominio privado.
- qualquer falha de autenticacao MUST:
  - bloquear comando;
  - abrir `SECURITY_VIOLATION_REVIEW`;
  - registrar hash do payload do update.
- controle de tentativa:
  - 3 falhas consecutivas => lock temporario de 15 minutos para comandos criticos.

## Idempotencia de Comando HITL
- cada comando Telegram MUST gerar `command_id` unico.
- reenvio do mesmo comando MUST ser no-op (sem transicao adicional de estado).
- comando com `command_id` repetido MUST ser auditado como replay.

## Timeouts e Escalation
- decision PENDING com timeout MUST escalar para humano responsavel.
- apos 2 timeouts, abrir incident de governanca.
- operacao bloqueada nao pode seguir sem estado terminal.

## Links Relacionados
- [Sprint Limits](./SPRINT-LIMITS.md)
- [Trading Enablement](../VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md)
- [Governance Risk](../CORE/GOVERNANCE-RISK.md)
