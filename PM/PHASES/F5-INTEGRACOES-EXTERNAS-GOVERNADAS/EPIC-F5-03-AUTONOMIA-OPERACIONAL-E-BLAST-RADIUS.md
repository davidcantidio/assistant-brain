---
doc_id: "EPIC-F5-03-AUTONOMIA-OPERACIONAL-E-BLAST-RADIUS.md"
version: "1.1"
status: "active"
owner: "PM"
last_updated: "2026-02-26"
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
- artifact unico com provas de autonomia e segregacao de blast radius.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F5-03-01 - Validar contratos de autonomia para jobs longos com tmux heartbeat e restart
**User story**
Como operador, quero jobs longos com monitoramento e restart controlado para evitar perda silenciosa de execucao.

**Plano TDD**
1. `Red`: executar job longo sem sessao isolada e sem health-check.
2. `Green`: exigir sessao isolada (`tmux` ou equivalente) com deteccao `stalled` e restart.
3. `Refactor`: alinhar runbook com `ops_autonomy_contract`.

**Criterios de aceitacao**
- Given job longo sem monitoramento, When heartbeat roda, Then deve abrir incidente e bloquear promocao.
- Given monitoramento com restart controlado, When heartbeat roda, Then o fluxo fica conforme contrato.

### ISSUE-F5-03-02 - Validar cron proativo e memoria noturna com trilha auditavel
**User story**
Como operador, quero cron proativo e consolidacao noturna de memoria para reduzir retrabalho e perda de contexto.

**Plano TDD**
1. `Red`: operar sem cron noturno ou sem atualizacao de memoria diaria.
2. `Green`: exigir `nightly-extraction` e evidencia de notas diarias atualizadas.
3. `Refactor`: padronizar campos minimos de evidencia por ciclo.

**Criterios de aceitacao**
- Given cron/memoria noturna ausente, When validacao roda, Then resultado deve ser `FAIL`.
- Given cron/memoria noturna ativos, When validacao roda, Then resultado deve ser `PASS`.

### ISSUE-F5-03-03 - Validar governanca avancada de catalog router custo e privacidade por preset
**User story**
Como operador, quero catalogo versionado, roteamento avancado e controles de custo/privacidade para evitar fallback opaco e burn-rate sem controle.

**Plano TDD**
1. `Red`: operar sem versionamento de catalogo/preset e sem auditoria de fallback.
2. `Green`: aplicar catalogo versionado, preset, provider routing/pin/no-fallback, burn-rate limits e politica de retention/ZDR por sensibilidade.
3. `Refactor`: consolidar relatorio de custo e fallback por task_type.

**Criterios de aceitacao**
- Given catalogo/roteamento/custo/privacidade sem governanca explicita, When gate roda, Then resultado deve ser `FAIL`.
- Given governanca ativa com trilha auditavel e politica de retention/ZDR, When gate roda, Then resultado deve ser `PASS`.

### ISSUE-F5-03-04 - Validar A2A cross-workspace e adapter Slack event normalizado
**User story**
Como operador, quero delegacao cross-workspace e eventos Slack tipados sem bypass de risco.

**Plano TDD**
1. `Red`: delegar fora de allowlist ou processar evento Slack sem idempotencia.
2. `Green`: exigir `allow[]`, limites de concorrencia/custo e `task_event` com `idempotency_key`.
3. `Refactor`: exigir mapeamento de thread para `issue_id/microtask_id` quando houver contexto.

**Criterios de aceitacao**
- Given delegacao/evento fora de contrato, When validacao roda, Then resultado deve ser `FAIL`.
- Given delegacao/evento conforme contrato, When validacao roda, Then resultado deve ser `PASS`.

### ISSUE-F5-03-05 - Validar fallback HITL Slack com HMAC anti-replay e incidente de restauracao Telegram
**User story**
Como operador, quero fallback Slack seguro para contingencia sem abrir bypass de autenticacao.

**Plano TDD**
1. `Red`: acionar fallback Slack sem assinatura/challenge.
2. `Green`: exigir HMAC + anti-replay + challenge e task automatica `RESTORE_TELEGRAM_CHANNEL`.
3. `Refactor`: alinhar com checklist de contingencia da fase HITL.

**Criterios de aceitacao**
- Given fallback sem controles equivalentes, When contingencia ocorre, Then resultado deve ser `hold`.
- Given fallback com controles equivalentes e incidente aberto, When contingencia ocorre, Then resultado pode ser `pass`.

### ISSUE-F5-03-06 - Validar segregacao de contas e credenciais do agente para reduzir blast radius
**User story**
Como operador, quero separar contas/ativos/credenciais do agente das contas pessoais para reduzir impacto de falha.

**Plano TDD**
1. `Red`: operar com credenciais pessoais misturadas com credenciais do agente.
2. `Green`: exigir segregacao de contas por superficie (`social/email/pagamentos/carteira`) e escopo minimo de permissao.
3. `Refactor`: consolidar runbook de concessao gradual de acessos.

**Criterios de aceitacao**
- Given credenciais sem segregacao por dominio, When revisao de seguranca ocorre, Then resultado deve ser `hold`.
- Given segregacao e escopo minimo comprovados, When revisao ocorre, Then criterio de blast radius fica `pass`.

## Artifact Minimo do Epico
- registrar em `artifacts/phase-f5/epic-f5-03-autonomy-blast-radius.md`:
  - status de jobs longos + heartbeat/restart;
  - status de cron/memoria noturna;
  - status de roteamento/custo avancado;
  - status de A2A/Slack fallback;
  - status de segregacao de contas/credenciais;
  - referencias `B*` cobertas.

## Resultado desta Rodada
- `make eval-runtime` final: `PASS` (`eval-runtime-contracts: PASS`).
- `make eval-gates` final: `PASS` (`eval-gates: PASS`).
- `make ci-security` final: `PASS` (`security-check: PASS`).
- evidencias por issue publicadas:
  - `artifacts/phase-f5/epic-f5-03-issue-01-ops-autonomy-jobs-heartbeat.md`;
  - `artifacts/phase-f5/epic-f5-03-issue-02-nightly-cron-memory-audit-trail.md`;
  - `artifacts/phase-f5/epic-f5-03-issue-03-routing-cost-privacy-preset-governance.md`;
  - `artifacts/phase-f5/epic-f5-03-issue-04-a2a-cross-workspace-slack-normalization.md`;
  - `artifacts/phase-f5/epic-f5-03-issue-05-slack-fallback-hmac-restore-telegram.md`;
  - `artifacts/phase-f5/epic-f5-03-issue-06-account-credential-segregation-blast-radius.md`.
- evidencia consolidada do epico:
  - `artifacts/phase-f5/epic-f5-03-autonomy-blast-radius.md`.
- conclusao: `EPIC-F5-03` concluido no escopo documental/tdd desta rodada.

## Dependencias
- [PRD Master](../../../PRD/PRD-MASTER.md)
- [ARC Heartbeat](../../../ARC/ARC-HEARTBEAT.md)
- [ARC Core](../../../ARC/ARC-CORE.md)
- [Security Policy](../../../SEC/SEC-POLICY.md)
- [Roadmap](../../../PRD/ROADMAP.md)
- [Felixcraft Architecture](../../../felixcraft.md)
- [Felix OpenClaw Pontos Relevantes](../../../felix-openclaw-pontos-relevantes.md)
