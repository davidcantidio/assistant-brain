---
doc_id: "CHANGELOG.md"
version: "2.12"
status: "active"
owner: "PM"
last_updated: "2026-02-25"
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

### 2026-02-25 - Execucao do EPIC-F1-03 (workspace state e memoria operacional minima)
- RFCs afetadas: RFC-001, RFC-010, RFC-030, RFC-040, RFC-050.
- Impacto:
  - endurece `scripts/ci/eval_runtime_contracts.sh` para validar estado canonico de workspace:
    - `workspaces/main/.openclaw/workspace-state.json` obrigatorio;
    - parse JSON obrigatorio;
    - `version` inteiro `>= 1`;
    - `bootstrapSeededAt` obrigatorio em ISO-8601 UTC (`Z`).
  - endurece `eval-runtime` para exigir contrato explicito de ciclo noturno:
    - `nightly-extraction`;
    - `schedule: "0 23 * * *"`;
    - `timezone: "America/Sao_Paulo"`;
    - alinhamento com baseline de heartbeat em `15 minutos`.
  - adiciona nota diaria operacional `workspaces/main/memory/2026-02-25.md` no formato canonico.
  - adiciona evidencia auditavel do epico em `artifacts/phase-f1/epic-f1-03-runtime-memory.md`.
  - atualiza `PM/PHASES/F1-INSTALACAO-BASE-OPENCLAW/EPICS.md` com `EPIC-F1-03` em status `done`.
  - registra resultado final da rodada no `EPIC-F1-03-WORKSPACE-STATE-MEMORY.md`.
- Migracao:
  - manter `workspaces/main/.openclaw/workspace-state.json` sempre valido pelo contrato minimo (`version`, `bootstrapSeededAt`).
  - manter notas diarias em `workspaces/main/memory/YYYY-MM-DD.md` com header e secoes obrigatorias (`Key Events`, `Decisions Made`, `Facts Extracted`) com bullet minimo.
  - executar `make eval-runtime` antes de promover alteracao documental que toque memoria/heartbeat/runtime.

### 2026-02-24 - Execucao do EPIC-F1-02 (contrato de configuracao local)
- RFCs afetadas: RFC-001, RFC-010, RFC-015, RFC-040, RFC-050.
- Impacto:
  - atualiza `PM/PHASES/F1-INSTALACAO-BASE-OPENCLAW/EPIC-F1-02-CONTRATO-CONFIG-LOCAL.md` para refletir gate executavel por `exit code` e defaults normativos verificaveis.
  - endurece `scripts/verify_linux.sh` com validacao explicita de defaults de runtime:
    - `HEARTBEAT_MINUTES=15`
    - `STANDUP_TIME=11:30`
    - `OPENCLAW_GATEWAY_URL=http://127.0.0.1:18789/v1`
    - `LITELLM_BASE_URL=http://127.0.0.1:4000/v1`
    - `OPENCLAW_SUPERVISOR_PRIMARY=codex-main`
    - `OPENCLAW_SUPERVISOR_SECONDARY=claude-review`
  - adiciona carregamento defensivo de NVM no `verify_linux.sh` para reduzir falso negativo de PATH em shells sem perfil carregado.
  - registra evidencias Red/Green/Refactor do epico em `artifacts/phase-f1/epic-f1-02-config-validation.md`.
  - atualiza `PM/PHASES/F1-INSTALACAO-BASE-OPENCLAW/EPICS.md` com `EPIC-F1-02` em status `done`.
- Migracao:
  - executar `bash scripts/onboard_linux.sh` para bootstrap local (quando necessario).
  - executar `bash scripts/verify_linux.sh` e corrigir qualquer divergence de `.env` antes da promocao de fase.
  - executar `make eval-models` para validar politica de cloud opcional desabilitada por default.

