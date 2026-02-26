---
doc_id: "CHANGELOG.md"
version: "2.25"
status: "active"
owner: "PM"
last_updated: "2026-02-26"
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

### 2026-02-26 - Execucao do ISSUE-F5-03-04 (A2A cross-workspace + Slack event normalizado)
- RFCs afetadas: RFC-001, RFC-015, RFC-030, RFC-050.
- Impacto:
  - executa `ISSUE-F5-03-04` do `EPIC-F5-03` com `PRD/PRD-MASTER.md` e `PRD/ROADMAP.md` (`B1-R16`, `B1-R17`) como fonte de verdade para reforcar:
    - delegacao A2A cross-workspace com allowlist + limites de concorrencia/custo;
    - fallback para fila serial em conflito de capacidade/custo;
    - normalizacao de evento Slack com `idempotency_key` e `thread_context` tipado (`issue_id` + `microtask_id`).
  - endurece contratos versionados:
    - `ARC/schemas/a2a_delegation_event.schema.json`;
    - `ARC/schemas/webhook_ingest_event.schema.json`.
  - endurece validacao executavel em:
    - `scripts/ci/eval_runtime_contracts.sh`.
  - alinha docs normativos:
    - `ARC/ARC-CORE.md`
    - `PRD/PRD-MASTER.md`
  - publica evidencia da issue em:
    - `artifacts/phase-f5/epic-f5-03-issue-04-a2a-cross-workspace-slack-normalization.md`.
- Migracao:
  - qualquer delegacao A2A cross-workspace MUST preservar limites explicitos de concorrencia/custo e fallback serial em conflito.
  - evento Slack com contexto de thread incompleto MUST bloquear `make eval-runtime`.

### 2026-02-26 - Execucao do ISSUE-F5-03-03 (governanca avancada de catalog/router custo e privacidade por preset)
- RFCs afetadas: RFC-001, RFC-015, RFC-030, RFC-050.
- Impacto:
  - executa `ISSUE-F5-03-03` do `EPIC-F5-03` com `PRD/PRD-MASTER.md` e `PRD/ROADMAP.md` (`B1-R08`, `B1-R09`, `B1-R10`, `B1-R13`, `B1-R14`) como fonte de verdade para reforcar:
    - `preset_id` obrigatorio no contrato `router_decision`;
    - governanca de custo com `burn_rate_policy` + `circuit_breaker_action`;
    - governanca de privacidade com `privacy_controls` e coerencia de rota `sensitive` (`no_fallback`, `pin_provider`, `ZDR`).
  - endurece contratos versionados:
    - `ARC/schemas/router_decision.schema.json` com requireds de preset/custo/privacidade;
    - `ARC/schemas/models_catalog.schema.json` com `catalog_version` obrigatorio.
  - endurece validacoes executaveis:
    - `scripts/ci/eval_models.sh`;
    - `scripts/ci/eval_runtime_contracts.sh`.
  - alinha docs normativos:
    - `ARC/ARC-MODEL-ROUTING.md`
    - `SEC/SEC-POLICY.md`
  - publica evidencia da issue em:
    - `artifacts/phase-f5/epic-f5-03-issue-03-routing-cost-privacy-preset-governance.md`.
- Migracao:
  - qualquer alteracao de roteamento em rota `sensitive` MUST preservar `no_fallback=true`, `pin_provider=true` e `ZDR`.
  - ausencia de `preset_id` no contrato `router_decision` MUST bloquear `make eval-gates`.

### 2026-02-26 - Execucao do ISSUE-F5-03-02 (cron proativo e memoria noturna com trilha auditavel)
- RFCs afetadas: RFC-001, RFC-030, RFC-050.
- Impacto:
  - executa `ISSUE-F5-03-02` do `EPIC-F5-03` com `PRD/PRD-MASTER.md` e `PRD/ROADMAP.md` (`B1-R11`, `B1-R12`) como fonte de verdade para reforcar:
    - contrato versionado para ciclo noturno de memoria (`nightly-extraction`);
    - trilha minima por execucao (`scheduled_at`, `executed_at`, `daily_note_ref`, `status`);
    - exigencia de `incident_ref` quando houver falha ou atraso maior que 24h.
  - adiciona schema dedicado:
    - `ARC/schemas/nightly_memory_cycle.schema.json`.
  - endurece `scripts/ci/eval_runtime_contracts.sh` para exigir:
    - campos minimos do contrato noturno e validacoes `valid/invalid`;
    - bloqueio para caso de falha/atraso >24h sem incidente.
  - atualiza contratos normativos:
    - `PRD/PRD-MASTER.md`
    - `ARC/ARC-HEARTBEAT.md`
    - `workspaces/main/MEMORY.md`
  - publica evidencia da issue em:
    - `artifacts/phase-f5/epic-f5-03-issue-02-nightly-cron-memory-audit-trail.md`.
- Migracao:
  - qualquer alteracao no ciclo noturno MUST preservar `job_name=nightly-extraction` e timezone `America/Sao_Paulo`.
  - falha/atraso >24h sem `incident_ref` MUST bloquear `make eval-runtime`.

