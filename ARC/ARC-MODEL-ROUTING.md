---
doc_id: "ARC-MODEL-ROUTING.md"
version: "1.0"
status: "active"
owner: "Marvin"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-010", "RFC-030", "RFC-050", "RFC-060"]
---

# ARC Model Routing

## Objetivo
Definir regras executaveis de roteamento por classe de tarefa, com fallback ladder, SLA p50/p95, saida auditavel e gates por risco.

## Escopo
Inclui:
- mapeamento tarefa -> modelo local -> validacoes -> fallback -> cloud
- separacao de perfis operacionais por ambiente (VPS e Mac)
- escolha de `execution_pattern` (script, agente unico, pod de subagentes)
- criterios de abertura de decision
- tabela operacional de referencia (Tabela A)

Exclui:
- benchmark de hardware em tempo real
- tuning fino de prompt por caso especifico

## Regras Normativas
- [RFC-030] MUST iniciar no menor custo que cumpra qualidade e SLA.
- [RFC-030] MUST executar fallback ladder antes de escalar para cloud.
- [RFC-010] MUST respeitar gate de risco para aprovacoes criticas.
- [RFC-050] MUST produzir output auditavel por classe de tarefa.
- [RFC-060] MUST tratar Trading com cloud/humano obrigatorio em pontos criticos.
- [RFC-030] MUST usar token manager para estimar custo e escolher modelo dentro do budget.
- [RFC-030] MUST escolher primeiro o `execution_pattern` e depois o modelo/tier.
- [RFC-030] MUST usar `codex-mini` como default de economia para microtarefas de codigo.

## Perfis Oficiais de Execucao
- `VPS-CLOUD` (producao): cloud-first, sem dependencia de LLM local para operacao critica.
- `MAC-LOCAL` (desenvolvimento/pesquisa): local-first, com fallback cloud por risco.

## Execution Patterns
- `deterministic_script`:
  - prioridade maxima para tarefas repetiveis e idempotentes.
- `single_agent`:
  - tarefas simples, baixo risco, contexto curto.
- `subagent_pod_codex`:
  - tarefas de codigo com decomposicao em planner/implementer/tester/reviewer.
- `subagent_pod_claude`:
  - tarefas de analise/produto/politica com researcher/critic/writer.
- `cross_review_codex_claude`:
  - alto risco: um pod produz, o outro revisa.

## Matriz de Escolha de Subagentes
| Cenário | Pattern | Engine tier recomendado |
|---|---|---|
| Função simples + teste curto | `single_agent` | `codex-mini` |
| Refactor pequeno com testes | `subagent_pod_codex` | planner/implementer `codex-mini`, reviewer `codex` |
| Correção complexa em base grande | `subagent_pod_codex` | planner `codex`, implementer `codex-mini`, reviewer `codex` |
| PRD/roadmap com riscos e trade-offs | `subagent_pod_claude` | researcher/writer `claude-code-default`, critic `claude-code-strong` |
| Mudança crítica (risco alto) | `cross_review_codex_claude` | produção em um pod + revisão no outro |

## Limites de Pod (custo e previsibilidade)
- `max_subagents_per_pod = 4`
- `max_pod_rounds = 2`
- `max_pod_runtime_seconds = 900`
- `stop_on_convergence = true`
- se exceder qualquer limite:
  - degradar para `single_agent`;
  - ou abrir decision para continuidade.

## Tabela A - Classes de Tarefa x Execucao x Modelos/Quants x Validacoes
| Classe de tarefa | SLA alvo | Padrao de execucao | Perfil VPS (cloud-first) | Perfil Mac (local-first) | Quant Mac recomendada (32GB) | Contexto recomendado | Temperatura/Decoding | Saida auditavel | Verificacao deterministica | Gate cloud/humano |
|---|---:|---|---|---|---|---:|---|---|---|---|
| Dispatcher/Router | 0.5-3s | `single_agent` rapido | GPT-5.2 mini/pro para roteamento | Llama 3.x 3B | MLX BF16 ou Q8 | 2k-8k | temp 0-0.3, top_p baixo | JSON fixo com schema | JSON Schema + regras de roteamento | Cloud obrigatoria em risco alto |
| PM Operacional (Scrum) | 10-60s | `subagent_pod_claude` (estrutura -> critica) | Claude Code (default + strong) | Mistral Small 3.1 24B Instruct | Q4_K_M ou Q5_K_M | 8k-32k | stage1 0.2; stage2 0.1 | YAML + IDs | lint YAML + checklist Scrum | Revisao cloud obrigatoria |
| RAG Librarian (empresa) | 5-30s | 2-stage (triagem -> resposta) | GPT-4.1 para casos criticos | Qwen2.5 7B Instruct | Q5_K_M/Q6 ou MLX 4-bit | triagem 8k; resposta 16k-32k | triagem 0; resposta 0.1-0.3 | resposta + citacoes doc_id/chunk_id | claim->fonte + dedupe + score minimo | Cloud em caso critico |
| RAG Geral do Condominio | 2-8s | 1-stage rapido | GPT-5 mini quando necessario | Llama 3.x 3B | Q8/BF16 | 4k-16k | temp 0 | JSON com links internos e versao | validacao de versao (sem drift) | Cloud opcional |
| Dev Junior Local | 15-90s | simples: `single_agent`; complexo: `subagent_pod_codex` | simples: `codex-mini`; complexo/review: `codex` | Codestral ou Qwen2.5 7B/Mistral 24B | 7B: Q5_K_M; 24B: Q4_K_M/Q5_K_M | 8k-16k | temp 0-0.2 + stop tokens | diff/patch + testes | pytest + lint + typecheck + no network | Review cloud para merge |
| Tech Lead (codigo) | minutos | `cross_review_codex_claude` ou cloud-first | `codex`/`gpt-5-codex` + revisao `claude-code-strong` | - | - | - | - | review de PR com criterios | CI + seguranca | Cloud obrigatoria |
| Execucao deterministica (ETL/validacao) | depende | script-first | script + auditoria cloud pontual | script + LLM glue local | - | - | temp 0 | artifacts + logs | testes + idempotencia + checksum | Script prevalece |
| Raciocinio pesado offline | 60-300s | 3-stage | GPT-5.2 pro (decisao final) | Mistral Small 3.1 24B | Q5_K_M | 16k-64k controlado | temp 0 + verify pass | resposta + claims checklist | consistencia + RAG para fatos | Cloud em decisao final |
| Design Office (texto->prompt imagem) | 10-60s | 2-stage | OpenAI Images + revisao cloud | Mistral Small 3.1 24B (texto) | Q4_K_M/Q5_K_M | 8k-16k | temp 0.4 com constraints | prompt + negativos + parametros | validacao de formato e seed | Checkpoint humano em risco reputacional |

