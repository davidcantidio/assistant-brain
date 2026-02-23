---
doc_id: "CHANGELOG.md"
version: "2.1"
status: "active"
owner: "PM"
last_updated: "2026-02-23"
rfc_refs: ["RFC-001", "RFC-010", "RFC-015", "RFC-020", "RFC-025", "RFC-030", "RFC-035", "RFC-040", "RFC-050", "RFC-060"]
---

# Changelog Normativo

## Objetivo
Manter historico auditavel de alteracoes normativas da documentacao, incluindo impacto e acao de migracao quando aplicavel.

## Escopo
Inclui:
- mudancas de regra MUST/SHOULD/MAY
- mudancas de RFC e de hierarquia documental
- impacto operacional e compliance

Exclui:
- log de tarefas de desenvolvimento cotidiano
- detalhe de commit tecnico sem impacto normativo

## Regras Normativas
- [RFC-001] MUST registrar data, resumo e RFCs afetadas em toda alteracao normativa.
- [RFC-050] MUST manter trilha de impacto e responsavel por mudanca.
- [RFC-015] SHOULD avaliar reflexo em seguranca para toda alteracao estrutural.

## Entradas

### 2026-02-23 - Migracao de plataforma: OpenClaw -> Nanobot + ClawWork
- RFCs afetadas: RFC-001, RFC-010, RFC-015, RFC-030, RFC-040, RFC-050, RFC-060.
- Impacto:
  - runtime oficial passa para `Nanobot >= 0.1.4`.
  - integra `clawmode_integration` (ClawWork wrapper) como camada oficial de adaptacao operacional.
  - atualiza comandos publicos para `nanobot ...` e `python -m clawmode_integration.cli ...`.
  - converte paths canonicos de estado/auditoria de `.openclaw` para `.nanobot`.
  - preserva regras de risco e bloqueia bypass por wrapper em `execution_gateway`, `pre_live_checklist`, challenge HITL e gates `R2/R3`.
- Migracao:
  - executar onboarding novo (`scripts/onboard_linux.sh`) e verificacao (`scripts/verify_linux.sh`);
  - preencher `~/.nanobot/config.json` + skill clawmode + `PYTHONPATH` da integracao;
  - validar bridge de estado repo <-> `~/.nanobot/workspace` com arquivo canonico no repo.
- Rollback documental:
  - permitido apenas por decision formal `R3` com plano explicito de restauracao de nomenclatura/paths/comandos.
  - rollback tecnico sem decision deve ser tratado como desvio de governanca.

### 2026-02-20 - Rebalanceamento de fases (reduzir carga inicial sem perda de informacao)
- RFCs afetadas: RFC-001, RFC-040, RFC-050, RFC-060.
- Impacto:
  - reduz escopo obrigatorio da Fase 0 para baseline executavel.
  - move refinos de catalog/router/presets/memory/budget/privacidade/Slack para Fase 1 com rastreabilidade de origem (`B1-R*`).
  - move refinos de resiliencia/escala de Trading para Fase 2 com rastreabilidade de origem (`B2-R*`).
  - preserva 100% das informacoes de backlog, sem descarte de requisito.
- Migracao:
  - seguir novos blocos de backlog em `PRD/ROADMAP.md`:
    - `Backlog ... baseline` (fase atual),
    - `Refinos diferidos ...` (fases seguintes).
  - manter gates obrigatorios por fase sem antecipar refino nao bloqueante.