### 2026-02-26 - Execucao do ISSUE-F5-03-01 (autonomia de jobs longos com sessao isolada e restart controlado)
- RFCs afetadas: RFC-001, RFC-030, RFC-050.
- Impacto:
  - executa `ISSUE-F5-03-01` do `EPIC-F5-03` com `PRD/PRD-MASTER.md` e `PRD/ROADMAP.md` (`B1-R12`) como fonte de verdade para reforcar:
    - contrato versionado de autonomia operacional para jobs longos com sessao isolada;
    - deteccao de `stalled` em 2 checks consecutivos e restart controlado com `trace_id`;
    - abertura de incidente em `stalled` e preservacao de contexto (`issue_id` + estado do DAG).
  - adiciona schema dedicado:
    - `ARC/schemas/ops_autonomy_contract.schema.json`.
  - endurece `scripts/ci/eval_runtime_contracts.sh` para exigir:
    - campos minimos do contrato (`isolation_mode`, `healthcheck_interval_minutes`, `stalled_threshold_checks`, `restart_policy`, `incident_on_stalled`, `preserve_issue_context`);
    - cenarios executaveis valid/invalid para o contrato.
  - atualiza contratos normativos:
    - `PRD/PRD-MASTER.md`
    - `ARC/ARC-HEARTBEAT.md`
  - publica evidencia da issue em:
    - `artifacts/phase-f5/epic-f5-03-issue-01-ops-autonomy-jobs-heartbeat.md`.
- Migracao:
  - qualquer alteracao no contrato de autonomia de jobs longos MUST preservar `stalled_threshold_checks=2` e `incident_on_stalled=true`.
  - ausencia de restart controlado com trilha `trace_id` MUST bloquear `make eval-runtime`.

### 2026-02-26 - Execucao do ISSUE-F5-02-05 (runbook de degradacao com posicao aberta + fechamento do EPIC-F5-02)
- RFCs afetadas: RFC-001, RFC-035, RFC-050, RFC-060.
- Impacto:
  - executa `ISSUE-F5-02-05` do `EPIC-F5-02` com `PRD/PRD-MASTER.md` e `PRD/ROADMAP.md` (`B1-08`) como fonte de verdade para reforcar:
    - exigencia de `TRADING_BLOCKED` em degradacao com posicao aberta;
    - exigencia de `position_snapshot`/`open_orders_snapshot`;
    - exigencia de reconciliacao e criterio de retorno seguro sem exposicao nao gerenciada.
  - endurece `scripts/ci/eval_trading.sh` para validar runbook de degradacao em:
    - `ARC/ARC-DEGRADED-MODE.md`
    - `INCIDENTS/DEGRADED-MODE-PROCEDURE.md`
  - publica evidencias:
    - `artifacts/phase-f5/epic-f5-02-issue-05-degraded-open-position-runbook.md`
    - `artifacts/phase-f5/epic-f5-02-trading-hardening.md`
  - atualiza status do `EPIC-F5-02` para `done` em `PM/PHASES/F5-INTEGRACOES-EXTERNAS-GOVERNADAS/EPICS.md`.
- Migracao:
  - qualquer alteracao no runbook de degradacao de trading MUST preservar `TRADING_BLOCKED`, snapshots e reconciliacao auditavel.
  - ausencia desses requisitos MUST bloquear `make eval-trading`.

### 2026-02-26 - Execucao do ISSUE-F5-02-04 (credenciais live restritas + gate CI de trading)
- RFCs afetadas: RFC-001, RFC-015, RFC-050, RFC-060.
- Impacto:
  - executa `ISSUE-F5-02-04` do `EPIC-F5-02` com `PRD/PRD-MASTER.md` e `PRD/ROADMAP.md` (`B1-09`, `B1-12`) como fonte de verdade para reforcar:
    - politica de credenciais live com principio `no-withdraw` e `IP allowlist` quando suportado;
    - gate CI obrigatorio de trading com execucao de `make eval-trading`.
  - endurece `scripts/ci/eval_trading.sh` para exigir:
    - regras de credencial live (`sem permissao de saque`, `IP allowlist`) nos docs normativos de trading;
    - politicas em `SEC/allowlists/ACTIONS.yaml` (`execution_gateway_only` para acoes de ordem e `trading_withdraw_funds` bloqueado);
    - presenca do workflow `.github/workflows/ci-trading.yml` com etapa de `make eval-trading`.
  - publica evidencia da issue em:
    - `artifacts/phase-f5/epic-f5-02-issue-04-credentials-ci-gate.md`.
- Migracao:
  - mudanca em credenciais/politicas de trading live MUST preservar bloqueio de saque e restricao via gateway.
  - ausencia de workflow CI com `make eval-trading` MUST bloquear promote de alteracao de trading.