### 2026-02-24 - F1-01 cross-platform (Linux/macOS) com gate real de verify
- RFCs afetadas: RFC-001, RFC-010, RFC-040, RFC-050.
- Impacto:
  - atualiza `scripts/onboard_linux.sh` para detectar plataforma (`Linux`/`Darwin`) e executar dependencias por SO sem trocar o comando oficial da fase.
  - adiciona validacoes de macOS no onboarding (`brew` + Command Line Tools) e persistencia de NVM em shell novo (`.bashrc` e `.zshrc`).
  - endurece `scripts/verify_linux.sh` para gate bloqueante com `exit code != 0` em requisito faltante.
  - formaliza contrato hibrido de `.env`: chaves operacionais do projeto obrigatorias + chaves completas do template como referencia opcional.
  - formaliza regra Telegram: `TELEGRAM_CHAT_ID` canonico com aliases aceitos (`TELEGRAM_USER_ID`, `TELEGRAM_GROUP_ID`).
  - cria template canonico `config/openclaw.env.example` e alinha `.env_example` como espelho.
  - atualiza docs de F1 (`EPIC-F1-01`, `EPICS`, `DEV-OPENCLAW-SETUP`, `PHASE-USABILITY-GUIDE`, `README`) para refletir suporte Linux/macOS e gate do verify.
- Migracao:
  - executar `bash scripts/onboard_linux.sh` no host local (Linux ou macOS).
  - executar `bash scripts/verify_linux.sh` e bloquear promocao de fase se retorno for diferente de zero.
  - usar `config/openclaw.env.example` como base unica para criar/atualizar `.env`.

### 2026-02-24 - Fechamento de lacunas F2/F5 e rastreabilidade roadmap-felix
- RFCs afetadas: RFC-001, RFC-010, RFC-015, RFC-040, RFC-050, RFC-060.
- Impacto:
  - cria fase `F2` em `PM/PHASES/F2-POS-INSTALACAO-BASELINE-SEGURANCA/` com epics para:
    - baseline de seguranca/gates,
    - contratos idempotentes/reconciliacao,
    - catalog/router/memory/budget baseline.
  - cria fase `F5` em `PM/PHASES/F5-INTEGRACOES-EXTERNAS-GOVERNADAS/` com epics para:
    - integracoes governadas e anti-bypass,
    - hardening de trading e prontidao live,
    - autonomia operacional + blast radius.
  - adiciona `PM/TRACEABILITY/FELIX-ALIGNMENT-MATRIX.md` para rastrear alinhamento de temas `felixcraft.md` e `felix-openclaw-pontos-relevantes.md` para epics/issues.
  - adiciona `PM/TRACEABILITY/ROADMAP-BACKLOG-COVERAGE.md` com cobertura completa de IDs `B*`.
  - atualiza `PRD/PHASE-USABILITY-GUIDE.md` para remover estado inconsistente de "pendente de criacao" e listar links de `F1..F8`.
  - expande `PM/PHASES/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPICS.md` com `EPIC-F8-04` para backlog multiativos (`B2-*`).
- Migracao:
  - usar `PM/TRACEABILITY/ROADMAP-BACKLOG-COVERAGE.md` como check obrigatorio de cobertura antes de promover fase.
  - usar `PM/TRACEABILITY/FELIX-ALIGNMENT-MATRIX.md` para validar alinhamento com fontes Felix e registrar qualquer `override_documentado`.
  - executar os novos epicos de `F2` e `F5` antes de ampliar risco operacional em canais e trading.

### 2026-02-24 - Estrutura da F8 com epicos de operacao continua e evolucao
- RFCs afetadas: RFC-001, RFC-015, RFC-040, RFC-050, RFC-060.
- Impacto:
  - cria `PM/PHASES/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPICS.md` com gate semanal de governanca (`eval-gates`, `ci-quality`, `ci-security`).
  - cria `EPIC-F8-01-CADENCIA-SEMANAL-DE-GATES.md` com issues para cadencia semanal e regra fail-fast.
  - cria `EPIC-F8-02-REVISAO-PERIODICA-DE-CONTRATOS-E-DRIFT.md` com issues para revisao de contratos e tratamento de drift.
  - cria `EPIC-F8-03-GOVERNANCA-DE-EVOLUCAO-E-RELEASE.md` com issues para decisao semanal `promote|hold` e trilha de release.
  - formaliza contrato documental de relatorio semanal da F8 em `artifacts/phase-f8/weekly-governance/<week_id>.md`.
- Migracao:
  - adotar rotina semanal com execucao do trio de gates obrigatorios.
  - registrar revisao de contratos/drift com owner e prazo em cada ciclo.
  - consolidar decisao semanal `promote|hold` com risco residual, rollback e `next_actions`.

