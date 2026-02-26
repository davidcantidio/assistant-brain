---
doc_id: "ARC-DEGRADED-MODE.md"
version: "1.3"
status: "active"
owner: "Frederisk"
last_updated: "2026-02-20"
rfc_refs: ["RFC-001", "RFC-015", "RFC-035", "RFC-050"]
---

# ARC Degraded Mode

## Objetivo
Definir tolerancia a falhas com degradacao graciosa, preservando seguranca e continuidade operacional minima.

## Escopo
Inclui:
- deteccao de falha e evento `SYSTEM_DEGRADED`
- operacao offline controlada
- reconciliacao apos restauracao

Exclui:
- bypass de controles de risco alto
- execucao sem logs durante incidente

## Regras Normativas
- [RFC-035] MUST emitir evento `SYSTEM_DEGRADED` na deteccao de falha critica.
- [RFC-035] MUST registrar operacoes offline em trilha local persistente.
- [RFC-015] MUST bloquear acoes de alto risco durante degradacao.
- [RFC-050] MUST reconciliar logs offline no Mission Control apos retorno.
- [RFC-035] MUST reconciliar com chave de replay deterministica para evitar duplicidade.
- [RFC-035] MUST executar reconciliacao automatica deterministica antes de qualquer passo manual.

## Deteccao e Ativacao
- gatilhos: indisponibilidade do Convex, falha Telegram/Slack, erro de persistencia, timeout sistemico.
- ao detectar:
  - abrir estado global `SYSTEM_DEGRADED`.
  - publicar alerta local e remoto (quando possivel).
  - reduzir execucao para modo seguro.

## Canal Offline Obrigatorio
- `tasks_offline.jsonl`: fila de tarefas e eventos nao sincronizados.
- `incidents.log`: trilha cronologica de falhas, tentativas e impacto.
- `human_action_required.md`: instrucoes objetivas para recuperacao humana.

## Modo Seguro
- bloquear: alto risco, mudanca de politica, acesso ampliado de dados, trading live.
- permitir: tarefas de baixo risco idempotentes e de manutencao.
- medio risco: somente com validacao deterministica estrita.

## Trading com Posicao Aberta em Degradacao
- regra geral:
  - degradacao com exposicao aberta MUST entrar em `TRADING_BLOCKED` para novas entradas.
  - objetivo primario passa a ser protecao de capital e reconciliacao de estado.
- quando venue estiver acessivel:
  - cancelar ordens pendentes nao essenciais.
  - manter/atualizar ordens de protecao (`stoploss`) para toda posicao aberta.
  - reduzir exposicao para `safe_notional` definido em `VERTICALS/TRADING/TRADING-RISK-RULES.md`.
  - registrar `position_snapshot` antes/depois de cada acao.
- quando venue estiver indisponivel:
  - marcar estado `UNMANAGED_EXPOSURE`.
  - abrir incidente `SEV-1` imediatamente.
  - emitir `human_action_required.md` com passos de contingencia manual.
- retorno ao normal:
  - so apos reconciliacao completa de ordens/posicoes e aprovacao HITL.

## Regra de Usuario (obrigatoria)
- "se algo cair, informar e criar tarefas pro humano consertar" MUST ser aplicada assim:
  - registrar evento offline imediatamente;
  - notificar humano quando houver canal disponivel;
  - quando Convex indisponivel ou ambos Telegram/Slack indisponiveis, gravar instrucoes em `human_action_required.md` com:
    - dependencia falha;
    - impacto atual;
    - passos de recuperacao;
    - criterio de validacao pos-recuperacao;
  - quando apenas Telegram estiver indisponivel e Slack estiver saudavel:
    - migrar HITL critico para Slack somente com fallback validado:
      - operador habilitado com `slack_user_ids` e `slack_channel_ids` nao vazios;
      - challenge + assinatura HMAC + anti-replay obrigatorios;
      - abrir incidente/task `RESTORE_TELEGRAM_CHANNEL` ate retorno do canal Telegram;
    - manter trilha de `command_id` idempotente por canal;
  - criar `task` e `decision` de correcao no retorno do sistema.

## Reconciliacao apos Retorno
1. validar integridade de `tasks_offline.jsonl` e `incidents.log`.
2. reprocessar eventos em ordem temporal.
3. deduplicar por `idempotency_key` e `replay_key`.
4. reabrir tasks/decisions pendentes.
5. encerrar modo degradado com evidencias de saude.

## Chave de Replay Canonica
- `replay_key = work_order_id + ":" + task_id + ":" + event_type + ":" + attempt`
- qualquer evento com `replay_key` repetida MUST ser ignorado e auditado.

## Reconciliacao Manual por Excecao
- reconciliacao manual SHOULD ocorrer apenas quando:
  - houver conflito de estado sem resolucao deterministica;
  - houver divergencia entre hash local e hash remoto;
  - houver efeito colateral externo nao idempotente.
- todo caso manual MUST gerar:
  - `incident` com causa raiz;
  - `decision` de correcao;
  - teste/regra nova para evitar recorrencia.

## Links Relacionados
- [Incident Procedure](../INCIDENTS/DEGRADED-MODE-PROCEDURE.md)
- [Incident Response](../SEC/SEC-INCIDENT-RESPONSE.md)
- [ARC Observability](./ARC-OBSERVABILITY.md)