### 2026-02-26 - Execucao do ISSUE-F5-02-03 (fail_closed primaria + single_engine_mode secundaria)
- RFCs afetadas: RFC-001, RFC-035, RFC-050, RFC-060.
- Impacto:
  - executa `ISSUE-F5-02-03` do `EPIC-F5-02` com `PRD/PRD-MASTER.md` e `PRD/ROADMAP.md` (`B1-07`, `B2-R04`) como fonte de verdade para reforcar:
    - `fail_closed` obrigatorio em falha de engine primaria;
    - `single_engine_mode` restrito a falha de engine secundaria/auxiliar com primaria saudavel.
  - endurece `scripts/ci/eval_trading.sh` para exigir, sem drift entre docs de trading:
    - regra de `fail_closed` vinculada a falha primaria;
    - regra de `single_engine_mode` vinculada a falha secundaria;
    - condicao de primaria saudavel para ativacao de `single_engine_mode`.
  - atualiza `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md` para explicitar a condicao de primaria saudavel.
  - publica evidencia da issue em:
    - `artifacts/phase-f5/epic-f5-02-issue-03-fail-closed-single-engine.md`.
- Migracao:
  - qualquer alteracao nas regras de degradacao de trading MUST preservar separacao explicita entre falha primaria (`fail_closed`) e secundaria (`single_engine_mode`).
  - ausencia de condicao de primaria saudavel no `single_engine_mode` MUST bloquear `make eval-trading`.

### 2026-02-26 - Execucao do ISSUE-F5-02-02 (idempotencia client_order_id + reconciliacao de falha parcial)
- RFCs afetadas: RFC-001, RFC-035, RFC-050, RFC-060.
- Impacto:
  - executa `ISSUE-F5-02-02` do `EPIC-F5-02` com `PRD/PRD-MASTER.md` e `PRD/ROADMAP.md` (`B1-06`) como fonte de verdade para reforcar:
    - idempotencia forte de ordem via `client_order_id` + `idempotency_key`;
    - replay tratado como `no-op` auditavel;
    - reconciliacao de falha parcial com estado final consistente e auditavel.
  - estende `ARC/schemas/execution_gateway.schema.json` com:
    - `client_order_id` obrigatorio;
    - metadados de trilha de replay/reconciliacao (`replay_disposition`, `reconciliation_status`, `reconciliation_trace_id`).
  - endurece `scripts/ci/eval_trading.sh` para exigir:
    - `client_order_id` como campo obrigatorio do contrato de gateway;
    - regras explicitas de replay e reconciliacao nos docs normativos de trading.
  - atualiza docs de trading:
    - `VERTICALS/TRADING/TRADING-PRD.md`
    - `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`
  - publica evidencia da issue em:
    - `artifacts/phase-f5/epic-f5-02-issue-02-idempotency-reconciliation.md`.
- Migracao:
  - qualquer alteracao no contrato de execucao de ordem MUST preservar `client_order_id` e `idempotency_key` como requisitos obrigatorios.
  - replay sem comportamento `no-op` auditavel ou reconciliacao sem estado final consistente MUST bloquear `make eval-trading`.

### 2026-02-26 - Execucao do ISSUE-F5-02-01 (pre_trade_validator por simbolo + contratos versionados)
- RFCs afetadas: RFC-001, RFC-010, RFC-050, RFC-060.
- Impacto:
  - executa `ISSUE-F5-02-01` do `EPIC-F5-02` com `PRD/PRD-MASTER.md` e `PRD/ROADMAP.md` (`B1-05`, `B1-10`) como fonte de verdade para reforcar:
    - contratos versionados dedicados para `execution_gateway` e `pre_trade_validator`;
    - validacao explicita por simbolo no contrato de pre-trade.
  - adiciona schemas dedicados em `ARC/schemas/`:
    - `execution_gateway.schema.json`
    - `pre_trade_validator.schema.json`
  - endurece `scripts/ci/eval_trading.sh` com validacoes estruturais:
    - presenca e JSON valido dos novos schemas;
    - enforcement de `schema_version` + `contract_version`;
    - enforcement de campos minimos obrigatorios dos contratos;
    - enforcement textual do contrato v1 e de `symbol_constraints` no `TRADING-PRD`.
  - atualiza `VERTICALS/TRADING/TRADING-PRD.md` para explicitar `symbol` e `symbol_constraints` na entrada obrigatoria de `pre_trade_validator`.
  - publica evidencia da issue em:
    - `artifacts/phase-f5/epic-f5-02-issue-01-validator-contracts.md`.
- Migracao:
  - alteracoes em contratos de gateway/validator MUST preservar `schema_version=1.0` e `contract_version=v1`.
  - qualquer regressao de campos minimos obrigatorios dos contratos MUST bloquear `make eval-trading`.

### 2026-02-26 - Execucao do ISSUE-F5-01-04 (modo permitido explicito por integracao sem ambiguidade)
- RFCs afetadas: RFC-001, RFC-010, RFC-015, RFC-050, RFC-060.
- Impacto:
  - executa `ISSUE-F5-01-04` do `EPIC-F5-01` com `PRD/PRD-MASTER.md` e `PRD/ROADMAP.md` (`B1-20`, `B1-22`, `B1-23`, `B1-24`) como fonte de verdade para explicitar:
    - `AI-Trader` em modo `signal_only`;
    - `ClawWork` em `lab_isolated` (default) e `governed` (`gateway-only`);
    - compatibilidade upstream via `gateway.control_plane.ws` canonico + `chatCompletions` opcional sob policy.
  - atualiza `INTEGRATIONS/README.md` com matriz canonica de modos permitidos por integracao.
  - endurece `scripts/ci/eval_integrations.sh` para exigir a matriz e suas regras de modo permitido no pacote `INTEGRATIONS`.
  - publica evidencias:
    - `artifacts/phase-f5/epic-f5-01-issue-04-allowed-modes-no-ambiguity.md`;
    - `artifacts/phase-f5/epic-f5-01-integrations-anti-bypass.md`.
  - atualiza status do `EPIC-F5-01` para `done` em `PM/PHASES/F5-INTEGRACOES-EXTERNAS-GOVERNADAS/EPICS.md`.