### 2026-02-24 - Expansao da F1 com epicos seguintes (Scrum + TDD)
- RFCs afetadas: RFC-001, RFC-010, RFC-015, RFC-040, RFC-050, RFC-060.
- Impacto:
  - atualiza `PM/PHASES/F1-INSTALACAO-BASE-OPENCLAW/EPICS.md` para incluir `EPIC-F1-02`, `EPIC-F1-03` e `EPIC-F1-04`.
  - cria `EPIC-F1-02-CONTRATO-CONFIG-LOCAL.md` com issues e gate (`verify_linux.sh` + `eval-models`).
  - cria `EPIC-F1-03-WORKSPACE-STATE-MEMORY.md` com issues e gate (`eval-runtime`).
  - cria `EPIC-F1-04-HITL-BOOTSTRAP-EVIDENCIAS.md` com issues e gate (`ci-security` + `ci-quality`).
  - padroniza no planejamento da F1: user story, plano TDD (`Red/Green/Refactor`) e criterios Given/When/Then por issue.
- Migracao:
  - executar os novos epicos em ordem `F1-02 -> F1-03 -> F1-04`.
  - promover `F1 -> F2` somente com epicos `F1-01..F1-04` concluidos e gates verdes.

### 2026-02-24 - Estrutura de fases com epicos/issue no padrao Scrum + TDD (F1 inicial)
- RFCs afetadas: RFC-001, RFC-040, RFC-050.
- Impacto:
  - cria estrutura inicial `PM/PHASES/` com a primeira fase (`F1-INSTALACAO-BASE-OPENCLAW`).
  - adiciona `EPICS.md` da fase `F1` com gate de saida objetivo.
  - adiciona `EPIC-F1-01-INSTALACAO-VERIFY.md` com issues em padrao Scrum, estrategia TDD e criterios de aceitacao.
  - conecta o guia de usabilidade de fases (`PRD/PHASE-USABILITY-GUIDE.md`) ao artefato de planejamento da `F1`.
- Migracao:
  - usar `PM/PHASES/F1-INSTALACAO-BASE-OPENCLAW/EPICS.md` como ponto de entrada da fase.
  - executar as issues do `EPIC-F1-01` com evidencias de validacao da fase.

### 2026-02-24 - Guia de fases usaveis com teste humano por etapa
- RFCs afetadas: RFC-001, RFC-010, RFC-040, RFC-050, RFC-060.
- Impacto:
  - cria `PRD/PHASE-USABILITY-GUIDE.md` com fases `F1` a `F8`, cada uma com uso humano, teste humano e gate de saida explicito.
  - conecta o guia de fases usaveis ao `README`, `PRD/ROADMAP.md` e `PRD/PRD-MASTER.md`.
  - padroniza promocao de fase por comando/evidencia e bloqueio automatico quando gate falhar.
- Migracao:
  - adotar a trilha `F1..F8` para planejamento e execucao operacional.
  - usar os gates definidos por fase (`verify`, `ci-*`, `eval-*`) antes de promover etapa.

### 2026-02-24 - Pacote normativo de integracoes e hardening de coerencia
- RFCs afetadas: RFC-001, RFC-015, RFC-030, RFC-050, RFC-060.
- Impacto:
  - unifica regra canonica de OpenRouter: adaptador cloud opcional, desabilitado por default, habilitacao somente por decision formal; preferido apenas quando cloud adicional estiver habilitado.
  - remove linguagem ambigua de "recomendado por padrao" em docs operacionais e allowlists.
  - cria pacote normativo `INTEGRATIONS/` para AI-Trader, ClawWork e OpenClaw upstream com contratos, riscos e testes.
  - formaliza compatibilidade dual de interface do runtime: `gateway.control_plane.ws` (canonico) + `chatCompletions` opcional sob policy.
  - registra override deliberado de timezone operacional para `America/Sao_Paulo` neste repositorio, mantendo rastreabilidade do exemplo original em `felixcraft.md`.
  - adiciona gate `make eval-integrations` com validacao de docs/schemas/regras anti-bypass.
  - endurece `eval-runtime` para validar qualidade minima de notas diarias de memoria (secoes e bullets obrigatorios).
