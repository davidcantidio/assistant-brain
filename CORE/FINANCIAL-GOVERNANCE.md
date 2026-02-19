---
doc_id: "FINANCIAL-GOVERNANCE.md"
version: "1.0"
status: "active"
owner: "Frederisk"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-010", "RFC-030", "RFC-050"]
---

# Financial Governance

## Objetivo
Definir controles de custo por empresa e por tarefa, garantindo operacao previsivel e escalonamento seguro.

## Escopo
Inclui:
- teto de budget por empresa/tarefa/sprint
- alertas de consumo e rate limiting
- relatorios operacionais para acompanhamento humano

Exclui:
- contabilizacao fiscal/legal externa
- precificacao detalhada de fornecedores

## Regras Normativas
- [RFC-050] MUST registrar custo por tarefa, empresa e decision.
- [RFC-010] MUST bloquear execucao de alto risco sem budget aprovado.
- [RFC-030] MUST acionar fallback de modelo quando teto estiver proximo.
- [RFC-001] SHOULD revisar parametros de custo em ciclo semanal.
- [RFC-030] MUST considerar diferenca entre canal de assinatura (humano) e canal programatico (router).
- [RFC-030] MUST separar estrategia de custo para `single_agent` e `subagent_pod`.

## Regras de Budget
- teto por tarefa: definido no Work Order.
- teto por sprint: consolidado por escritorio.
- teto mensal por empresa: aprovado por decision.
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

## Canais de Consumo de Modelo
- canal humano por assinatura:
  - uso manual, fora do roteamento automatico.
  - nao deve ser considerado capacidade garantida para automacao.
- canal programatico (router):
  - usado para execucao automatica de tarefas.
  - MUST ter custo/latencia monitorados e versionados no catalogo de modelos.

## Custo por Pattern de Execucao
- `deterministic_script`:
  - custo de modelo tende a zero; priorizar sempre que possivel.
- `single_agent`:
  - canal economico default para tarefas simples.
  - para codigo simples, usar tier `codex-mini` como padrao.
- `subagent_pod_codex` / `subagent_pod_claude`:
  - usar apenas quando ganho esperado de qualidade justificar custo/tempo.
  - MUST respeitar limites de pod definidos no router.
- `cross_review_codex_claude`:
  - reservado para risco alto ou mudanca estrutural.

## Rate Limiting de Custo
- limitar chamadas cloud por janela de tempo.
- priorizar modelos locais para baixo risco.
- reduzir contexto e temperatura antes de escalar para cloud.
- bloquear classes nao essenciais quando incidente de custo estiver ativo.

## Integracao com Model Routing e Circuit Breaker
- custo alto repetido MUST acionar circuit breaker.
- fallback ladder MUST seguir: reduzir temp -> reduzir quant/contexto -> trocar modelo -> cloud/humano.
- qualquer override de teto MUST abrir decision com justificativa.
- router MUST registrar custo por pattern (`single_agent` vs `subagent_pod`) para calibracao semanal.

## Relatorios para Humano
- semanal:
  - custo por escritorio e top 10 tarefas por gasto
  - taxa de fallback e retrabalho por causa de custo
- mensal:
  - variacao de custo vs SLA e qualidade
  - recomendacao de rebalanceamento de budget

## Links Relacionados
- [ARC Model Routing](../ARC/ARC-MODEL-ROUTING.md)
- [ARC Observability](../ARC/ARC-OBSERVABILITY.md)
- [Work Order Spec](../PM/WORK-ORDER-SPEC.md)
- [System Health Thresholds](../EVALS/SYSTEM-HEALTH-THRESHOLDS.md)
