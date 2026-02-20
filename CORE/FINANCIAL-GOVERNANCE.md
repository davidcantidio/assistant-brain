---
doc_id: "FINANCIAL-GOVERNANCE.md"
version: "1.1"
status: "active"
owner: "Frederisk"
last_updated: "2026-02-20"
rfc_refs: ["RFC-001", "RFC-010", "RFC-030", "RFC-050"]
---

# Financial Governance

## Objetivo
Definir controles de custo por empresa e por tarefa com Budget Governor baseado em saldo de creditos OpenRouter, garantindo operacao previsivel e escalonamento seguro.

## Escopo
Inclui:
- teto de budget por run/tarefa/dia/sprint
- monitoramento de saldo e burn-rate por `credits_snapshots`
- circuit breakers de custo
- relatorios operacionais para acompanhamento humano

Exclui:
- contabilizacao fiscal/legal externa
- precificacao de fornecedor fora da politica interna

## Regras Normativas
- [RFC-050] MUST registrar custo por tarefa, empresa e decision.
- [RFC-010] MUST bloquear execucao de alto risco sem budget aprovado.
- [RFC-030] MUST acionar fallback de modelo quando teto estiver proximo.
- [RFC-050] MUST calcular budget operacional a partir de saldo de creditos OpenRouter.
- [RFC-001] SHOULD revisar parametros de custo em ciclo semanal.

## Budget Governor (creditos OpenRouter)
- entrada primaria:
  - `total_credits`, `total_usage`, `balance` via endpoint de creditos.
- tabela canonica:
  - `credits_snapshots`.
- frequencia minima:
  - snapshot a cada 5 minutos em horario operacional.

## Seguranca de Chave
- endpoint de creditos usa `OPENROUTER_MANAGEMENT_KEY`.
- essa chave MUST ficar isolada do runtime comum de agentes.
- workers de inferencia usam somente `OPENROUTER_API_KEY`.

## Regras de Budget
- teto por run: definido por preset/policy.
- teto por tarefa: definido no Work Order.
- teto diario por escritorio: definido por decision.
- teto mensal por empresa: definido por decision.
- alerta 70%: notificar PM e sugerir ajuste de roteamento.
- alerta 90%: restringir tarefas nao criticas e abrir decision.

## Baseline Inicial (Fase 0)
- perfil `VPS-CLOUD`:
  - teto diario global cloud: BRL 220.
  - teto mensal global cloud: BRL 4500.
- perfil `MAC-LOCAL`:
  - teto cloud auxiliar diario: BRL 60.
  - teto cloud auxiliar mensal: BRL 1200.
- valores sao defaults iniciais e MAY ser alterados por decision.

## Circuit Breakers de Custo
- gatilhos:
  - burn-rate horario > limite de policy
  - burn-rate diario > limite de policy
  - custo por sucesso degradado por janela consecutiva
- acoes:
  - trocar para preset economico
  - reduzir output tokens e reasoning depth
  - reduzir retries
  - bloquear tarefas nao criticas
  - abrir decision de budget quando persistente

## Custo por Pattern de Execucao
- `deterministic_script`:
  - prioridade maxima quando atender qualidade.
- `single_agent`:
  - default para tarefas simples.
- `subagent_pod`:
  - somente quando ganho esperado justificar custo/tempo.
- `cross_review`:
  - reservado para risco alto/criticidade elevada.

## Relatorios para Humano
- semanal:
  - custo total, custo por sucesso, top 10 rotas por gasto
  - burn-rate medio e picos
  - fallback por motivo de custo
- mensal:
  - variacao custo vs SLA e qualidade
  - recomendacao de rebalanceamento por preset/task_type

## Links Relacionados
- [ARC Model Routing](../ARC/ARC-MODEL-ROUTING.md)
- [ARC Observability](../ARC/ARC-OBSERVABILITY.md)
- [SEC Secrets](../SEC/SEC-SECRETS.md)
- [System Health Thresholds](../EVALS/SYSTEM-HEALTH-THRESHOLDS.md)
