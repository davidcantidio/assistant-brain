---
doc_id: "ARC-MODEL-ROUTING.md"
version: "1.9"
status: "active"
owner: "Marvin"
last_updated: "2026-02-26"
rfc_refs: ["RFC-001", "RFC-010", "RFC-015", "RFC-030", "RFC-050", "RFC-060"]
---

# ARC Model Routing

## Objetivo
Definir regras executaveis de roteamento por classe de tarefa com OpenClaw gateway-first, provider routing explicito, fallback controlado, governanca por preset e trilha auditavel completa.

## Escopo
Inclui:
- OpenClaw Gateway como endpoint unico programatico
- LiteLLM como adaptador padrao para supervisores pagos
- workers locais via Ollama/vLLM para execucao bracal
- Model Catalog Service como fonte viva de metadados
- Model Router com ranking por capabilities + historico real + custo/latencia/confiabilidade
- provider selection/pin/no-fallback/fallback chain
- modo de alta confiabilidade para tool-calling critico
- exemplos minimos de implementacao

Exclui:
- benchmark de hardware em tempo real
- tuning fino de prompt por caso especifico

## Regras Normativas
- [RFC-030] MUST usar OpenClaw Gateway como ponto unico de chamada LLM programatica.
- [RFC-030] MUST bloquear chamada cloud direta a provider fora do gateway OpenClaw.
- [RFC-030] MUST escolher modelo por policy + historico + custo/latencia/confiabilidade.
- [RFC-030] MUST tratar variancia de provider como risco operacional explicito.
- [RFC-050] MUST registrar requested/effective model/provider em toda execucao.
- [RFC-015] MUST respeitar provider allowlist por sensibilidade de dado.
- [RFC-010] MUST aplicar gate de risco para rotas criticas.
- [RFC-060] MUST tratar Trading com rotas restritas e checkpoint humano.

## OpenClaw Gateway e Adapters Cloud
- endpoint canonico do runtime: Gateway OpenClaw local.
- adaptador de supervisao padrao:
  - LiteLLM (`/v1`) com aliases gerenciados por preset (`codex-main`, `claude-review`).
- adaptadores cloud adicionais:
  - OpenRouter e adaptador cloud opcional, permanece desabilitado por default e so pode ser habilitado por decision formal; quando cloud adicional estiver habilitado, OpenRouter e o preferido.
  - outro agregador cloud MAY ser habilitado somente por decision formal e com registro explicito em policy.
- cliente:
  - OpenAI SDK compativel (troca de modelo via campo `model`) pode apontar para o gateway OpenClaw.
- capacidades:
  - tools, structured outputs, reasoning e multimodal conforme suporte do modelo efetivo.

## Model Catalog Service (fonte de verdade)
### Responsabilidades
- sincronizar periodicamente o catalogo via Models API.
- versionar mudancas de:
  - preco,
  - limite de contexto/output,
  - supported parameters,
  - capabilities,
  - disponibilidade/status.
- expor API interna para o Router consultar e ranquear candidatos.

### Regras
- contrato minimo por entrada de catalogo MUST conter:
  - `model_id`, `provider`, `capabilities`, `limits`, `pricing`, `status`;
  - metadata de sync: `catalog_synced_at`, `sync_source`, `sync_interval_seconds`.
- catalogo sem timestamp atual nao pode ser usado em rota critica.
- modelo sem metrica minima de custo/latencia/confiabilidade deve ser degradado ou bloqueado.
- alteracao de schema do catalogo MUST abrir decision.

## Provider Variance e Provider Routing
### Premissa
- o mesmo `model_id` pode variar por provider em latencia, limites e comportamento.

### Politica obrigatoria
- o Router MUST aceitar parametros de provider routing:
  - `include`
  - `exclude`
  - `order`
  - `require`
- rotas criticas MAY usar `pin_provider=true`.
- rotas nao criticas podem usar order preferencial com fallback de provider permitido.

## Fallback Policy
### Cadeia declarativa por task_type
- cada `task_type` MUST ter:
  - primario
  - secundario
  - degradado
- fallback MUST registrar:
  - motivo,
  - etapa acionada,
  - impacto previsto de qualidade/custo.