### 2026-02-20 - Correcoes de coerencia pos-auditoria (stop-ship)
- RFCs afetadas: RFC-001, RFC-010, RFC-015, RFC-030, RFC-040, RFC-050, RFC-060.
- Impacto:
  - remove contradicao entre OpenRouter obrigatorio e uso de LLM local (`cloud/provider externo` via OpenRouter; local permitido em `MAC-LOCAL` sem chamada direta a provider).
  - endurece fallback HITL em Slack no degradado para exigir IDs validados + assinatura + anti-replay + challenge.
  - torna `risk_tier` obrigatorio no Work Order para evitar gate ambiguo.
  - define contrato objetivo de `safe_notional` e referencia canonica em degradacao.
  - formaliza contrato minimo de `pre_live_checklist` para bloquear live-run sem evidencia.
  - formaliza conversao creditos <-> BRL no Budget Governor.
  - revoga explicitamente a entrada historica de `live-first` e mantem `S0 -> S1 -> S2` como regra vigente.
  - elimina bypass de governanca nos scripts de backup (`git add/commit/push` automatico removido).
  - adiciona harness/workflows minimos executaveis:
    - `Makefile` com `eval-models`, `eval-rag`, `eval-trading`, `eval-gates`;
    - `scripts/ci/*.sh`;
    - `.github/workflows/ci-quality.yml`, `ci-security.yml`, `ci-routing.yml`, `ci-evals.yml`, `ci-trading.yml`.
- Migracao:
  - executar `make eval-gates` e `make eval-trading` antes de promover mudancas criticas;
  - manter fallback Slack de trading live bloqueado enquanto IDs de Slack estiverem vazios no operador habilitado;
  - manter `TRADING_BLOCKED` quando checklist/gates obrigatorios falharem.

### 2026-02-20 - Trading em rollout conservador (paper-first -> micro-live -> escala)
- RFCs afetadas: RFC-010, RFC-050, RFC-060.
- Impacto:
  - define `S0` (`paper/sandbox`) como etapa obrigatoria antes da primeira ordem real.
  - define `S1` com capital minimo e modo assistido humano por ordem de entrada na janela inicial.
  - define `S2` com escala gradual somente por decision `R3` apos historico estavel.
  - substitui linguagem `live-first` por fluxo conservador de exposicao.
- Migracao:
  - registrar evidencias de `S0` antes de desbloquear capital real.
  - manter `S1` por janela minima com monitoramento de incidentes/violacoes hard.
  - bloquear promocao para `S2` sem janela estavel e decisao formal.

### 2026-02-20 - Correcao de STOP-SHIPs da vertical Trading (capital real)
- RFCs afetadas: RFC-010, RFC-015, RFC-035, RFC-050, RFC-060.
- Impacto:
  - inclui dominios de venue (Binance fase 1) na allowlist mantendo `default deny`.
  - expande allowlist de acoes para ciclo de ordens com enforcement `execution_gateway_only`.
  - formaliza politica de credenciais de trading sem saque + IP allowlist.
  - define fail-safe em degradacao com posicao aberta (`TRADING_BLOCKED`, protecao/reducao de exposicao, `UNMANAGED_EXPOSURE` => `SEV-1`).
  - unifica regra de engines: `single_engine_mode` para falha secundaria; falha primaria => `fail_closed`.
  - torna explicito o gate de capital real (harness executavel, CI, backup operator, fallback HITL validado).
- Migracao:
  - preencher `slack_user_ids` e `slack_channel_ids` para fallback HITL antes de live.
  - habilitar e validar `backup_operator` antes de capital real.
  - versionar contratos `execution_gateway` e `pre_trade_validator`.
  - disponibilizar `make eval-trading` em CI antes de liberar ordem real.

### 2026-02-20 - Trading com escopo inicial em crypto e trilha formal de expansao multiativos
- RFCs afetadas: RFC-010, RFC-050, RFC-060.
- Impacto:
  - formaliza `crypto_spot` (Binance Spot) como escopo live da Fase 1.
  - explicita trilha de expansao para `equities_br`, `fii_br`, `fixed_income_br`.
  - exige enablement por classe (`asset_profile`, eval da classe, shadow mode, decision `R3`).
  - reforca regra de execucao unica via `execution_gateway` para qualquer classe.
- Migracao:
  - definir schema versionado de `asset_profile` por classe.
  - criar suites `eval-trading-<asset_class>` antes de habilitar classe nova em live.
  - implementar adapters de venue por classe mantendo gates de risco/auditoria.