- Migracao:
  - qualquer alteracao em `INTEGRATIONS/*` MUST preservar a matriz de modos permitidos e suas regras anti-bypass.
  - tratar ambiguidade de modo permitido como bloqueante de promote da fase `F5`.

### 2026-02-26 - Execucao do ISSUE-F5-01-03 (contratos versionados + compatibilidade dual runtime)
- RFCs afetadas: RFC-001, RFC-030, RFC-050, RFC-060.
- Impacto:
  - executa `ISSUE-F5-01-03` do `EPIC-F5-01` com `PRD/PRD-MASTER.md` e `PRD/ROADMAP.md` (`B1-21`, `B1-24`) como fonte de verdade para reforcar:
    - metadado minimo de versionamento nos contratos `signal_intent`, `order_intent`, `execution_report` e `economic_run`;
    - continuidade da validacao dual de runtime (`gateway.control_plane.ws` canonico + `chatCompletions` opcional sob policy).
  - atualiza schemas de integracao em `ARC/schemas/` para incluir:
    - `schema_version` obrigatorio em `required[]`;
    - `properties.schema_version` com `type=string` e `const=\"1.0\"`.
  - endurece `scripts/ci/eval_integrations.sh` com nova validacao executavel:
    - `schema_assert_version_metadata` para exigir `$schema`, `$id`, `required.schema_version` e `properties.schema_version.const`.
  - publica evidencia da issue em:
    - `artifacts/phase-f5/epic-f5-01-issue-03-versioned-contracts-runtime-dual.md`.
- Migracao:
  - qualquer alteracao nos schemas de integracao MUST preservar `schema_version` com metadata de versao valida.
  - manter `make eval-integrations` como gate obrigatorio para contratos versionados e compatibilidade dual do runtime.

### 2026-02-26 - Execucao do ISSUE-F5-01-02 (bloqueio de ordem direta externa + allowlist de venue)
- RFCs afetadas: RFC-001, RFC-010, RFC-015, RFC-050, RFC-060.
- Impacto:
  - executa `ISSUE-F5-01-02` do `EPIC-F5-01` com `PRD/PRD-MASTER.md` e `PRD/ROADMAP.md` (`B1-03`, `B1-11`, `B1-22`) como fonte de verdade para reforcar:
    - caminho unico de execucao live via `execution_gateway`;
    - bloqueio hard de ordem direta externa (anti-bypass);
    - allowlist de dominios de venue com bloqueio para dominio fora da allowlist.
  - endurece `scripts/ci/eval_trading.sh` com:
    - exigencia de `SEC/allowlists/DOMAINS.yaml` como arquivo obrigatorio de trading;
    - validacao por arquivo da regra `somente execution_gateway pode enviar ordem live`;
    - validacao por arquivo da regra de allowlist de venue;
    - validacao de baseline da allowlist Binance fase 1 (`trading_phase1_binance`, `api.binance.com`, `deny` default).
  - atualiza `VERTICALS/TRADING/TRADING-PRD.md` para alinhar explicitamente:
    - caminho unico de execucao live via gateway;
    - dependencia de allowlist de venue em `SEC/allowlists/DOMAINS.yaml`.
  - publica evidencia da issue em:
    - `artifacts/phase-f5/epic-f5-01-issue-02-direct-order-block-venue-allowlist.md`.
- Migracao:
  - executar `make eval-trading` em alteracoes que toquem regras de execucao de ordem, venue, allowlists ou contratos de trading.
  - tratar qualquer ausencia de regra de `execution_gateway only` ou allowlist de venue como bloqueante para operacao live.

### 2026-02-26 - Execucao do ISSUE-F5-01-01 (TradingAgents + signal_intent + normalizacao/deduplicacao)
- RFCs afetadas: RFC-001, RFC-010, RFC-050, RFC-060.
- Impacto:
  - executa `ISSUE-F5-01-01` do `EPIC-F5-01` com `PRD/PRD-MASTER.md` e `PRD/ROADMAP.md` (`B1-01`, `B1-02`, `B1-22`) como fonte de verdade para reforcar:
    - `TradingAgents` como engine primaria de sinal nos docs normativos de trading;
    - pipeline oficial `AI-Trader -> signal_intent -> normalizacao/deduplicacao -> pre_trade_validator -> HITL -> execution_gateway` sem drift entre `TRADING-PRD` e `TRADING-ENABLEMENT-CRITERIA`;
    - regra anti-bypass de ordem direta validada por arquivo.
  - endurece `scripts/ci/eval_trading.sh` com:
    - helper `search_re_each_file` para exigir padroes obrigatorios em cada documento alvo;
    - validacao obrigatoria de `TradingAgents.*engine primaria de sinal` nos dois docs de trading;
    - validacao por arquivo do pipeline oficial e da regra anti-bypass do AI-Trader.
  - publica evidencia da issue em:
    - `artifacts/phase-f5/epic-f5-01-issue-01-tradingagents-signal-intent.md`.