## Escopo MVP de Roteamento (Fase 0)
- Classes ativas no MVP:
  - Dispatcher/Router
  - RAG Librarian (empresa)
  - Dev Junior Local
- Demais classes operam em modo cloud-first simplificado ate estabilizar SLO da Fase 0.

## Token Manager (Router)
- objetivo:
  - minimizar custo mantendo SLA e qualidade minima.
- entradas obrigatorias:
  - classe de tarefa, risco, SLA, contexto estimado (tokens), budget disponivel.
- saidas:
  - `execution_pattern` escolhido;
  - modelo escolhido;
  - custo estimado;
  - fallback previsto;
  - motivo da escolha (auditavel).

## Session Manager (Assisted Orchestration)
- para `subagent_pod_codex` e `subagent_pod_claude`, MUST controlar:
  - capacidade de sessoes simultaneas;
  - tempo humano disponivel;
  - fila de pods pendentes.
- router MUST evitar iniciar pod se a fila assisted ultrapassar limite operacional.

## Catalogo de Modelos (fonte de verdade)
- MUST manter tabela versionada em banco (ex.: `models_catalog`) com:
  - `model_id`
  - `provider`
  - `cost_input_per_1k`
  - `cost_output_per_1k`
  - `latency_p50`
  - `latency_p95`
  - `quality_score_por_classe`
  - `max_context`
  - `status` (active/degraded/disabled)
- router MUST recusar modelo sem metrica/custo atualizado.

## Algoritmo de Escolha (custo-prioritario)
1. escolher `execution_pattern` por risco/complexidade/SLA.
2. para canais programaticos, filtrar modelos que atendem risco/politica/SLA.
3. estimar custo por tarefa com tokens previstos.
4. escolher menor custo com `quality_score` acima do minimo da classe.
5. para tarefas simples de codigo, preferir `codex-mini`.
6. se nenhum atender, abrir fallback ladder e/ou decision.

## SLA p50/p95 por Classe
- Dispatcher: p50 <= 1s, p95 <= 3s
- RAG Geral: p50 <= 3s, p95 <= 8s
- RAG Empresa: p50 <= 12s, p95 <= 30s
- PM/Dev local: p50 <= 30s, p95 <= 90s
- Raciocinio pesado: p50 <= 180s, p95 <= 300s

## Fallback Ladder (ordem obrigatoria)
1. reduzir temperatura e output token.
2. reduzir contexto para janela segura.
3. (perfil Mac) trocar quantizacao para perfil mais rapido.
4. (perfil Mac) trocar modelo local da mesma classe.
5. escalar para cloud conforme risco.
6. abrir decision se houver impacto de risco/custo/prazo.

## Quando abrir Decision
- risco alto ou acao em ambiente real
- mais de 2 fallbacks sem sucesso
- custo estimado acima do teto da tarefa
- alteracao de modelo padrao de classe critica

## Formato de Saida Auditavel por Classe
- roteamento: JSON com schema e justificativa.
- PM: YAML de epicos/sprints/tasks com IDs.
- RAG: resposta com claims e citacoes.
- DEV: patch + resultado de teste.
- decisao: proposta, evidencias, risco, custo e status.

## Links Relacionados
- [ARC Core](./ARC-CORE.md)
- [Governance Risk](../CORE/GOVERNANCE-RISK.md)
- [Financial Governance](../CORE/FINANCIAL-GOVERNANCE.md)
- [System Health Thresholds](../EVALS/SYSTEM-HEALTH-THRESHOLDS.md)
- [Decision Protocol](../PM/DECISION-PROTOCOL.md)