### 2026-02-20 - Estrategia de frameworks para Trading: TradingAgents primario, AgenticTrading modular
- RFCs afetadas: RFC-010, RFC-050, RFC-060.
- Impacto:
  - define Nanobot como backbone unico de producao para trading live.
  - define `TradingAgents` como engine primaria de sinal na Fase 1.
  - define `AgenticTrading` como fonte de modulos seletivos (risco/custo/portfolio) na Fase 2.
  - bloqueia caminho de ordem direta de framework externo para exchange.
- Migracao:
  - implementar adapter `signal_intent` para `TradingAgents`.
  - implementar `single_engine_mode` para degradacao segura.
  - habilitar modulos de `AgenticTrading` somente apos criterio de ganho comprovado e decision registrada.

### 2026-02-20 - Entrada historica revogada: "live-first sem etapa obrigatoria"
- Status: **REVOGADA no mesmo dia** pela entrada "Trading em rollout conservador (paper-first -> micro-live -> escala)".
- Motivo da revogacao:
  - conflito normativo com `S0` obrigatorio antes de capital real.
  - risco operacional alto sem janela minima de estabilizacao.
- Regra vigente:
  - permanece `S0 -> S1 -> S2` com gate formal de enablement, `pre_live_checklist` e decision `R3` para promote.

### 2026-02-20 - HITL multi-canal, operador registrado e migracao final para OPENROUTER_*
- RFCs afetadas: RFC-010, RFC-015, RFC-035, RFC-050.
- Impacto:
  - Telegram permanece primario para HITL critico, com fallback controlado em Slack quando Telegram degradar.
  - `OPERATORS.yaml` atualizado com operador primario real (telegram user/chat id fornecidos).
  - contratos de decision/seguranca passam a validar autenticacao por canal (Telegram/Slack), com assinatura HMAC no Slack.
  - mapeamento canonico `risk_class` (`baixo|medio|alto`) para `risk_tier` (`R0..R3`) formalizado.
  - scripts de onboarding/verify migram de `OPENAI_API_KEY` para `OPENROUTER_API_KEY` e adicionam segredos Slack/OpenRouter management.
  - politica de storage imutavel reforcada com Object Lock + retention quente/fria.
- Migracao:
  - preencher `slack_user_ids` reais em `SEC/allowlists/OPERATORS.yaml` antes de habilitar fallback HITL em producao.
  - configurar `SLACK_BOT_TOKEN` e `SLACK_SIGNING_SECRET` no secret manager/.env local.
  - remover referencias legadas a `OPENAI_API_KEY` de ambientes ativos.

### 2026-02-20 - Slack como canal oficial de colaboracao operacional
- RFCs afetadas: RFC-010, RFC-040, RFC-050.
- Impacto:
  - Slack passa a canal oficial para colaboracao diaria e `@mentions` entre agentes.
  - Telegram permanece canal HITL critico para `approve/reject/kill`.
  - evento de Slack passa a exigir normalizacao para `task_event` com idempotencia e rastreabilidade.
  - mensagem de chat nao vira fonte de verdade de estado/execucao.
- Migracao:
  - implementar adapter Slack com deduplicacao de eventos.
  - mapear thread para `issue_id`/`microtask_id` quando houver contexto.
  - manter gates de risco e aprovacao formal sem bypass por chat.

### 2026-02-20 - Separacao de onboarding e operacao diaria no workspace main
- RFCs afetadas: RFC-001, RFC-050.
- Impacto:
  - `workspaces/main/AGENTS.md` deixa de exigir `BOOTSTRAP.md` no inicio de sessao operacional.
  - onboarding (`BOOTSTRAP.md`, `IDENTITY.md`, `USER.md`, `SOUL.md`) passa a ser explicitamente one-time/opcional.
  - reduz drift operacional por instrucoes sociais fora do fluxo de governanca.
- Migracao:
  - iniciar rotina diaria por heartbeat + estado + memoria canonica.
  - manter `BOOTSTRAP.md` apenas como template de onboarding/reset.