- Migracao:
  - executar `make eval-trading` em alteracoes que toquem `VERTICALS/TRADING/*` ou `scripts/ci/eval_trading.sh`.
  - tratar ausencia de `TradingAgents` como engine primaria, pipeline oficial ou regra anti-bypass em qualquer doc alvo como bloqueante para promote de `F5`.

### 2026-02-26 - Execucao do EPIC-F4-03 (coerencia normativa anti-drift e gate)
- RFCs afetadas: RFC-001, RFC-015, RFC-030, RFC-040, RFC-050, RFC-060.
- Impacto:
  - executa cenarios `Red/Green/Refactor` do `EPIC-F4-03` com `PRD/PRD-MASTER.md` e `PRD/ROADMAP.md` como fonte de verdade para:
    - regra canonica de OpenRouter por arquivo normativo e bloqueio de frases proibidas;
    - matriz de compatibilidade upstream e pipeline anti-bypass exigidos sem drift;
    - consolidacao de evidencia unica de fase com decisao formal `promote|hold`.
  - endurece `scripts/ci/eval_integrations.sh` com validacoes anti-drift por arquivo:
    - adiciona helpers `search_re_each_file` e `search_fixed_each_file`;
    - exige frase canonica OpenRouter em cada arquivo normativo alvo;
    - exige pipeline oficial e regra anti-bypass em `VERTICALS/TRADING/TRADING-PRD.md` e `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`.
  - publica evidencias por issue e consolidado:
    - `artifacts/phase-f4/epic-f4-03-issue-01-openrouter-canonical-rule.md`
    - `artifacts/phase-f4/epic-f4-03-issue-02-upstream-matrix-anti-bypass.md`
    - `artifacts/phase-f4/epic-f4-03-issue-03-phase-evidence-promote-hold.md`
    - `artifacts/phase-f4/epic-f4-03-coerencia-normativa-gate.md`
    - `artifacts/phase-f4/validation-summary.md`
  - atualiza status do `EPIC-F4-03` para `done` em `PM/PHASES/F4-ONBOARDING-REPOS-CONTEXTO-EXTERNO/EPICS.md`.
- Migracao:
  - executar `make eval-integrations` em alteracoes que toquem `INTEGRATIONS/*`, docs normativos de OpenRouter, docs de trading ou `scripts/ci/eval_integrations.sh`.
  - tratar ausencia por arquivo de regra canonica OpenRouter, pipeline oficial ou regra anti-bypass como bloqueante de promote da fase `F4`.

### 2026-02-26 - Execucao do EPIC-F4-02 (contratos e schemas de integracao)
- RFCs afetadas: RFC-001, RFC-015, RFC-030, RFC-040, RFC-050, RFC-060.
- Impacto:
  - executa cenarios `Red/Green/Refactor` do `EPIC-F4-02` com `PRD/PRD-MASTER.md` e `PRD/ROADMAP.md` como fonte de verdade para:
    - presenca e JSON valido dos schemas obrigatorios em `ARC/schemas/`;
    - campos minimos obrigatorios em `signal_intent`, `order_intent`, `execution_report` e `economic_run`;
    - contrato dual de runtime (`gateway.control_plane.ws` canonico + trilha `chatCompletions.enabled`) e shape de `provider_path`.
  - endurece `scripts/ci/eval_integrations.sh` com validacoes estruturais de contrato:
    - enforcement de `required[]` + `properties` minimos para os quatro contratos versionados;
    - enforcement da estrutura dual de `openclaw_runtime_config` sem tornar `gateway.http` obrigatorio global;
    - enforcement de `provider_path` como array nao vazio de strings nao vazias.
  - publica evidencias por issue e consolidado:
    - `artifacts/phase-f4/epic-f4-02-issue-01-schema-presence-json-valid.md`
    - `artifacts/phase-f4/epic-f4-02-issue-02-min-required-fields.md`
    - `artifacts/phase-f4/epic-f4-02-issue-03-runtime-dual-provider-path.md`
    - `artifacts/phase-f4/epic-f4-02-schema-validation.md`
  - atualiza status do `EPIC-F4-02` para `done` em `PM/PHASES/F4-ONBOARDING-REPOS-CONTEXTO-EXTERNO/EPICS.md`.
- Migracao:
  - executar `make eval-integrations` em alteracoes que toquem `ARC/schemas/*` de integracao, `INTEGRATIONS/*` ou `scripts/ci/eval_integrations.sh`.
  - tratar qualquer regressao de required minimo, runtime dual ou shape de `provider_path` como bloqueante de promote na fase `F4`.