### no-fallback para sensivel
- rotas `sensitive` e/ou criticas MAY marcar `no_fallback=true`.
- se rota falhar sob `no_fallback`, resultado MUST ser `blocked_with_incident`.
- rotas `sensitive` MUST usar `no_fallback=true` + `pin_provider=true` + `ZDR` obrigatorio.

## Modo de Alta Confiabilidade para Tool-Calling
- quando `tools_required=true` e risco >= medio:
  - Router SHOULD preferir variante curada de alta confiabilidade (ex.: exacto) quando disponivel.
- quando variante curada nao estiver disponivel:
  - Router MUST registrar `exacto_unavailable` e aplicar rota alternativa permitida por policy.

## Presets (governanca central)
### Definicao
- `preset` e a unidade canonica de configuracao por task_type.

### Campos minimos
- `preset_id`
- `task_type`
- `requested_model`
- `provider_routing`
- `generation_defaults`
- `fallback_chain`
- `no_fallback`
- `pin_provider`
- `exacto_mode`
- `policy_version`
- `burn_rate_policy` (`max_usd_per_hour` + `circuit_breaker_action`)
- `privacy_controls` (`retention_profile` + `zdr_enforced`)

### Regra
- agente nao escolhe modelo livremente em runtime de producao.
- runtime MUST consumir `preset_id` aprovado.

## Perfis Oficiais de Execucao
- `VPS-CLOUD` (producao): OpenClaw + LiteLLM para supervisores pagos; workers locais opcionais quando host permitir.
- `MAC-LOCAL` (dev/operacao assistida): local-first para modelos locais, com escalonamento para supervisores pagos via LiteLLM quando gate local falhar.
- Fase 0 MUST suportar `MAC-LOCAL` para tarefas pesadas nao urgentes, com supervisao por modelo robusto de assinatura em checkpoints de risco.

## Regra Operacional de Capacidade Local
- selecao local MUST usar a maior potencia disponivel que passe simultaneamente nos gates:
  - `success_rate_min`
  - `latency_p95_max`
  - `retry_rate_max`
  - `context_fit=true`
- se qualquer gate falhar para o `task_type`, Router MUST escalar para supervisor pago e registrar motivo.

## Defaults Conservadores (quando nao especificado)
- default de tipo: texto-only.
- output para consumo por maquina:
  - structured output obrigatorio ou falha controlada.
- tarefas agenticas:
  - tools obrigatorias.
- retries:
  - `max_retries = 2` com fallback rapido.
- consistencia critica:
  - `pin_provider = true`.
- tool-calling critico:
  - preferir exacto (quando disponivel).
- algoritmo de escolha:
  - com historico suficiente: rank por `cost_per_success` + confiabilidade + latencia.
  - sem historico suficiente: capabilities-first + heuristica de custo/latencia.

## Router Inputs e Outputs
### Inputs obrigatorios
- `task_type`
- `risk_class`
- `risk_tier`
- `sensitivity`
- `sla_class`
- `budget_cap`
- `tools_required`
- `structured_output_required`
- `context_tokens_estimated`

### Outputs obrigatorios
- `preset_id`
- `requested_model`
- `effective_model`
- `effective_provider`
- `provider_routing_applied`
- `fallback_step`
- `estimated_cost`
- `decision_explain`

## Ranking e Decisao
1. filtrar candidatos por policy (risco, sensibilidade, allowlist de provider, suporte tecnico).
2. aplicar constraints de SLA e budget.
3. pontuar por:
  - `cost_per_success`
  - `success_rate`
  - `tool_success_rate` (quando tools)
  - `parse_rate` (quando structured)
  - `latency_p95`
4. selecionar melhor candidato e fallback chain.
5. registrar decisao em `router_decisions`.

## Metricas Minimas por task_type/model/provider
- success_rate
- tool_success_rate
- parse_rate
- retry_rate
- timeout_rate
- cost_per_success
- latency_p95

## Formato de Saida Auditavel
- roteamento MUST gerar payload JSON com:
  - constraints de entrada,
  - candidatos avaliados,
  - ranking final,
  - decisao (`requested_model`, `effective_model`, `effective_provider`),
  - politica aplicada (`provider_routing_applied`, `risk_class`, `risk_tier`, `data_sensitivity`),
  - fallback aplicado,
  - justificativa curta.
