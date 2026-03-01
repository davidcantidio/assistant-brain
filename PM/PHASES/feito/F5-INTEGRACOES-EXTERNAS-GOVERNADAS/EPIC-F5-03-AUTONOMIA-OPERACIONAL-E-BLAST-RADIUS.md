---
doc_id: "EPIC-F5-03-AUTONOMIA-OPERACIONAL-E-BLAST-RADIUS.md"
version: "1.2"
status: "done"
owner: "PM"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-015", "RFC-040", "RFC-050"]
---

# EPIC-F5-03 Autonomia operacional e blast radius

## Objetivo
Formalizar autonomia operacional controlada (cron/heartbeat/delegacao longa) e segregacao de identidade/credenciais do agente para reduzir blast radius.

## Resultado de Negocio Mensuravel
- tarefas longas deixam de morrer silenciosamente sem reacao do sistema.
- superficie de risco financeiro/social fica segmentada por conta/credencial do agente.

## Cobertura ROADMAP
- `B1-R08`, `B1-R09`, `B1-R10`, `B1-R11`, `B1-R12`, `B1-R13`, `B1-R14`, `B1-R16`, `B1-R17`, `B1-R18`, `B1-R19`.

## Source refs (felix)
- `felixcraft.md`: heartbeat de 15 min, cron jobs, tmux health-check/stalled restart, delegation to Codex, cost optimization.
- `felix-openclaw-pontos-relevantes.md`: memoria em 3 camadas, cron proativo, jobs longos, evitar TMP, contas separadas (wallet/email/social/payments).

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- `make eval-runtime`, `make eval-gates` e `make ci-security` em `PASS`.
- artifact unico com provas de autonomia e segregacao de blast radius, referenciado em `artifacts/phase-f5/validation-summary.md`.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F5-03-01 - Validar contratos de autonomia para jobs longos com tmux heartbeat e restart
**Owner** `Ops Lead`
**Estimativa** `1d`
**Dependencias**
- `ARC/ARC-HEARTBEAT.md`
- `ARC/schemas/ops_autonomy_contract.schema.json`
- `artifacts/phase-f5/epic-f5-03-issue-01-ops-autonomy-jobs-heartbeat.md`
**Labels** `prio:medium`, `risk:reliability`, `needs-qa`, `needs-owner`, `needs-estimation`
**Definition of Ready**
- contrato de autonomia para jobs longos identificado.
- metadados de run obrigatorios definidos para observabilidade.
**Definition of Done**
- restart controlado e `stalled` detection continuam documentados.
- trilha de run inclui `requested/effective`, `usage`, `fallback`, `errors` e `outcome`.
- artifact registra cenario invalido de metadados incompletos.
**User story**
Como operador, quero jobs longos com monitoramento e restart controlado para evitar perda silenciosa de execucao.

**Plano TDD**
1. `Red`: executar job longo sem sessao isolada e sem health-check.
2. `Green`: exigir sessao isolada (`tmux` ou equivalente) com deteccao `stalled` e restart.
3. `Refactor`: alinhar runbook com `ops_autonomy_contract`.

**Criterios de aceitacao**
- Given job longo `stalled`, When o heartbeat roda, Then deve abrir incidente, registrar `trace_id` e bloquear promocao.
- Given run concluida, When o contrato e validado, Then `requested/effective`, `usage`, `fallback`, `errors` e `outcome` devem estar registrados.
- Given qualquer metadado obrigatorio de run ausente, When `make eval-runtime` roda, Then resultado deve ser `FAIL`.

**Passos QA**
1. Simular job `stalled` e registrar incidente com `trace_id`.
2. Validar payload completo de metadados de run.
3. Executar cenario invalido com metadado ausente e anexar a falha esperada.