### 2026-02-26 - Execucao do EPIC-F4-01 (pacote INTEGRATIONS baseline)
- RFCs afetadas: RFC-001, RFC-015, RFC-030, RFC-040, RFC-050, RFC-060.
- Impacto:
  - executa cenarios `Red/Green/Refactor` do `EPIC-F4-01` com `PRD/PRD-MASTER.md` e `PRD/ROADMAP.md` como fonte de verdade para:
    - presenca dos docs obrigatorios do pacote `INTEGRATIONS/`;
    - regra mandataria de AI-Trader em modo `signal_intent` only com anti-bypass;
    - regra mandataria de ClawWork com `lab_isolated` default e `governed` gateway-only.
  - publica evidencias por issue e consolidado:
    - `artifacts/phase-f4/epic-f4-01-issue-01-required-docs.md`
    - `artifacts/phase-f4/epic-f4-01-issue-02-ai-trader-signal-only.md`
    - `artifacts/phase-f4/epic-f4-01-issue-03-clawwork-governed-gateway-only.md`
    - `artifacts/phase-f4/epic-f4-01-integrations-baseline.md`
  - atualiza status do `EPIC-F4-01` para `done` em `PM/PHASES/F4-ONBOARDING-REPOS-CONTEXTO-EXTERNO/EPICS.md`.
- Migracao:
  - executar `make eval-integrations` em alteracoes que toquem `INTEGRATIONS/`, `ARC/schemas/*` de integracao ou `scripts/ci/eval_integrations.sh`.
  - tratar linguagem ambigua para AI-Trader/ClawWork como bloqueante de promote da fase `F4`.

### 2026-02-26 - Execucao do EPIC-F3-03 (heartbeat, timezone e operacao critica)
- RFCs afetadas: RFC-001, RFC-015, RFC-030, RFC-040, RFC-050, RFC-060.
- Impacto:
  - executa cenarios `Red/Green/Refactor` para validar coerencia de heartbeat, timezone e regras criticas no gate `make eval-runtime`, cobrindo:
    - baseline oficial de heartbeat em 15 minutos (`ARC/ARC-HEARTBEAT.md` + `workspaces/main/HEARTBEAT.md`);
    - timezone canonico `America/Sao_Paulo` e nightly extraction as `23:00`;
    - regra de email como canal nao confiavel para comando;
    - regra de aprovacao humana explicita para side effect financeiro.
  - endurece `scripts/ci/eval_runtime_contracts.sh` para baseline do ARC exigir simultaneamente:
    - `baseline unico de 15 minutos`;
    - `base global: 15 minutos`.
  - publica evidencias por issue e consolidado:
    - `artifacts/phase-f3/epic-f3-03-issue-01-heartbeat-baseline.md`
    - `artifacts/phase-f3/epic-f3-03-issue-02-timezone-nightly.md`
    - `artifacts/phase-f3/epic-f3-03-issue-03-channel-financial-rules.md`
    - `artifacts/phase-f3/epic-f3-03-heartbeat-timezone-operation.md`
  - atualiza status do `EPIC-F3-03` para `done` em `PM/PHASES/F3-RUNTIME-MINIMO-MEMORIA-HEARTBEAT/EPICS.md`.
- Migracao:
  - manter baseline de heartbeat do ARC com as duas ancoras canonicas (normativa e operacional) para evitar drift parcial.
  - executar `make eval-runtime` em alteracoes que toquem heartbeat, timezone, regras de canal ou aprovacao financeira.

### 2026-02-26 - Execucao do EPIC-F3-02 (memoria diaria com contrato minimo)
- RFCs afetadas: RFC-001, RFC-030, RFC-040, RFC-050.
- Impacto:
  - executa cenarios `Red/Green/Refactor` para validar contrato minimo de memoria diaria no gate `make eval-runtime`, cobrindo:
    - presenca canonica de `workspaces/main/MEMORY.md`;
    - presenca de nota diaria em `workspaces/main/memory/YYYY-MM-DD.md`;
    - header canonico `# YYYY-MM-DD`;
    - secoes obrigatorias `Key Events`, `Decisions Made`, `Facts Extracted`;
    - bullet minimo por secao obrigatoria.
  - publica evidencias por issue e consolidado:
    - `artifacts/phase-f3/epic-f3-02-issue-01-memory-daily-files.md`
    - `artifacts/phase-f3/epic-f3-02-issue-02-daily-header-sections.md`
    - `artifacts/phase-f3/epic-f3-02-issue-03-daily-bullet-minimum.md`
    - `artifacts/phase-f3/epic-f3-02-memory-contract.md`
  - atualiza status do `EPIC-F3-02` para `done` em `PM/PHASES/F3-RUNTIME-MINIMO-MEMORIA-HEARTBEAT/EPICS.md`.
- Migracao:
  - manter o contrato minimo atual de nota diaria (existencia de ao menos uma nota `YYYY-MM-DD.md` valida), sem endurecer para obrigatoriedade de "nota do dia".
  - executar `make eval-runtime` em alteracoes que toquem memoria operacional, daily notes, heartbeat ou contrato de runtime.

