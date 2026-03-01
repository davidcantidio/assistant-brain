---
doc_id: "DEGRADED-MODE-PROCEDURE.md"
version: "1.3"
status: "active"
owner: "Security"
last_updated: "2026-02-20"
rfc_refs: ["RFC-001", "RFC-035", "RFC-050"]
---

# Degraded Mode Procedure

## Objetivo
Fornecer checklist operacional para humano atuar durante degradacao e garantir recuperacao com reconciliacao segura.

## Escopo
Inclui:
- passos operacionais durante `SYSTEM_DEGRADED`
- criterios de retorno ao modo normal
- reconciliacao offline -> Mission Control

Exclui:
- retomada sem validacao de integridade
- execucao de alto risco em degradacao

## Regras Normativas
- [RFC-035] MUST seguir checklist oficial quando modo degradado for ativado.
- [RFC-035] MUST registrar eventos em `tasks_offline.jsonl` e `incidents.log`.
- [RFC-050] MUST reconciliar e auditar antes de encerrar incidente.
- [RFC-035] SHOULD minimizar intervencao manual, priorizando reconciliacao automatica deterministica.

## Checklist Operacional
1. confirmar alerta `SYSTEM_DEGRADED`.
2. bloquear tarefas de alto risco.
3. manter apenas tarefas idempotentes de baixo risco.
4. registrar toda acao offline.
5. notificar stakeholders via Telegram (primario) ou Slack (fallback validado), se disponivel.
6. fallback Slack para HITL critico so pode ser acionado apos indisponibilidade de Telegram por > 2 heartbeats consecutivos.
7. fallback Slack acionado MUST manter controles equivalentes: assinatura HMAC valida + anti-replay + challenge.
8. se fallback Slack for acionado por degradacao de Telegram, abrir incidente/task `RESTORE_TELEGRAM_CHANNEL`.
9. se Convex estiver indisponivel ou ambos Telegram/Slack indisponiveis, registrar aviso em `human_action_required.md`.

## Checklist de Exposicao Aberta (Trading)
1. colocar sistema em `TRADING_BLOCKED` para novas entradas.
2. capturar `position_snapshot` e `open_orders_snapshot`.
3. se venue estiver acessivel:
  - cancelar ordens pendentes nao essenciais;
  - garantir `stoploss` ativo por posicao;
  - reduzir exposicao para `safe_notional` definido em `VERTICALS/TRADING/TRADING-RISK-RULES.md`.
4. se venue estiver indisponivel:
  - marcar `UNMANAGED_EXPOSURE`;
  - abrir incidente `SEV-1`;
  - registrar passos manuais obrigatorios em `human_action_required.md`.
5. registrar evidencia de cada acao (timestamp, operador/canal, resultado).

## Template de Aviso ao Humano (quando canal cair)
```md
titulo: HUMAN_ACTION_REQUIRED
dependencia_falha: "Convex|Telegram|Slack|combinado"
impacto: "quais fluxos estao bloqueados"
acoes_imediatas:
  - "passo 1"
  - "passo 2"
validacao_pos_fix:
  - "check 1"
  - "check 2"
```

## Recuperacao
1. restaurar dependencia falha.
2. validar conectividade com Convex, Telegram e Slack.
3. processar backlog offline por ordem temporal.
4. rodar reconciliador deterministico (`idempotency_key`, `replay_key`, hash-chain).
5. deduplicar e reconciliar tasks/decisions.
6. abrir fila de excecoes para casos sem resolucao automatica.
7. validar metricas de saude e encerrar degradacao.

## Criterio de Saida
- sem erro critico por 2 ciclos de heartbeat.
- fila offline zerada ou reconciliada.
- fila de excecoes manuais zerada.
- logs sincronizados e auditados.
- aprovacao do responsavel de operacao.
- para trading: posicoes e ordens reconciliadas, sem `UNMANAGED_EXPOSURE`.

## Links Relacionados
- [ARC Degraded Mode](../ARC/ARC-DEGRADED-MODE.md)
- [Incident Response](../SEC/SEC-INCIDENT-RESPONSE.md)
- [Incident Log Policy](./INCIDENT-LOG-POLICY.md)