- contrato executavel canonico: `ARC/schemas/router_decision.schema.json`.

## Integrações Externas (pacote normativo)
- integracoes externas MUST seguir contrato normativo em `INTEGRATIONS/`.
- AI-Trader MUST operar em modo `signal_only`, sem permissao de ordem direta.
- ClawWork em modo `governed` MUST usar gateway-only para chamadas LLM.
- compatibilidade com OpenClaw upstream MUST ser mantida pela matriz versionada em `INTEGRATIONS/OPENCLAW-UPSTREAM.md`.

## Exemplos Minimos de Implementacao

### 1) OpenAI SDK -> OpenClaw Gateway
```python
from openai import OpenAI
import os

client = OpenAI(
    api_key=os.environ["OPENCLAW_GATEWAY_API_KEY"],
    base_url=os.environ.get("OPENCLAW_GATEWAY_URL", "http://127.0.0.1:18789/v1"),
)

resp = client.chat.completions.create(
    model="local/code-worker",
    messages=[{"role": "user", "content": "resuma em 3 bullets"}],
)
print(resp.choices[0].message.content)
```

### 1.1) Adaptador de supervisao LiteLLM (padrao)
```python
client = OpenAI(
    api_key=os.environ["LITELLM_API_KEY"],
    base_url=os.environ.get("LITELLM_BASE_URL", "http://127.0.0.1:4000/v1"),
)

resp = client.chat.completions.create(
    model="codex-main",
    messages=[{"role": "user", "content": "revisar risco do patch"}],
)
```

### 2) Chamada com tools
```python
tools = [{
    "type": "function",
    "function": {
        "name": "lookup_policy",
        "description": "consulta politica interna",
        "parameters": {
            "type": "object",
            "properties": {"doc_id": {"type": "string"}},
            "required": ["doc_id"],
        },
    },
}]

resp = client.chat.completions.create(
    model="codex-main",
    messages=[{"role": "user", "content": "buscar policy SEC-015"}],
    tools=tools,
)
```

### 3) Structured output
```python
response_format = {
    "type": "json_schema",
    "json_schema": {
        "name": "route_result",
        "schema": {
            "type": "object",
            "properties": {
                "action": {"type": "string"},
                "risk_class": {"type": "string"}
            },
            "required": ["action", "risk_class"],
            "additionalProperties": False,
        },
    },
}

resp = client.chat.completions.create(
    model="claude-review",
    messages=[{"role": "user", "content": "classifique risco da tarefa"}],
    response_format=response_format,
)
```

### 4) Provider selection (include/order/require)
```python
resp = client.chat.completions.create(
    model="local/code-worker",
    messages=[{"role": "user", "content": "gerar patch minimo"}],
)
```

### 5) Fallback configurado por task_type (exemplo)
```yaml
task_type: "dev_patch"
fallback_chain:
  - step: 0
    model: "local/code-worker"
    provider_routing:
      order: ["ollama"]
  - step: 1
    model: "claude-review"
    provider_routing:
      order: ["litellm"]
  - step: 2
    model: "codex-main"
    provider_routing:
      order: ["litellm"]
no_fallback: false
```

### 6) Preset aplicado (exemplo)
```yaml
preset_id: "preset.dev_patch_v1"
task_type: "dev_patch"
requested_model: "local/code-worker"
provider_routing:
  order: ["ollama", "litellm"]
pin_provider: false
no_fallback: false
exacto_mode: "prefer"
generation_defaults:
  temperature: 0.1
  max_output_tokens: 1800
```

## Links Relacionados
- [ARC Core](./ARC-CORE.md)
- [Integrations](../INTEGRATIONS/README.md)
- [Models Catalog Schema](./schemas/models_catalog.schema.json)
- [Security Policy](../SEC/SEC-POLICY.md)
- [Financial Governance](../CORE/FINANCIAL-GOVERNANCE.md)
- [System Health Thresholds](../EVALS/SYSTEM-HEALTH-THRESHOLDS.md)
- [Decision Protocol](../PM/DECISION-PROTOCOL.md)
