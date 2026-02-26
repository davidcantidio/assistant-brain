---
doc_id: "PRD-MASTER.md"
version: "1.14"
status: "active"
owner: "Marvin"
last_updated: "2026-02-24"
rfc_refs: ["RFC-001", "RFC-010", "RFC-015", "RFC-020", "RFC-025", "RFC-030", "RFC-035", "RFC-040", "RFC-050", "RFC-060"]
---

# PRD Master

## Objetivo
Definir a constituicao executiva do OpenClaw Agent OS com governanca por risco, auditabilidade ponta a ponta e operacao implementavel com OpenClaw gateway-first (providers plugaveis).

## Escopo
Inclui:
- visao de produto, organizacao, governanca de risco e fases 0/1/2
- arquitetura alvo consolidada (OpenClaw gateway + Model Router + memoria vetorial hibrida)
- regras de privacidade/retencao/provider allowlist/ZDR
- budget governor baseado em saldo de creditos

Exclui:
- codigo de implementacao detalhado
- playbook de tuning fino por prompt
- detalhes de UI fora da operacao minima

## Regras Normativas
- [RFC-001] MUST usar termos normativos MUST/SHOULD/MAY em toda a stack documental.
- [RFC-010] MUST aplicar aprovacao proporcional ao risco (baixo, medio, alto).
- [RFC-015] MUST tratar seguranca como enforceable (sandbox, allowlist, redaction e secrets).
- [RFC-020] MUST executar colaboracao entre empresas via Work Order formal.
- [RFC-025] MUST operar RAG com isolamento por empresa e citacao por claim.
- [RFC-030] MUST adotar model routing com fallback controlado e SLA p50/p95.
- [RFC-035] MUST operar degraded mode com trilha offline e reconciliacao posterior.
- [RFC-040] MUST limitar Scrum (sprint/task) com override somente por decision.
- [RFC-050] MUST registrar observabilidade e auditoria por tarefa/empresa/decisao.
- [RFC-060] MUST tratar Trading como vertical de alto risco estrutural.

## Status de Maturidade (2026-02-24)
- estado atual do repo: **planejamento/PRD**, sem control-plane implementado.
- isso e esperado na fase atual e NAO caracteriza falha por si so.
- risco real: iniciar automacoes sem contrato executavel de idempotencia, rollback, eval gate e politica de privacidade.

## Arquitetura Alvo Consolidada
- gateway programatico principal: **OpenClaw Gateway** (loopback-first e contratos de policy no runtime).
- stack de roteamento para supervisao: **LiteLLM** como adaptador padrao de modelos pagos (`codex-main` primario, `claude-review` secundario).
- stack de execucao bracal: workers locais via Ollama/vLLM (`qwen2.5-coder:32b`, `deepseek-r1:32b`) com escalonamento por gates de capacidade.
- OpenRouter e adaptador cloud opcional, permanece desabilitado por default e so pode ser habilitado por decision formal; quando cloud adicional estiver habilitado, OpenRouter e o preferido.
- plano de execucao:
  - `Control Plane`: Convex + runtime + adapters de canal (Telegram primario para HITL critico; Slack para colaboracao operacional e fallback controlado de HITL; Discord/Signal/iMessage opcionais por policy).
  - `Router Plane`: Model Router + Presets + Policy Engine.
  - `Memory Plane`: banco vetorizado hibrido unico (Postgres + pgvector ou equivalente) para catalogo de modelos, runs e decisoes de roteamento.
- `Model Catalog Service` MUST sincronizar catalogo de modelos/provedores/capacidades/precos/limites.
- `Budget Governor` MUST usar a telemetria de custo consolidada do LiteLLM + snapshots financeiros do provedor efetivo habilitado por policy.