### 2026-02-20 - Reestruturacao PRD para OpenRouter + Router + Memoria Vetorial
- RFCs afetadas: RFC-001, RFC-015, RFC-030, RFC-050.
- Impacto:
  - OpenRouter consolidado como gateway programatico padrao.
  - Model Catalog Service formalizado com sync/versionamento de metadados.
  - Model Router formalizado com provider routing (`include/exclude/order/require`), `pin provider`, `no-fallback` e modo de tool-calling confiavel.
  - entidade `presets` oficializada para governanca central de configuracao de roteamento.
  - memory plane vetorial hibrido (Postgres + pgvector) definido com entidades:
    - `model_catalog`, `llm_runs`, `router_decisions`, `eval_aggregates`, `credits_snapshots`, `router_presets`.
  - `model_catalog` expandido com `tags` e schema alinhado para consultas estruturadas + busca semantica.
  - privacidade/retencao por sensibilidade (`public/internal/sensitive`) com policy ZDR para fluxos sensiveis.
  - provider allowlist formalizada em `SEC/allowlists/PROVIDERS.yaml`.
  - budget governor migrado para saldo de creditos OpenRouter com isolacao da management key.
- Migracao:
  - implementar coleta de `credits_snapshots` via servico dedicado.
  - implementar persistencia de `requested/effective model/provider` em `llm_runs`.
  - migrar rotas programaticas para base URL OpenRouter.
  - bloquear rotas sensiveis sem policy ZDR/allowlist compatível.

### 2026-02-19 - Resposta formal as criticas de viabilidade do PRD
- RFCs afetadas: RFC-001, RFC-015, RFC-030, RFC-040, RFC-050, RFC-060.
- Impacto:
  - elimina contradicoes de governanca em `README.md` e `workspaces/main/AGENTS.md`;
  - formaliza contratos idempotentes/rollback para `SPRINT_OVERRIDE` e auto-acoes de observabilidade;
  - define lifecycle completo do challenge HITL (geracao, hash, TTL, rotacao, invalidacao e auditoria);
  - fecha lacuna do catalogo de modelos com schema canonico (`ARC/schemas/models_catalog.schema.json`);
  - registra CI oficial em GitHub Actions e torna harness de eval obrigatorio para release;
  - adiciona suite executavel obrigatoria para enablement de Trading;
  - cria allowlists canonicas em `SEC/allowlists/*.yaml`.
- Migracao:
  - preencher IDs reais em `SEC/allowlists/OPERATORS.yaml`;
  - implementar workflows de CI e comandos `make eval-*`;
  - configurar trilha auditavel nao versionada em `workspaces/main/.nanobot/audit/` e espelhamento externo.

### 2026-02-19 - Ajustes de viabilidade MVP e controle operacional
- RFCs afetadas: RFC-015, RFC-030, RFC-040, RFC-050.
- Impacto:
  - fixa heartbeat baseline unico em 20 minutos;
  - define controle forte de aprovador Telegram (allowlist + challenge + idempotencia de comando);
  - formaliza fonte canonica de memoria/estado operacional em `workspaces/main/*`;
  - adiciona EVAL gates obrigatorios para claims centrais.
- Migracao:
  - desativar memoria operacional duplicada fora de `workspaces/main/memory`;
  - remover versionamento de `sessions/*.json*`;
  - atualizar scripts/env para `HEARTBEAT_MINUTES=20`.

### 2026-02-18 - Baseline v1.0 da stack documental
- RFCs afetadas: RFC-001, RFC-010, RFC-015, RFC-020, RFC-025, RFC-030, RFC-035, RFC-040, RFC-050, RFC-060.
- Impacto:
  - define arquitetura Local + Cloud com gates por risco;
  - formaliza RAG hibrido, degraded mode e Scrum com enforcement;
  - institui tabela de model routing com fallback e auditoria.
- Migracao:
  - remover arvores duplicadas de documentacao sob `PRD/`;
  - adotar somente arvore canonica na raiz do repositorio;
  - atualizar automacoes para novos caminhos relativos.

## Links Relacionados
- [PRD Master](./PRD-MASTER.md)
- [Document Hierarchy](../META/DOCUMENT-HIERARCHY.md)
- [RFC Index](../META/RFC-INDEX.md)