- Migracao:
  - rodar `make eval-models`, `make eval-integrations`, `make eval-runtime` e `make eval-gates`.
  - manter qualquer integracao de AI-Trader em modo `signal_only`.
  - manter ClawWork em `lab_isolated` por default e habilitar `governed` somente com gateway-only + policy.

### 2026-02-24 - Merge do paradigma `llms_locais.md` com OpenClaw-first + LiteLLM
- RFCs afetadas: RFC-001, RFC-015, RFC-030, RFC-050.
- Impacto:
  - remove OpenRouter como recomendacao padrao e corrige desalinhamento para baseline OpenClaw-first.
  - formaliza stack de roteamento: `OpenClaw -> LiteLLM -> supervisores pagos` + workers locais bracais.
  - define contratos normativos: `routing_stack_contract`, `supervisor_contract`, `local_worker_contract`, `capacity_guard_contract`, `fallback_contract`.
  - fixa aliases de supervisores: `codex-main` (primario) e `claude-review` (secundario).
  - explicita regra de capacidade local: maior potencia local possivel somente dentro de gates de sucesso/latencia/retry/contexto.
  - reforca auditoria obrigatoria de fallback (`requested_model`, `effective_model`, `fallback_step`, `reason`) em 100% das execucoes.
  - atualiza setup/env/scripts para LiteLLM e ajusta gates `eval-models` para o novo contrato.
- Migracao:
  - atualizar `.env` com `LITELLM_API_KEY`, `LITELLM_MASTER_KEY`, `CODEX_OAUTH_ACCESS_TOKEN`, `ANTHROPIC_API_KEY`.
  - manter OpenRouter desabilitado por default; habilitar apenas via decision formal.
  - rerodar `bash scripts/onboard_linux.sh`, `bash scripts/verify_linux.sh` e `make eval-models`.

### 2026-02-24 - Reauditoria de inadequacoes com `felixcraft.md` como fonte suprema
- RFCs afetadas: RFC-001, RFC-010, RFC-015, RFC-030, RFC-050, RFC-060.
- Impacto:
  - `felixcraft.md` passa a referencia arquitetural suprema na hierarquia documental.
  - arquitetura realinhada para OpenClaw gateway-first com providers cloud plugaveis.
  - contratos normativos adicionados: `openclaw_runtime_config`, `approval_policy`, `memory_contract`, `ops_autonomy_contract`.
  - A2A, hooks/webhooks, `bind=loopback` e `chatCompletions` entram como contrato explicito de runtime.
  - regra endurecida: email nunca e canal confiavel de comando.
  - regra endurecida: side effect financeiro sempre exige aprovacao humana explicita por ordem.
  - heartbeat baseline ajustado para 15 minutos e ciclo noturno de memoria formalizado as 23:00.
- Migracao:
  - criar/manter `workspaces/main/MEMORY.md` e notas diarias `workspaces/main/memory/YYYY-MM-DD.md`.
  - ajustar ambientes para `HEARTBEAT_MINUTES=15`.
  - revisar gates/scripts para validar novos contratos e evitar bypass por canal nao confiavel.

### 2026-02-24 - Readequacao completa para OpenClaw (rollback da migracao Nanobot)
- RFCs afetadas: RFC-001, RFC-015, RFC-040, RFC-050, RFC-060.
- Impacto:
  - runtime oficial volta para OpenClaw.
  - paths canonicos de estado/auditoria voltam para `.openclaw`.
  - onboarding e verify retornam ao fluxo OpenClaw (Node/NVM/npm + `openclaw` CLI).
  - remove referencias operacionais a Nanobot/ClawWork e contratos associados.
  - adiciona guia tecnico de setup em `DEV/DEV-OPENCLAW-SETUP.md`.
- Migracao:
  - remover estados locais legados do runtime anterior nos ambientes operacionais.
  - adotar `workspaces/main/.openclaw/workspace-state.json` como estado canonico versionado.
  - rerodar `bash scripts/onboard_linux.sh` e `bash scripts/verify_linux.sh` em hosts ativos.

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
  - define OpenClaw como backbone unico de producao para trading live.
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
  - configurar trilha auditavel nao versionada em `workspaces/main/.openclaw/audit/` e espelhamento externo.

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