### Papeis de Agentes
Esta subsecao define papeis funcionais para executar o [Paradigma de Execucao: Microtasks e Delegacao Sob Demanda](#paradigma-de-execucao-microtasks-e-delegacao-sob-demanda), respeitando [Governanca de Risco (Nivel Alto)](#governanca-de-risco-nivel-alto) e [Regra de Testabilidade de Claims Centrais](#regra-de-testabilidade-de-claims-centrais).

#### 1) Orchestrator (controlador deterministico)
- Responsabilidades:
  - gerenciar fila de execucao, estado do DAG e ordem deterministica de processamento;
  - aplicar patch/diff somente apos validacoes obrigatorias;
  - coordenar retry, rollback e reconciliacao em caso de falha.
- Entradas:
  - DAG de microtasks tipado;
  - politicas de risco/execucao e sinais de validadores.
- Saidas:
  - transicoes de estado por microtask (`Queued`, `Running`, `Failed(Triage)`, `Blocked(NeedsInput)`, `Verified`, `Applied/Merged`, `RolledBack`);
  - artifacts de execucao (diff aplicado, logs, motivo de rollback).
- Limites (NAO pode):
  - reescrever objetivo/escopo da microtask;
  - aprovar excecao de alto risco sem gate;
  - ignorar falha de validador para forcar progresso.

#### 2) Decomposer/Planner
- Responsabilidades:
  - converter Issue em DAG de microtasks atomicas com dependencias explicitas;
  - produzir contratos de entrada/saida tipados por microtask;
  - definir checkpoints de validacao e criterios de aceite por no.
- Entradas:
  - issue/requisito aprovado;
  - politicas de escopo, risco e DoD.
- Saidas:
  - DAG tipado com `microtask_id`, dependencias, escopo e criterios verificaveis.
- Limites (NAO pode):
  - executar mudancas de codigo;
  - aprovar bypass de limite de escopo;
  - criar microtask sem criterio de aceite verificavel.

#### 3) Worker LLM Local
- Responsabilidades:
  - executar UMA microtask por vez, dentro do escopo declarado;
  - gerar saida estritamente tipada (ex.: diff estruturado ou JSON valido);
  - reportar falha explicita quando nao conseguir cumprir contrato.
- Entradas:
  - contrato da microtask (escopo, contexto minimo, formato de saida).
- Saidas:
  - proposta de mudanca tipada + justificativa curta + status de execucao.
- Limites (NAO pode):
  - ampliar escopo por conta propria;
  - editar arquivos fora de `scope_files`;
  - marcar propria saida como aprovada.

#### 4) Verifier
- Responsabilidades:
  - executar checks automaticos (sintaxe, schema, testes, politicas, seguranca);
  - classificar falhas por tipo e severidade;
  - devolver feedback acionavel para retry ou rollback.
- Entradas:
  - saida tipada do Worker;
  - suite de validadores e regras de policy.
- Saidas:
  - relatorio de verificacao (`pass/fail`), erros classificados e recomendacao (`retry/rollback/escalate`).
- Limites (NAO pode):
  - alterar codigo diretamente;
  - converter `fail` em `pass` sem nova evidencia;
  - dispensar check obrigatorio de risco/compliance.

#### 5) Gatekeeper/Reviewer
- Responsabilidades:
  - decidir aprovacao final para mudancas de alto risco ou fora de playbook;
  - validar aderencia a risco, compliance, impacto operacional e rastreabilidade;
  - autorizar promote, bloqueio ou rollback em casos criticos.
- Entradas:
  - pacote de evidencia (plano, diff, resultado de verificadores, trilha de execucao).
- Saidas:
  - decisao formal (`approved/rejected/needs_changes`) com justificativa auditavel.
- Limites (NAO pode):
  - aprovar sem evidencias minimas de verificacao;
  - ocultar fallback, erro ou excecao de policy;
  - delegar decisao critica sem registrar trilha.

## Paradigma de Execucao: Microtasks e Delegacao Sob Demanda
- Definicao de `Microtask`:
  - unidade atomica de trabalho com um objetivo verificavel, entrada explicita, saida esperada e criterio de aceite objetivo.
  - toda microtask MUST declarar `scope_files`, `scope_lines`, `risk_level`, `rollback_hint` e `idempotency_key`.
- Terminologia canonica:
  - `Issue` = unidade de planejamento e entrega auditavel no backlog.
  - `Microtask` = unidade atomica de execucao dentro de uma Issue.
  - `task` e termo generico e NAO substitui `Issue`/`Microtask` em contratos, estados e gates.
- Objetivos operacionais:
  - reduzir erro silencioso por limitar superficie de mudanca.
  - aumentar rastreabilidade por microtask (quem delegou, quem executou, qual modelo, qual resultado).
  - habilitar paralelizacao segura sem conflito de estado.
- Modos de execucao:
  - `Rotina (playbooks)`: usa playbooks pre-aprovados para tarefas recorrentes e de baixo risco; fluxo deterministico e validacoes padrao.
  - `Sob Demanda (delegacao por Agente Superior)`: usado quando nao existe playbook valido, quando risco/contexto muda, ou quando ha falha repetida; o Agente Superior decompoe trabalho em microtasks menores com checkpoints explicitos.
- Modelo de fluxo MUST ser DAG (`Directed Acyclic Graph`), nao lista linear:
  - cada no = uma microtask; cada aresta = dependencia formal de dados/estado.
  - uma microtask so inicia quando todas as dependencias de entrada estiverem em estado de sucesso (`Verified` ou `Applied/Merged`).
  - nos sem dependencia direta podem executar em paralelo, desde que `scope_files` nao conflite.
  - deteccao de conflito MUST bloquear execucao paralela no mesmo arquivo/regiao e forcar serializacao.
- Trade-offs operacionais:
  - custo/overhead sobe (mais planejamento, mais orquestracao, mais logs por unidade).
  - risco de erro silencioso cai (menor blast radius, maior capacidade de replay, rollback e auditoria por passo).
- Regras de escopo por tipo de microtask:
  - `Rotina`: maximo de 2 arquivos e 120 linhas alteradas por microtask; proibido refactor estrutural, mudanca de schema, upgrade de dependencia e automacao com efeito colateral nao previsto em playbook.
  - `Sob Demanda`: maximo de 4 arquivos e 240 linhas alteradas por microtask; proibido refactor cross-modulo, mudanca de arquitetura, migration de dados e alteracao de policy sem aprovacao explicita.
  - qualquer necessidade acima desses limites MUST ser quebrada em novo DAG de microtasks ou escalada para decisao formal antes da execucao.

## Contrato de Microtask (Task Spec)
`Task Spec` e o contrato tipado minimo entre Decomposer, Orchestrator, Worker, Verifier e Gatekeeper.

Campos obrigatorios:
- `id`: identificador unico e imutavel da microtask.
- `title`: titulo objetivo e verificavel.
- `type`: tipo da microtask (enum obrigatorio).
- `inputs`: referencias de entrada necessarias (arquivos, artifacts, ids, contexto minimo).
- `constraints`: limites operacionais da execucao (escopo, proibicoes, budget tecnico, politicas).
- `output_contract`: formato de saida permitido + regras de validacao da saida.
- `acceptance`: criterios de aceite objetivos e verificaveis.
- `validators`: lista ordenada de validadores automaticos obrigatorios.
- `retry_policy`: politica de retry/rollback para falha transiente ou deterministica.
- `risk`: classificacao de risco e requisitos de gate.

Output formats permitidos:
- `unified_diff`: patch aplicavel e validavel automaticamente.
- `json`: payload JSON valido contra schema definido no contrato.
- texto livre fora desses formatos e proibido.

Tipos de microtask (enum):
- `plan_fragment`
- `code_change`
- `test_change`
- `config_change`
- `doc_change`
- `triage`
- `verify`

Regras de `NEEDS_INPUT`:
- o Worker MUST retornar `NEEDS_INPUT` quando faltar contexto essencial para cumprir `acceptance` ou `output_contract`.
- gatilhos minimos de `NEEDS_INPUT`: entrada ausente em `inputs`, conflito de `constraints`, ambiguidade que gera mais de uma interpretacao valida, dependencia externa indisponivel.
- ao receber `NEEDS_INPUT`, o Orchestrator MUST:
  - marcar a microtask como `blocked_needs_input` sem consumir tentativa de `retry_policy`;
  - registrar `missing_inputs` tipado (campo, motivo, severidade, origem);
  - encaminhar solicitacao para a fonte correta (Decomposer para escopo/plano, Gatekeeper para excecao de risco, humano para dado externo);
  - reexecutar a mesma microtask (mesmo `id`) apos completar contexto, preservando `idempotency_key` e trilha de auditoria.

Exemplo compacto (JSON):
```json
{
  "id": "MT-0001",
  "title": "Adicionar validacao de schema para task spec",
  "type": "test_change",
  "inputs": {
    "issue_id": "OC-EVAL-012",
    "references": ["PM/WORK-ORDER-SPEC.md"]
  },
  "constraints": {
    "scope_files": ["EVALS/RAG-EVALS-TESTS.md"],
    "scope_lines_max": 120,
    "forbidden": ["refactor", "dependency_upgrade"]
  },
  "output_contract": {
    "format": "unified_diff",
    "target_files": ["EVALS/RAG-EVALS-TESTS.md"]
  },
  "acceptance": [
    "patch aplica limpo",
    "teste novo cobre o schema minimo",
    "nenhuma mudanca fora de scope_files"
  ],
  "validators": ["lint", "unit_tests", "policy_scope"],
  "retry_policy": {
    "max_retries": 2,
    "strategy": "bounded_retry",
    "rollback_on_fail": true
  },
  "risk": {
    "level": "low",
    "requires_gatekeeper": false
  }
}
```

### Escalonamento para Agente Superior (Sob Demanda)
Triggers objetivos de escalonamento:
- `retry_count > retry_policy.max_retries`.
- falha `flaky`: alternancia `pass/fail` em 2+ execucoes com mesmo `inputs` e mesmo contrato.
- escopo estourado: diff proposto excede `scope_lines_max` ou toca arquivo fora de `scope_files`.
- conflito de checks: validadores obrigatorios retornam bloqueio nao resolvido no mesmo ciclo.
- mudanca de contrato apos fila: alteracao de `output_contract`, `acceptance` ou `risk`.
- risco alto (`R2` ou `R3`).
- `NEEDS_INPUT` recorrente: 2+ ciclos `blocked_needs_input` para a mesma microtask.

O que o Agente Superior PRODUZ (obrigatorio):
- `superior_decision` tipada (`decision_id`, `action`, `reason_code`, `risk_level`, `required_gates`).
- DAG atualizado e versionado (`dag_version`), com novos nos/arestas e estado alvo por microtask.
- diretriz operacional para o Orchestrator (`retry`, `rollback`, `replan`, `abort`, `escalate_gate`).
- sem artefato tipado, a decisao e invalida.

Politica de retry/rollback:
- replanejar (`replan`) quando a causa raiz for estrutural: contrato incompleto, dependencia faltante, escopo estourado ou conflito recorrente de checks.
- abortar (`abort`) quando houver risco inaceitavel sem mitigacao valida, efeito colateral sem rollback garantido, ou gate obrigatorio indisponivel.
- retry simples somente para falha transiente, abaixo do limite de tentativas e sem novo side effect.
- rollback imediato quando houver aplicacao parcial com falha de gate obrigatorio ou suspeita de side effect indevido.

### Auditabilidade do Paradigma
Estrutura sugerida de artifacts por execucao:
- `runs/<issue_id>/<microtask_id>/`
  - `input.json`
  - `prompt.txt`
  - `output.diff` (ou `output.json`, conforme `output_contract`)
  - `verify.log`
  - `status.json`

Requisitos obrigatorios:
- replay deterministico quando possivel: mesma versao de Task Spec, mesma policy/preset, mesmos validadores, mesmo estado de entrada.
- versionamento do estado do Orchestrator em toda transicao de status (`state_version`), com historico de `from_state -> to_state`.
- trilha formal de aprovacao do Gatekeeper para gates exigidos (`decision_id`, aprovador, timestamp, motivo, evidencia vinculada).

Fonte da verdade operacional:
- `output.diff`/`output.json` + `verify.log` + `status.json` sao a base oficial de auditoria e reconciliacao.
- texto narrativo de LLM nao e fonte de verdade para promote/merge/release.

### Canal Slack (colaboracao operacional)
- escopo:
  - Slack e canal oficial para colaboracao diaria e delegacao por `@mention` entre agentes.
  - Telegram e canal HITL primario para comandos criticos (`approve/reject/kill`).
  - Slack pode atuar como fallback HITL somente quando Telegram estiver degradado.
- contrato:
  - evento de `@mention` no Slack MUST ser normalizado para `task_event` com `idempotency_key`, `trace_id` e autor.
  - repeticao do mesmo evento (retry/webhook duplicado) MUST ser `NO_OP_DUPLICATE`.
  - thread do Slack MUST mapear para `issue_id`/`microtask_id` quando existir contexto.
  - `thread_context` do evento normalizado, quando presente, MUST incluir `issue_id` e `microtask_id`.
- governanca:
  - Slack nao pode aprovar gate de risco alto por texto livre.
  - fallback HITL em Slack exige assinatura valida do request + allowlist de operador + challenge de segundo fator.
  - `R2`/`R3` e side effects seguem obrigatoriamente `Review/Gate` e trilha formal.
- fonte de verdade:
  - mensagem de Slack e sinal de entrada/colaboracao.
  - estado final de execucao continua em artifacts e logs canonicos do Orchestrator.

### Contrato Canonico `openclaw_runtime_config`
O runtime MUST manter contrato de configuracao versionado com os campos minimos abaixo:
- concorrencia e agentes:
  - `agents.defaults.maxConcurrent`
  - `agents.defaults.subagents.maxConcurrent`
- agent-to-agent:
  - `tools.agentToAgent.enabled`
  - `tools.agentToAgent.allow[]` (allowlist obrigatoria de delegacao)
  - `tools.agentToAgent.maxConcurrent` (limite de concorrencia por delegacao)
  - `tools.agentToAgent.maxCostUsd` (limite de custo por delegacao)
  - `tools.agentToAgent.serialFallbackOnConflict` (fallback para fila serial em conflito)
- canais:
  - `channels.telegram`
  - `channels.slack`
  - `channels.discord`
  - `channels.signal`
  - `channels.imessage`
- hooks:
  - `hooks.enabled`
  - `hooks.mappings[]` (webhooks externos -> evento interno)
  - `hooks.internal.entries[]` (`boot-md`, `command-logger`, `session-memory`)
- memoria:
  - `memory.backend = qmd`
  - `memory.qmd.paths[]`
  - `memory.qmd.update.interval`
- gateway:
  - `gateway.bind = loopback`
  - `gateway.control_plane.ws` (canonico)
  - `gateway.http.endpoints.chatCompletions.enabled` (opcional sob policy)

Regras mandatarias de evento A2A/Webhook:
- evento A2A cross-workspace MUST registrar `source_workspace`, `target_workspace`, `max_concurrency`, `max_cost_usd` e `serial_fallback_on_conflict`.
- webhook Slack normalizado com contexto de thread MUST registrar `issue_id` + `microtask_id`.

### Contrato `routing_stack_contract`
```yaml
schema_version: "1.0"
gateway:
  primary: "openclaw"
  supervisor_adapter: "litellm"
  cloud_optional: "disabled"
```

Regras mandatarias:
- `gateway.primary` MUST permanecer OpenClaw em todos os ambientes.
- `gateway.supervisor_adapter` MUST ser LiteLLM para chamadas de supervisores pagos.
- `gateway.cloud_optional` default MUST ser `disabled`; habilitacao de cloud adicional exige decision formal.

### Contrato `supervisor_contract`
```yaml
schema_version: "1.0"
supervisors:
  primary: "litellm/codex-main"
  secondary: "litellm/claude-review"
roles:
  - approval
  - critique
  - correction
  - delegation
  - risk_review
```

Regras mandatarias:
- tarefas de aprovacao, critica, correcao e risco MUST passar por supervisor pago.
- alias de supervisor MUST ser resolvido por preset versionado (sem `model_id` hardcoded por agente).

### Contrato `local_worker_contract`
```yaml
schema_version: "1.0"
workers:
  local:
    code: "ollama/qwen2.5-coder:32b"
    reason: "ollama/deepseek-r1:32b"
policy:
  max_local_power_mode: true
```

Regras mandatarias:
- tarefa bracal (`code_change`, `doc_change`, `triage`, `verify`) SHOULD executar local-first.
- selecao local MUST usar a maior potencia disponivel que passe nos gates de capacidade.

### Contrato `capacity_guard_contract`
```yaml
schema_version: "1.0"
gates:
  success_rate_min: 0.85
  latency_p95_max_ms: 120000
  retry_rate_max: 0.15
  context_fit: true
```

Regras mandatarias:
- qualquer falha de gate local MUST bloquear persistencia local para `task_type` afetado e escalar para supervisor pago.
- capacidade local MUST considerar memoria efetiva, `num_ctx`, KV cache e latencia alvo.

### Contrato `fallback_contract`
```yaml
schema_version: "1.0"
order:
  - "local_worker"
  - "litellm/claude-review"
  - "litellm/codex-main"
audit_fields:
  - requested_model
  - effective_model
  - fallback_step
  - reason
```

Regras mandatarias:
- cada execucao MUST registrar `requested_model`, `effective_model`, `fallback_step` e `reason`.
- `task_type` critico MAY inverter a ordem de fallback por preset aprovado, sem remover auditoria obrigatoria.

Regras de hardening do gateway:
- runtime exposto externamente MUST permanecer `bind=loopback` e ser publicado apenas por tunel/autenticacao na borda.
- endpoint `chatCompletions` MAY ficar habilitado para interoperabilidade, mas MUST obedecer as mesmas policies de risco/allowlist/auditoria do runtime.

### Contrato de Hooks e Webhooks
- webhook externo MUST ser mapeado por `hooks.mappings[]` com transform explicita para evento interno tipado.
- evento de webhook MUST carregar `trace_id`, `idempotency_key` e `source_hook_id`.
- hooks internos (`boot-md`, `command-logger`, `session-memory`) SHOULD ficar ativos por default no workspace principal.
- webhook sem mapping valido ou sem assinatura exigida pela policy MUST ser bloqueado e auditado.

### Contrato `approval_policy`
```yaml
schema_version: "1.0"
financial_side_effect_requires_explicit_human_approval: true
email_command_channel_trusted: false
trusted_instruction_channels:
  - "telegram"
  - "slack_fallback_validado"
```

Regras mandatarias:
- toda acao com side effect financeiro exige aprovacao humana explicita sempre (sem excecao por fase).
- email e canal de informacao; nunca canal confiavel de comando.
- instrucao recebida por email MUST exigir confirmacao em canal confiavel antes de qualquer execucao.

### Contrato `memory_contract`
```yaml
schema_version: "1.0"
tacit_memory_file: "workspaces/main/MEMORY.md"
daily_notes_path: "workspaces/main/memory/YYYY-MM-DD.md"
nightly_extraction:
  name: "nightly-extraction"
  schedule: "0 23 * * *"
  timezone: "America/Sao_Paulo"
  required: true
semantic_backend:
  backend: "qmd"
  update_interval: "5m"
nightly_cycle_audit:
  job_name: "nightly-extraction"
  scheduled_at: "ISO-8601"
  executed_at: "ISO-8601"
  timezone: "America/Sao_Paulo"
  daily_note_ref: "workspaces/main/memory/YYYY-MM-DD.md"
  status: "success|failed|delayed|skipped"
  incident_ref: "INC-XXX|null"
```

Regras mandatarias:
- `MEMORY.md` MUST existir e registrar padroes operacionais duraveis.
- notas diarias MUST ser atualizadas por ciclo noturno com decisoes, mudancas de status e fatos duraveis.
- extracao noturna sem sucesso por 24h MUST abrir incident operacional.
- cada execucao do ciclo noturno MUST registrar `scheduled_at`, `executed_at`, `daily_note_ref`, `status` e `incident_ref` quando houver falha/atraso >24h.

### Contrato `ops_autonomy_contract`
```yaml
schema_version: "1.0"
contract_version: "v1"
isolation_mode: "tmux"
healthcheck_interval_minutes: 15
stalled_threshold_checks: 2
restart_policy:
  mode: "controlled_restart"
  max_restarts: 3
  restart_backoff_seconds: 30
  requires_trace_id_log: true
incident_on_stalled: true
preserve_issue_context: true
required_runtime_fields:
  - "issue_id"
  - "dag_state_ref"
  - "trace_id"
```

Regras mandatarias:
- execucoes longas de agentes (`ralph`/loops equivalentes) SHOULD rodar em sessao isolada (`tmux` ou equivalente).
- se sessao cair, relancar e registrar evento com `trace_id`.
- se output ficar estagnado por 2 checks consecutivos, marcar `stalled`, matar sessao e relancar.
- evento `stalled` MUST abrir incidente operacional e bloquear promocao ate reconciliacao.
- toda relargada MUST preservar referencia da Issue e estado do DAG.

## Visao Executiva
- O sistema opera como edificio com escritorios por empresa e servicos compartilhados.
- O roteamento de modelo e central e governado por policy/preset, nao por escolha ad hoc de agente.
- Requisito chave: toda chamada LLM precisa ser explicavel (modelo pedido, modelo efetivo, provider efetivo, custo, motivo).
- Tarefas criticas e sensiveis podem operar com `pin provider`, `no-fallback` e modo de alta confiabilidade para tool calling.

## Estrutura Organizacional Minima
- Diretora IA (cloud): desempate, risco alto, aprovacoes criticas.
- PM: backlog, sprint, capacidade e limites.
- RAG Librarian: curadoria, versionamento e drift de politica.
- Controladoria/Financeiro: budget governor e circuit breaker de custo.
- Compliance/Auditoria: privacidade, retencao e rastreabilidade.

## Governanca de Risco (Nivel Alto)
- Baixo risco: execucao automatizada com validacao deterministica e log obrigatorio.
- Medio risco: execucao com checkpoint cloud por policy.
- Alto risco: gate cloud + HITL quando aplicavel, com trilha completa.
- `sensitive` MUST aplicar provider allowlist restrita + requisitos ZDR + armazenamento minimizado de prompt.
- compatibilidade entre taxonomias:
  - `baixo -> R1` (ou `R0` quando doc-only),
  - `medio -> R2`,
  - `alto -> R3`.

## Quality Gates e Governanca por Risco
Camadas de gates (ordem obrigatoria de avaliacao):
- `schema`: valida formato de entrada/saida, contratos JSON e Task Spec.
- `patch_hygiene`: valida patch aplicavel, escopo permitido, arquivos autorizados e ausencia de lixo operacional.
- `static`: valida lint, typecheck e regras estaticas de qualidade.
- `unit`: valida testes unitarios obrigatorios do escopo alterado.
- `integration`: valida fluxo integrado minimo quando houver dependencia entre modulos/servicos.
- `security`: valida regras de seguranca (allowlists, segredos, policy, regressao de controle de acesso).

Classificacao de risco:
- `R0`: doc-only ou alteracao sem impacto funcional.
- `R1`: alteracao funcional local, sem side effects externos.
- `R2`: alteracao funcional com side effects controlados ou impacto cross-modulo.
- `R3`: alteracao critica com side effects de alto impacto/regulatorio/financeiro.

Gates obrigatorios por nivel:
- `R0`: `schema`, `patch_hygiene`.
- `R1`: `schema`, `patch_hygiene`, `static`, `unit`.
- `R2`: `schema`, `patch_hygiene`, `static`, `unit`, `integration`, `security`.
- `R3`: todos de `R2` + verificacoes adicionais de seguranca/compliance definidas por policy ativa.

Regra mandataria para `R2` e `R3`:
- exige `Gatekeeper/Reviewer` (cloud ou humano) antes de promover mudanca.
- quando houver side effects, MUST executar `pre_live_checklist` aprovado.
- quando a acao suportar dry-run tecnico, dry-run SHOULD ser executado; para acoes live-only (ex.: ordem real), aplicar rollout conservador por estagios (`S0 -> S1 -> S2`) com guardrails hard + capital ramp.
- `live-run` sem evidencia de checklist aprovado e bloqueado por policy.

Definicao objetiva de side effect:
- qualquer acao que altere estado de producao.
- qualquer acao que mova, bloqueie ou arrisque dinheiro.
- qualquer acao que leia/escreva/exponha dados sensiveis.
- qualquer acao que crie, use, rode ou exponha credenciais/chaves/tokens.

## Contrato Minimo de `pre_live_checklist`
- `pre_live_checklist` e o gate tecnico obrigatorio antes de qualquer `live-run` com side effect.
- campos minimos:
  - `checklist_id`, `decision_id`, `risk_tier`, `approved_at`, `operator_id`, `items[]`.
- regra de validacao:
  - `items[]` MUST incluir evidencia objetiva (`evidence_ref`) e status `pass|fail`.
  - qualquer item `fail` MUST bloquear `live-run`.
- para vertical Trading:
  - usar checklist detalhado em `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`.

## Decisoes Fechadas
- OpenClaw Gateway e o gateway padrao para chamadas LLM programaticas.
- LiteLLM e o adaptador padrao para supervisores pagos (`codex-main` primario; `claude-review` secundario).
- workers locais operam como camada bracal default em modo local-first (`ollama/qwen2.5-coder:32b`, `ollama/deepseek-r1:32b`).
- OpenRouter e adaptador cloud opcional, permanece desabilitado por default e so pode ser habilitado por decision formal; quando cloud adicional estiver habilitado, OpenRouter e o preferido.
- inferencia local em `MAC-LOCAL` e permitida para modelos locais sem chamada direta a provider externo.
- adaptador de supervisao ativo SHOULD manter logging de prompts/respostas desativado por default; qualquer opt-in MUST ser registrado por policy.
- providers efetivos possuem politicas proprias de retencao e MUST obedecer `provider allowlist` por sensibilidade.
- roteamento MUST ser orientado por:
  - capabilities e limites do modelo,
  - historico real (`cost_per_success`, confiabilidade, latencia),
  - constraints de risco/privacidade/orcamento.
- runtime multiagente e delegacao A2A sao permitidos somente com allowlist explicita por agente.
- hooks externos e internos fazem parte do contrato operacional e MUST gerar eventos rastreaveis com `trace_id`.
- gateway externo MUST operar com `bind=loopback` no processo local + tunel/autenticacao na borda.
- endpoint `chatCompletions` pode ser habilitado para interoperabilidade, sem bypass de policy/gates.
- email nunca e canal de comando confiavel; apenas canal de informacao.
- toda acao financeira com side effect exige aprovacao humana explicita sempre.
- existe um Model Catalog versionado com metadados vivos.
- existe um Model Router com fallback chain declarativa por `task_type`.
- existe modo `no-fallback` para rotas sensiveis.
- existe modo de alta confiabilidade para tool-calling critico (preferencia por variante curada/exacto quando disponivel).
- existe entidade de configuracao `preset` para centralizar governanca de roteamento.
- memoria vetorial hibrida (estruturado + embeddings) e obrigatoria para metadados de modelos e execucoes.
- budget operacional e derivado da telemetria de custo do LiteLLM e do provedor efetivo habilitado por policy.
- credenciais de billing/management MUST ficar isoladas fora do runtime comum.
- em trading live, OpenClaw e o backbone unico de producao para risco, HITL, execucao e auditoria.
- em trading fase 1, o escopo de ativos live e `crypto_spot` via Binance Spot.
- em trading fase 1, `TradingAgents` e a engine primaria de sinal sob contrato `signal_intent`.
- AI-Trader e permitido somente em modo `signal_only` e MUST operar sob contrato `signal_intent`.
- payload de AI-Trader que represente ordem direta MUST ser rejeitado e auditado como violacao de policy.
- ClawWork opera em `lab_isolated` por default; modo `governed` exige gateway-only, provider allowlist e politica de dados explicita para ambiente externo.
- em trading fase 2, `AgenticTrading` entra apenas por modulos seletivos (risco/custo/portfolio), sem substituir backbone.
- expansao para `equities_br`, `fii_br` e `fixed_income_br` e permitida somente por enablement formal por classe (`asset_profile` + eval da classe + shadow mode + decision `R3`).
- framework externo MUST NOT enviar ordem diretamente para exchange.
- rollout de capital na vertical Trading MUST seguir modo conservador:
  - `S0` paper/sandbox obrigatorio,
  - `S1` micro-live com capital minimo,
  - `S2` escala gradual apenas com historico real estavel.
- em `S0`, `S1` e `S2`, ordem com side effect financeiro so executa apos aprovacao humana explicita por ordem.
- falha de engine primaria de sinal em live MUST operar em `fail_closed` para novas entradas.
- `single_engine_mode` e permitido apenas para falha de engine secundaria/auxiliar com engine primaria saudavel.
- `make eval-trading` MUST existir e passar em CI antes de qualquer operacao com capital real.
- credenciais de trading live MUST operar sem permissao de saque e com IP allowlist quando suportado.
- fallback HITL em Slack para trading live exige `slack_user_ids` e `slack_channel_ids` nao vazios para operador habilitado.
- Trading live MUST ter `backup_operator` habilitado; sem isso, estado operacional e `TRADING_BLOCKED`.

## Resposta Formal aos Bloqueadores Criticos
- STOP-SHIP (`SPRINT_OVERRIDE`): contrato com idempotencia + rollback explicito em `PM/SPRINT-LIMITS.md`.
- STOP-SHIP (auto-acoes por threshold): contrato com `automation_action_id` e rollback em `ARC/ARC-OBSERVABILITY.md`.
- variancia por provider: provider routing explicito e auditavel em `ARC/ARC-MODEL-ROUTING.md`.
- fallback silencioso: `no-fallback` e logs obrigatorios de fallback por `task_type` sensivel.
- claims nao testaveis: gates obrigatorios em `EVALS/SYSTEM-HEALTH-THRESHOLDS.md`.
- STOP-SHIP (trading sem harness): live bloqueado sem `make eval-trading` executavel em CI.
- STOP-SHIP (degradacao com posicao aberta): runbook obrigatorio de protecao/reducao de exposicao e reconciliacao.

## Riscos e Mitigacoes (Atualizado)
- provider variance (impacto alto, prob media):
  - mitigacao: provider routing explicito, `pin provider` em rotas criticas, metricas por provider.
- fallback masking (impacto alto, prob media):
  - mitigacao: `no-fallback` em rotas sensiveis e log de motivo de fallback.
- custo imprevisivel (impacto alto, prob alta):
  - mitigacao: budget governor por telemetria LiteLLM, burn-rate limits e circuit breaker.
- retencao/privacidade (impacto alto, prob media):
  - mitigacao: classificacao `public/internal/sensitive`, provider allowlist e politica ZDR.
- drift de catalogo (impacto medio, prob alta):
  - mitigacao: sync periodico do catalogo, versionamento e bloqueio de modelo sem metrica atualizada.
- exposicao nao gerenciada em degradacao (impacto alto, prob media):
  - mitigacao: `TRADING_BLOCKED`, `position_snapshot`, protecao de posicao e incidente `SEV-1` para `UNMANAGED_EXPOSURE`.

## Fases e Definition of Done
- Fase 0 (Mission Control MVP):
  - control-plane minimo + baseline executavel de catalog/router/memory/budget/privacidade.
  - refinos avancados desses blocos devem ser diferidos para Fase 1/2 conforme `PRD/ROADMAP.md`, sem perda de escopo.
  - DoD MUST: 7 dias estavel, rota explicavel por Issue/Microtask, claims centrais cobertos por gate, sem bypass de policy.
- Fase 1 (Trading):
  - habilitada somente apos criteria formal de enablement e suite hard-risk verde.
  - engine primaria de sinal: `TradingAgents`.
  - capital real habilitado somente apos `S0` concluido e gate de prontidao verde por 7 dias.
  - aumento de capital/limites somente apos janela estavel de `S1` e decision `R3`.
- Fase 2 (Expansao):
  - novas verticais/escritorios com o mesmo padrao de governanca.
  - evolucao trading com modulos seletivos de `AgenticTrading` quando houver ganho comprovado.
  - expansao multiativos (acoes/FIIs/titulos) por classe de ativo, sem bypass de `execution_gateway`/risk gates.

### Workflow de Execucao (Scrum/Agile)
- principio operacional: fluxo minimo e previsivel; cada gate existe para evitar erro silencioso, nao para adicionar cerimonia.
- mapeamento de planejamento para execucao:
  - `Epic` define outcome macro, limites e risco.
  - `Story` define recorte funcional verificavel do epic.
  - `Issue` define entrega unitaria auditavel (criterios objetivos, escopo e risco).
  - `Issue` e decomposta em DAG de microtasks tipadas conforme [Contrato de Microtask (Task Spec)](#contrato-de-microtask-task-spec) e [Paradigma de Execucao: Microtasks e Delegacao Sob Demanda](#paradigma-de-execucao-microtasks-e-delegacao-sob-demanda).
- estados da Issue:
  - fluxo base: `Ready -> Decomposed -> InProgress(micro) -> Verify -> Done`
  - fluxo com gate: `Ready -> Decomposed -> InProgress(micro) -> Verify -> Review/Gate -> Done` (obrigatorio para `R2`/`R3` ou side effect).
  - retorno permitido: `Verify -> InProgress(micro)` quando falha tecnica; `Review/Gate -> InProgress(micro)` quando houver rejeicao de risco/compliance.
- estados da Microtask:
  - caminho feliz: `Queued -> Running -> Verified -> Applied/Merged`
  - caminhos de excecao: `Running -> Failed(Triage) -> Queued`; `Running -> Blocked(NeedsInput) -> Queued`; `Applied/Merged -> RolledBack` quando gate obrigatorio falhar ou houver incidente.
- DoR/DoD como gates tecnicos (sem subjetividade):
  - `DoR (Issue)` MUST conter: objetivo verificavel, criterios de aceite mensuraveis, classificacao de risco, dependencias declaradas e inputs minimos disponiveis.
  - `DoR (Microtask)` MUST conter todos os campos obrigatorios do Task Spec e `output_contract` valido (`unified_diff` ou `json`).
  - `DoD (Microtask)` MUST conter: saida tipada valida, gates obrigatorios por risco (`R0..R3`) em `pass`, trilha de execucao com `idempotency_key` e estado terminal registrado.
  - `DoD (Issue)` MUST conter: todas as microtasks em estado terminal valido, `Verify` em `pass`, `Review/Gate` concluido para `R2`/`R3` ou side effect, e evidencia auditavel consolidada.

## Regra de Testabilidade de Claims Centrais
- claim central sem eval gate MUST bloquear release de fase.
- automacao com efeito colateral sem idempotencia/rollback MUST ser stop-ship.
- decisao de roteamento sem rastro (`requested/effective`) MUST ser falha de compliance.

## Mudancas Aplicadas (2026-02-24)
- `felixcraft.md` adotado como referencia arquitetural suprema.
- arquitetura realinhada para OpenClaw gateway-first com providers plugaveis.
- contratos canonicos adicionados: `openclaw_runtime_config`, `approval_policy`, `memory_contract`, `ops_autonomy_contract`.
- A2A, hooks/webhooks, `bind=loopback` e endpoint `chatCompletions` formalizados como contrato de runtime.
- regra endurecida: email nunca e canal de comando confiavel.
- regra endurecida: side effect financeiro exige aprovacao humana explicita sempre (todas as fases).

## Links Relacionados
- [Felixcraft Architecture](../felixcraft.md)
- [Roadmap](./ROADMAP.md)
- [Phase Usability Guide](./PHASE-USABILITY-GUIDE.md)
- [Changelog](./CHANGELOG.md)
- [Integrations](../INTEGRATIONS/README.md)
- [ARC Core](../ARC/ARC-CORE.md)
- [ARC Model Routing](../ARC/ARC-MODEL-ROUTING.md)
- [Security Policy](../SEC/SEC-POLICY.md)
- [Secrets](../SEC/SEC-SECRETS.md)
- [System Health Thresholds](../EVALS/SYSTEM-HEALTH-THRESHOLDS.md)
- [Financial Governance](../CORE/FINANCIAL-GOVERNANCE.md)

## MVP do Paradigma (Implementacao Minima)
Implementar primeiro:
- schema do `Task Spec` + validacao de entrada/saida.
- executor deterministico de microtask (`Queued -> Running -> Verified -> Applied/Merged` + caminhos de erro).
- camada minima de validators (`schema`, `patch_hygiene`, `static`).
- fluxo de triage para `Failed(Triage)` e `Blocked(NeedsInput)` com reentrada controlada.
- persistencia de estado e artifacts de run (`status.json`, `verify.log`, `output.diff`/`output.json`).

Fora do MVP:
- paralelizacao avancada com scheduling adaptativo.
- auto-otimizacao de roteamento por aprendizado continuo.
- heuristicas complexas de decomposicao automatica multi-issue.

Criterios de sucesso (mediveis):
- `pass_rate` de microtasks >= 85% apos no maximo 2 retries por microtask.
- `retry_rate` medio <= 1.2 por microtask nas ultimas 2 semanas.
- tempo mediano por Issue (Ready -> Done) <= 1 dia util para escopo R0/R1.