### ISSUE-F5-03-02 - Validar cron proativo e memoria noturna com trilha auditavel
**Owner** `Tech Lead Runtime`
**Estimativa** `1d`
**Dependencias**
- `workspaces/main/MEMORY.md`
- `ARC/schemas/nightly_memory_cycle.schema.json`
- `artifacts/phase-f5/epic-f5-03-issue-02-nightly-cron-memory-audit-trail.md`
**Labels** `prio:p0`, `risk:observability`, `blocking-release`, `needs-po-review`, `needs-qa`
**Definition of Ready**
- escopo de `B1-R11` e `B1-R12` separado entre memory plane e metadados de run.
- fontes `model_catalog`, `eval_aggregates` e embeddings operacionais identificadas.
**Definition of Done**
- ACs cobrem explicitamente `model_catalog`, `eval_aggregates`, embeddings e metadados completos de run.
- atraso noturno acima de `24h` sem `incident_ref` reprova o gate.
- artifact registra schema valido/invalido e evidencias da trilha auditavel.
**User story**
Como operador, quero cron proativo e consolidacao noturna de memoria para reduzir retrabalho e perda de contexto.

**Plano TDD**
1. `Red`: operar sem cron noturno ou sem atualizacao de memoria diaria.
2. `Green`: exigir `nightly-extraction` e evidencia de notas diarias atualizadas.
3. `Refactor`: padronizar campos minimos de evidencia por ciclo.

**Criterios de aceitacao**
- Given ausencia de `model_catalog`, `eval_aggregates` ou embeddings operacionais no ciclo noturno, When `make eval-runtime` roda, Then resultado deve ser `FAIL`.
- Given metadados de run incompletos (`requested/effective`, `usage`, `fallback`, `errors`, `outcome`), When `make eval-runtime` roda, Then resultado deve ser `FAIL`.
- Given `nightly-extraction` atrasado por mais de `24h` sem `incident_ref`, When a validacao roda, Then resultado deve ser `FAIL`.

**Passos QA**
1. Executar cenario invalido sem `model_catalog`, `eval_aggregates` ou embeddings.
2. Executar cenario invalido com metadados de run incompletos.
3. Registrar evidencia do atraso > `24h` sem `incident_ref` e do resultado final da issue.

### ISSUE-F5-03-03 - Validar governanca avancada de catalog router custo e privacidade por preset
**Owner** `Platform Lead`
**Estimativa** `1d`
**Dependencias**
- `ARC/ARC-MODEL-ROUTING.md`
- `EVALS/SYSTEM-HEALTH-THRESHOLDS.md`
- `artifacts/phase-f5/epic-f5-03-issue-03-routing-cost-privacy-preset-governance.md`
**Labels** `prio:high`, `risk:privacy`, `compliance-review`, `needs-qa`, `needs-owner`
**Definition of Ready**
- threshold de custo e circuito de bloqueio conhecidos a partir de `EVALS/SYSTEM-HEALTH-THRESHOLDS.md`.
- matriz de privacidade por `task_type` sensivel revisada com `pin_provider`, `no_fallback` e `ZDR`.
**Definition of Done**
- `preset_id` vira obrigatorio no fluxo de roteamento.
- burn-rate e circuit breaker ficam descritos com thresholds objetivos.
- artifact registra matriz de privacidade e os gatilhos de custo aplicados.
**User story**
Como operador, quero catalogo versionado, roteamento avancado e controles de custo/privacidade para evitar fallback opaco e burn-rate sem controle.

**Plano TDD**
1. `Red`: operar sem versionamento de catalogo/preset e sem auditoria de fallback.
2. `Green`: aplicar catalogo versionado, preset, provider routing/pin/no-fallback, burn-rate limits e politica de retention/ZDR por sensibilidade.
3. `Refactor`: consolidar relatorio de custo e fallback por task_type.

**Criterios de aceitacao**
- Given `burn-rate` acima de `90%` do teto diario ou taxa de falha acima de `10%` em `1h`, When o monitoramento roda, Then o circuit breaker deve bloquear tarefas nao criticas e abrir decisao de budget.
- Given rota `sensitive` sem `no_fallback=true`, `pin_provider=true` e `ZDR`, When `make eval-gates` roda, Then resultado deve ser `FAIL`.
- Given `preset_id` ausente em decisao de roteamento, When `make eval-gates` roda, Then resultado deve ser `FAIL`.

**Passos QA**
1. Validar o gatilho de custo acima de `90%` do teto diario.
2. Validar o gatilho de falha acima de `10%` em `1h`.
3. Validar a matriz de privacidade por `task_type` e anexar a evidencia do `preset_id` obrigatorio.