### 2026-02-26 - Execucao do EPIC-F3-01 (contrato de runtime minimo)
- RFCs afetadas: RFC-001, RFC-030, RFC-040, RFC-050.
- Impacto:
  - endurece `scripts/ci/eval_runtime_contracts.sh` para detectar caminhos duplicados em `required_files`.
  - endurece `eval-runtime` para reportar todos os arquivos obrigatorios ausentes no mesmo ciclo (falha agregada).
  - adiciona validacao executavel do contrato estrutural de `ARC/schemas/openclaw_runtime_config.schema.json`, cobrindo:
    - required top-level (`agents`, `tools`, `channels`, `hooks`, `memory`, `gateway`);
    - required de A2A (`enabled`, `allow`);
    - required de hooks (`enabled`, `mappings`, `internal`) e hooks internos (`boot-md`, `command-logger`, `session-memory`);
    - `gateway.bind.const=loopback`;
    - `gateway.control_plane.ws.required` (`enabled`, `url`);
    - `gateway.http.endpoints.chatCompletions.required` (`enabled`).
  - adiciona fixtures `valid/invalid` no gate para bloquear drift estrutural do contrato de runtime.
  - endurece `eval-runtime` para exigir fonte canonica unica de estado:
    - busca `workspaces/*/.openclaw/workspace-state.json`;
    - bloqueia quando houver 0 ou mais de 1 caminho;
    - exige caminho unico em `workspaces/main/.openclaw/workspace-state.json`.
  - publica evidencias por issue e consolidado:
    - `artifacts/phase-f3/epic-f3-01-issue-01-required-files.md`
    - `artifacts/phase-f3/epic-f3-01-issue-02-runtime-schema-a2a-hooks-gateway.md`
    - `artifacts/phase-f3/epic-f3-01-issue-03-workspace-state-canonical-source.md`
    - `artifacts/phase-f3/epic-f3-01-runtime-contract.md`
  - atualiza status do `EPIC-F3-01` para `done` em `PM/PHASES/F3-RUNTIME-MINIMO-MEMORIA-HEARTBEAT/EPICS.md`.
- Migracao:
  - executar `make eval-runtime` em alteracoes que toquem contratos de runtime, schemas, memoria operacional ou heartbeat.
  - tratar multiplos caminhos de `workspace-state.json` em `workspaces/*/.openclaw/` como `stop-ship`.
  - manter `openclaw_runtime_config.schema.json` alinhado aos required estruturais validados pelo gate.

### 2026-02-26 - Execucao do EPIC-F2-03 (catalog/router/memory/budget + A2A/hooks)
- RFCs afetadas: RFC-001, RFC-015, RFC-030, RFC-050.
- Impacto:
  - reforca baseline de `Model Catalog` com metadata minima obrigatoria + sync explicito em `ARC/schemas/models_catalog.schema.json`:
    - `model_id`, `provider`, `capabilities`, `limits`, `pricing`, `status`;
    - `catalog_synced_at`, `sync_source`, `sync_interval_seconds`.
  - adiciona contrato executavel de roteamento auditavel em `ARC/schemas/router_decision.schema.json` com trilha `requested/effective`, policy aplicada e fallback.
  - adiciona contratos executaveis do memory plane:
    - `ARC/schemas/llm_run.schema.json`;
    - `ARC/schemas/credits_snapshot.schema.json`.
  - adiciona contrato executavel de budget baseline em `ARC/schemas/budget_governor_policy.schema.json` com limites obrigatorios por `run/task/day` e vinculo formal com `credits_snapshots`.
  - adiciona contratos executaveis de rastreabilidade operacional:
    - `ARC/schemas/a2a_delegation_event.schema.json`;
    - `ARC/schemas/webhook_ingest_event.schema.json`.
  - endurece gates executaveis:
    - `scripts/ci/eval_models.sh` para cenarios `valid/invalid` de catalog + router;
    - `scripts/ci/eval_runtime_contracts.sh` para cenarios `valid/invalid` de memory/budget/A2A/hooks.
  - atualiza contratos normativos em:
    - `ARC/ARC-MODEL-ROUTING.md`,
    - `ARC/ARC-CORE.md`,
    - `PM/DECISION-PROTOCOL.md`,
    - `CORE/FINANCIAL-GOVERNANCE.md`,
    - `EVALS/SYSTEM-HEALTH-THRESHOLDS.md`.
  - fecha status de `EPIC-F2-03` como `done` em `PM/PHASES/F2-POS-INSTALACAO-BASELINE-SEGURANCA/EPICS.md`.
  - publica artifacts por issue e artifact consolidado:
    - `artifacts/phase-f2/epic-f2-03-issue-01-model-catalog.md`
    - `artifacts/phase-f2/epic-f2-03-issue-02-model-router.md`
    - `artifacts/phase-f2/epic-f2-03-issue-03-memory-plane.md`
    - `artifacts/phase-f2/epic-f2-03-issue-04-budget-governor.md`
    - `artifacts/phase-f2/epic-f2-03-issue-05-a2a-hooks-traceability.md`
    - `artifacts/phase-f2/epic-f2-03-catalog-router-memory-budget.md`
- Migracao:
  - executar `make eval-models` ao alterar catalogo/router/model-routing.
  - executar `make eval-runtime` ao alterar contratos de memory/budget/A2A/hooks.
  - executar `make phase-f2-gate` antes de promover alteracao de baseline de fase.

