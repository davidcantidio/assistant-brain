---
doc_id: "SEC-SECRETS.md"
version: "1.5"
status: "active"
owner: "Security"
last_updated: "2026-02-23"
rfc_refs: ["RFC-001", "RFC-015", "RFC-050"]
---

# SEC Secrets

## Objetivo
Definir armazenamento, escopo, rotacao e auditoria de segredos operacionais com separacao clara entre chave de inferencia e chave de management.

## Escopo
Inclui:
- local correto de armazenamento de secrets
- separacao por workspace e por servico
- rotacao e auditoria de acesso
- segredos de OpenRouter, Slack e challenge HITL

Exclui:
- exposicao de segredo em docs, logs ou repositorio
- uso de credencial compartilhada sem dono

## Regras Normativas
- [RFC-015] MUST armazenar secrets em `.env` local ou secret manager do host.
- [RFC-015] MUST manter escopo minimo de secret por workspace/servico.
- [RFC-050] MUST registrar acesso administrativo a segredo.
- [RFC-015] MUST proibir commit de `~/.nanobot/`, chaves e tokens.
- [RFC-015] MUST armazenar challenge HITL apenas em forma hasheada com TTL.
- [RFC-015] MUST isolar `OPENROUTER_MANAGEMENT_KEY` do runtime comum.
- [RFC-015] MUST validar requests Slack com `SLACK_SIGNING_SECRET` armazenado em secret manager/.env seguro.

## Onde os Secrets Vivem
- `.env` local ignorado por git (uso local).
- secret manager do host/VPS para runtime e automacoes.
- `~/.nanobot/config.json` pode referenciar chaves por nome/alias, mas valor sensivel SHOULD permanecer no secret manager/.env.
- nunca em markdown, issue tracker, logs publicos ou artifacts externos.

## Segredos OpenRouter
- `OPENROUTER_API_KEY`:
  - uso: inferencia programatica no runtime.
  - escopo: menor privilegio para chamadas de modelos.
- `OPENROUTER_MANAGEMENT_KEY`:
  - uso: endpoint de creditos/saldo para Budget Governor.
  - escopo: apenas servico de governanca financeira.
  - proibido em workers de agente comuns.
- recomendacao:
  - service account dedicada para coleta de creditos.

## Segredos de Exchange/Broker (Trading)
- `TRADING_VENUE_API_KEY_LIVE` e `TRADING_VENUE_API_SECRET_LIVE`:
  - uso: emissao/cancelamento de ordens somente no `execution_gateway`.
  - escopo: `read/trade`; permissao de saque MUST ser desativada.
  - isolamento: uma credencial por ambiente (`sandbox`, `paper`, `live`) e por conta/subconta.
- `TRADING_VENUE_API_KEY_READONLY`:
  - uso: market data/reconciliacao sem permissao de trade.
  - proibido para emissao de ordens.
- requisitos obrigatorios:
  - IP allowlist ativa para credenciais live quando suportado.
  - rotacao imediata apos incidente de seguranca ou suspeita de vazamento.
  - nunca compartilhar a mesma credencial entre runtime de execucao e jobs auxiliares.

## Segredos Slack
- `SLACK_BOT_TOKEN`:
  - uso: envio de alertas e interacao operacional.
  - escopo: canais autorizados para operacao/HITL fallback.
- `SLACK_SIGNING_SECRET`:
  - uso: validar assinatura HMAC de eventos/comandos.
  - escopo: apenas adapter HTTP de entrada de eventos/comandos.
- `SLACK_APP_TOKEN` (opcional, socket mode):
  - uso: conexao websocket quando arquitetura nao expor endpoint HTTP publico.
  - escopo: somente processo adapter de eventos.

## Segredo de Challenge HITL
- chave mestre:
  - `HITL_CHALLENGE_HMAC_KEY` no secret manager do host.
- store transiente (`hitl_challenges`):
  - `challenge_id`
  - `decision_id`
  - `command_id`
  - `operator_user_id`
  - `challenge_hash`
  - `expires_at`
  - `attempt_count`
  - `status`
- regras:
  - TTL padrao: 5 minutos.
  - maximo 3 tentativas por challenge.
  - invalidar em sucesso, expiracao, lock ou revogacao.
  - nunca logar valor bruto do challenge.

## Rotacao
- `OPENROUTER_API_KEY`: rotacao minima trimestral.
- `OPENROUTER_MANAGEMENT_KEY`: rotacao minima mensal ou apos incidente.
- `SLACK_BOT_TOKEN`: rotacao minima trimestral ou apos suspeita de exposicao.
- `SLACK_SIGNING_SECRET`: rotacao minima trimestral ou apos incidente de webhook.
- `HITL_CHALLENGE_HMAC_KEY`: rotacao minima mensal.
- `TRADING_VENUE_API_KEY_LIVE`: rotacao minima mensal ou apos qualquer anomalia de ordem.
- `TRADING_VENUE_API_KEY_READONLY`: rotacao minima trimestral.
- pos-rotacao MUST validar pipelines e health checks.

## Auditoria de Acesso
- logar quem acessou, quando, motivo e sistema alvo.
- revisar mensalmente acessos ativos.
- revogar acesso ocioso > 30 dias.

## Proibicoes
- commit de `.env`, `.pem`, `.key`, `~/.nanobot/`.
- envio de segredo em chat, ticket ou artifact nao criptografado.
- reuso da management key para inferencia de rotina.

## Links Relacionados
- [Security Policy](./SEC-POLICY.md)
- [Incident Response](./SEC-INCIDENT-RESPONSE.md)
- [Financial Governance](../CORE/FINANCIAL-GOVERNANCE.md)
- [Decision Protocol](../PM/DECISION-PROTOCOL.md)