### ISSUE-F5-03-04 - Validar A2A cross-workspace e adapter Slack event normalizado
**Owner** `Tech Lead Integrations`
**Estimativa** `1d`
**Dependencias**
- `ARC/schemas/a2a_delegation_event.schema.json`
- `ARC/schemas/webhook_ingest_event.schema.json`
- `artifacts/phase-f5/epic-f5-03-issue-04-a2a-cross-workspace-slack-normalization.md`
**Labels** `prio:high`, `risk:integration`, `needs-qa`, `blocking-release`
**Definition of Ready**
- allowlist cross-workspace identificada por papel.
- mapeamento de thread e `idempotency_key` definido para o adapter Slack.
**Definition of Done**
- delegacao fora de allowlist e evento sem idempotencia reprovam o gate.
- bypass de gates `R2/R3` fica explicitamente proibido.
- artifact registra os cenarios negativos de delegacao e de evento Slack.
**User story**
Como operador, quero delegacao cross-workspace e eventos Slack tipados sem bypass de risco.

**Plano TDD**
1. `Red`: delegar fora de allowlist ou processar evento Slack sem idempotencia.
2. `Green`: exigir `allow[]`, limites de concorrencia/custo e `task_event` com `idempotency_key`.
3. `Refactor`: exigir mapeamento de thread para `issue_id/microtask_id` quando houver contexto.

**Criterios de aceitacao**
- Given delegacao fora de allowlist por papel, When a validacao roda, Then resultado deve ser `FAIL`.
- Given evento Slack sem `idempotency_key` ou sem mapeamento de thread quando houver contexto, When a validacao roda, Then resultado deve ser `FAIL`.
- Given tentativa de bypass dos gates `R2/R3`, When a validacao roda, Then resultado deve ser `FAIL` bloqueante.

**Passos QA**
1. Executar delegacao fora de allowlist e registrar a falha.
2. Executar evento Slack sem `idempotency_key`.
3. Simular bypass de gate e anexar a evidencia bloqueante no artifact.

### ISSUE-F5-03-05 - Validar fallback HITL Slack com HMAC anti-replay e incidente de restauracao Telegram
**Owner** `Security Lead + HITL Lead`
**Estimativa** `1d`
**Dependencias**
- `PM/DECISION-PROTOCOL.md`
- `SEC/allowlists/OPERATORS.yaml`
- `artifacts/phase-f5/epic-f5-03-issue-05-slack-fallback-hmac-restore-telegram.md`
**Labels** `prio:p0`, `risk:security`, `compliance-review`, `blocking-release`, `needs-qa`
**Definition of Ready**
- fallback Slack validado com HMAC, anti-replay e challenge.
- prontidao de operadores e canais revisada para capital real.
**Definition of Done**
- `slack_user_ids`, `slack_channel_ids` e `backup_operator` aparecem explicitamente nos ACs.
- ausencia de `RESTORE_TELEGRAM_CHANNEL` bloqueia a contingencia.
- artifact registra configuracao de operadores/canais e incidente de restauracao.
**User story**
Como operador, quero fallback Slack seguro para contingencia sem abrir bypass de autenticacao.

**Plano TDD**
1. `Red`: acionar fallback Slack sem assinatura/challenge.
2. `Green`: exigir HMAC + anti-replay + challenge e task automatica `RESTORE_TELEGRAM_CHANNEL`.
3. `Refactor`: alinhar com checklist de contingencia da fase HITL.

**Criterios de aceitacao**
- Given fallback Slack sem HMAC, anti-replay ou challenge, When a contingencia ocorre, Then resultado deve ser `hold`.
- Given fallback Slack sem incidente/task `RESTORE_TELEGRAM_CHANNEL`, When a contingencia ocorre, Then resultado deve ser `hold`.
- Given operador habilitado para capital real com `slack_user_ids` ou `slack_channel_ids` vazios, ou sem `backup_operator` habilitado, When a contingencia ocorre, Then resultado deve ser `FAIL`.

**Passos QA**
1. Validar assinatura HMAC, janela anti-replay e challenge do fallback.
2. Validar a criacao obrigatoria de `RESTORE_TELEGRAM_CHANNEL`.
3. Validar operadores com `slack_user_ids`, `slack_channel_ids` e `backup_operator` antes de anexar o artifact.