### 2026-02-25 - Execucao do EPIC-F2-02 (contratos idempotentes e reconciliacao)
- RFCs afetadas: RFC-001, RFC-015, RFC-035, RFC-040, RFC-050.
- Impacto:
  - adiciona schemas versionados para contratos canonicos:
    - `ARC/schemas/work_order.schema.json`;
    - `ARC/schemas/decision.schema.json`;
    - `ARC/schemas/task_event.schema.json`.
  - adiciona gate executavel `make eval-idempotency` com script `scripts/ci/eval_idempotency_reconciliation.sh`.
  - integra `eval-idempotency` ao harness de fase (`scripts/ci/eval_gates.sh`), mantendo fail-fast por contrato.
  - valida explicitamente no gate:
    - contratos `work_order/decision/task_event` (samples valid/invalid);
    - `SPRINT_OVERRIDE` com no-op por `override_key` e rollback obrigatorio;
    - auto-acoes com `automation_action_id`, deduplicacao por `coalescing_key`/cooldown e fallback `notify-only` sem rollback;
    - reconciliacao em degraded mode com `idempotency_key` + `replay_key`, formula canonica e deduplicacao auditavel.
  - atualiza `DEV/DEV-CI-RULES.md` e `README.md` para incluir `make eval-idempotency` no fluxo oficial.
  - atualiza status de `EPIC-F2-02` para `done` em `PM/PHASES/F2-POS-INSTALACAO-BASELINE-SEGURANCA/EPICS.md`.
  - publica artifact auditavel da rodada em `artifacts/phase-f2/epic-f2-02-idempotency-reconciliation.md`.
- Migracao:
  - executar `make eval-idempotency` em qualquer alteracao que toque contratos `work_order/decision/task_event`, `PM/SPRINT-LIMITS.md`, `ARC/ARC-OBSERVABILITY.md` ou `ARC/ARC-DEGRADED-MODE.md`.
  - manter formula canonica de `replay_key` e regra de deduplicacao auditavel como bloqueantes de release.
  - tratar override sem rollback e auto-acao sem idempotencia como `stop-ship`.

### 2026-02-25 - Execucao do EPIC-F2-01 (baseline de seguranca e gates)
- RFCs afetadas: RFC-001, RFC-015, RFC-040, RFC-050, RFC-060.
- Impacto:
  - adiciona gate agregado de fase `make phase-f2-gate` com fail-fast para o trio obrigatorio (`ci-quality`, `ci-security`, `eval-gates`).
  - adiciona workflow dedicado `.github/workflows/ci-phase-f2-gate.yml` para validar o gate agregado em `push`/`pull_request`.
  - normaliza `PRD/PHASE-USABILITY-GUIDE.md` para exigir trio completo de gates na fase `F2`.
  - endurece `scripts/ci/check_security.sh` para cobrir explicitamente:
    - classificacao `public/internal/sensitive` e minimizacao de prompt por policy;
    - baseline de `SEC/allowlists/PROVIDERS.yaml` por sensibilidade;
    - estrategia de `backup_operator` rastreada em `SEC/allowlists/OPERATORS.yaml`;
    - regra de canal confiavel (`email` nao confiavel), `UNTRUSTED_COMMAND_SOURCE`, challenge para comando critico, e rastreabilidade de approval queue/trust ladder.
  - atualiza status de `EPIC-F2-01` para `done` em `PM/PHASES/F2-POS-INSTALACAO-BASELINE-SEGURANCA/EPICS.md`.
  - publica artifact auditavel da rodada em `artifacts/phase-f2/epic-f2-01-security-gates.md`.
- Migracao:
  - executar `make phase-f2-gate` como gate de consolidacao de fase.
  - manter `SEC/allowlists/OPERATORS.yaml` com `backup_operator_strategy` e `backup_operator_operator_id` validos.
  - tratar qualquer regressao de canal confiavel/approval queue como bloqueio imediato em `make ci-security`.

### 2026-02-25 - Execucao do EPIC-F1-04 (HITL bootstrap e fechamento da F1)
- RFCs afetadas: RFC-001, RFC-010, RFC-015, RFC-040, RFC-050, RFC-060.
- Impacto:
  - endurece `scripts/ci/check_security.sh` para validar baseline HITL de operadores em `SEC/allowlists/OPERATORS.yaml`, incluindo:
    - flags de prontidao obrigatorias no bloco `readiness`;
    - existencia de operador habilitado;
    - identidade Telegram minima por operador habilitado;
    - permissoes `approve/reject/kill` obrigatorias;
    - validacao de coerencia de `slack_ready`.
  - consolida checklist HITL bootstrap e evidencias executaveis da fase em `artifacts/phase-f1/validation-summary.md`.
  - formaliza decisao de fase `F1 -> F2` como `promote`, com Telegram primario validado e fallback Slack explicitamente pendente para F6 (sem bypass de policy).
  - atualiza `PM/PHASES/F1-INSTALACAO-BASE-OPENCLAW/EPICS.md` com `EPIC-F1-01` e `EPIC-F1-04` em status `done`.
  - atualiza resultados de rodada nos epicos `EPIC-F1-01` e `EPIC-F1-04`.
- Migracao:
  - manter `SEC/allowlists/OPERATORS.yaml` aderente ao baseline HITL exigido por `make ci-security`.
  - usar `artifacts/phase-f1/validation-summary.md` como artifact unico para revisao de fechamento da F1.
  - tratar prontidao de fallback Slack (IDs/canal/challenge/idempotencia) como obrigatoria na fase F6 antes de ampliar risco operacional humano.

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