### ISSUE-F5-03-06 - Validar segregacao de contas e credenciais do agente para reduzir blast radius
**Owner** `Security Lead + Compliance`
**Estimativa** `1d`
**Dependencias**
- `SEC/allowlists/AGENT-IDENTITY-SURFACES.yaml`
- `SEC/SEC-POLICY.md`
- `artifacts/phase-f5/epic-f5-03-issue-06-account-credential-segregation-blast-radius.md`
**Labels** `prio:p0`, `risk:compliance`, `security-review`, `blocking-release`, `needs-qa`
**Definition of Ready**
- superficies `social`, `email`, `pagamentos` e `carteira` mapeadas para segregacao.
- processo formal de aprovacao/excecao identificado para privilegios especiais.
**Definition of Done**
- mistura entre conta pessoal e conta do agente fica explicitamente proibida.
- `minimum_scope` vira obrigatorio por superficie.
- excecao de privilegio sem aprovacao formal registrada reprova a issue.
**User story**
Como operador, quero separar contas/ativos/credenciais do agente das contas pessoais para reduzir impacto de falha.

**Plano TDD**
1. `Red`: operar com credenciais pessoais misturadas com credenciais do agente.
2. `Green`: exigir segregacao de contas por superficie (`social/email/pagamentos/carteira`) e escopo minimo de permissao.
3. `Refactor`: consolidar runbook de concessao gradual de acessos.

**Criterios de aceitacao**
- Given conta pessoal igual a conta do agente para qualquer superficie, When a revisao de seguranca ocorre, Then resultado deve ser `hold`.
- Given superficie sem `minimum_scope` preenchido, When a revisao de seguranca ocorre, Then resultado deve ser `FAIL`.
- Given excecao de privilegio sem aprovacao formal registrada, When a revisao de compliance ocorre, Then resultado deve ser `FAIL`.

**Passos QA**
1. Validar segregacao por superficie entre conta pessoal e conta do agente.
2. Validar `minimum_scope` para cada superficie listada.
3. Anexar a trilha de aprovacao formal de excecao ou a falha correspondente no artifact.

## Artifact Minimo do Epico
- registrar em `artifacts/phase-f5/epic-f5-03-autonomy-blast-radius.md`:
  - status de jobs longos + heartbeat/restart;
  - status de cron/memoria noturna;
  - status de roteamento/custo avancado;
  - status de A2A/Slack fallback;
  - status de segregacao de contas/credenciais;
  - referencias `B*` cobertas;
  - referencia cruzada para `artifacts/phase-f5/validation-summary.md`.

## Resultado desta Rodada
- `make eval-runtime` final: sem regressao documental esperada para o epico.
- `make eval-gates` final: sem regressao documental esperada para o epico.
- `make ci-security` final: sem regressao documental esperada para o epico.
- evidencias por issue publicadas:
  - `artifacts/phase-f5/epic-f5-03-issue-01-ops-autonomy-jobs-heartbeat.md`;
  - `artifacts/phase-f5/epic-f5-03-issue-02-nightly-cron-memory-audit-trail.md`;
  - `artifacts/phase-f5/epic-f5-03-issue-03-routing-cost-privacy-preset-governance.md`;
  - `artifacts/phase-f5/epic-f5-03-issue-04-a2a-cross-workspace-slack-normalization.md`;
  - `artifacts/phase-f5/epic-f5-03-issue-05-slack-fallback-hmac-restore-telegram.md`;
  - `artifacts/phase-f5/epic-f5-03-issue-06-account-credential-segregation-blast-radius.md`.
- evidencia consolidada do epico:
  - `artifacts/phase-f5/epic-f5-03-autonomy-blast-radius.md`.
- conclusao: `EPIC-F5-03` corrigido para atender a auditoria documental da F5.

## Dependencias
- [PRD Master](../../../../PRD/PRD-MASTER.md)
- [ARC Heartbeat](../../../../ARC/ARC-HEARTBEAT.md)
- [ARC Core](../../../../ARC/ARC-CORE.md)
- [Security Policy](../../../../SEC/SEC-POLICY.md)
- [Roadmap](../../../../PRD/ROADMAP.md)
- [Felixcraft Architecture](../../../../felixcraft.md)
- [Felix OpenClaw Pontos Relevantes](../../../../felix-openclaw-pontos-relevantes.md)
