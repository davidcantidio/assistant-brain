---
doc_id: "SEC-POLICY.md"
version: "1.6"
status: "active"
owner: "Security"
last_updated: "2026-02-23"
rfc_refs: ["RFC-001", "RFC-015", "RFC-040", "RFC-050"]
---

# Security Policy

## Objetivo
Estabelecer politica de seguranca enforceable para agentes, modelos, providers e fluxos do Mission Control.

## Escopo
Inclui:
- menor privilegio por agente e por tarefa
- allowlists de dominio/ferramenta/acao/provider
- politica de privacidade e retencao por sensibilidade
- regra ZDR para fluxos sensiveis

Exclui:
- excecoes tacitas sem registro formal
- execucao fora de sandbox para tarefas nao aprovadas

## Regras Normativas
- [RFC-015] MUST aplicar menor privilegio por agente e por Work Order.
- [RFC-015] MUST operar com allowlist explicita de dominios, ferramentas, acoes e providers.
- [RFC-015] MUST bloquear operacao suspeita e abrir `SECURITY_VIOLATION_REVIEW`.
- [RFC-050] MUST redigir logs para remover secrets e PII.
- [RFC-040] MUST exigir decision para override de politica.
- [RFC-015] MUST controlar aprovadores HITL por allowlist de operadores autorizados e contrato de canal.
- [RFC-015] MUST exigir segundo fator (challenge) para comandos criticos de aprovacao/kill.
- [RFC-015] MUST aplicar restricoes de provider e retencao para tarefa `sensitive`.
- [RFC-015] MUST validar assinatura e anti-replay para requests de Slack no canal HITL.
- [RFC-060] MUST permitir envio/cancelamento de ordem somente via `execution_gateway`.
- [RFC-015] MUST bloquear credencial de trading com permissao de saque.
- [RFC-015] MUST exigir IP allowlist nas credenciais de venue quando o provedor suportar.
- [RFC-015] MUST impedir que adapters/wrappers (incluindo ClawMode/ClawWork) bypassem gates de risco e controles de execucao.

## Menor Privilegio
- cada agente recebe apenas escopos necessarios para sua funcao.
- acesso de escrita em repositorio MUST ser restrito por papel e risco.
- acesso externo MUST ser default-deny e explicitamente liberado.

## Classificacao de Sensibilidade
- `public`: dados publicos e nao pessoais.
- `internal`: dados internos sem segredo critico.
- `sensitive`: dados sensiveis (PII, credenciais, risco juridico/comercial).

## Politica por Sensibilidade
- `public`:
  - allowlist de provider ampla conforme policy.
  - prompt bruto MAY ser armazenado se necessario.
- `internal`:
  - provider allowlist moderada.
  - prompt bruto SHOULD ser evitado; preferir hash + resumo.
- `sensitive`:
  - provider allowlist restrita.
  - ZDR REQUIRED quando disponivel por provider/rota.
  - `no_fallback` por default para evitar troca silenciosa de provider.
  - prompt bruto MUST ser bloqueado por default.

## Allowlists Canonicas
- dominios:
  - `./allowlists/DOMAINS.yaml`
- ferramentas:
  - `./allowlists/TOOLS.yaml`
- acoes:
  - `./allowlists/ACTIONS.yaml`
- operadores HITL:
  - `./allowlists/OPERATORS.yaml`
- providers por task/sensibilidade:
  - `./allowlists/PROVIDERS.yaml`

## OpenRouter e Providers
- chamadas programaticas de inferencia em cloud/provider externo MUST passar por OpenRouter.
- inferencia local em `MAC-LOCAL` MAY operar sem OpenRouter somente para modelos locais sem chamada a provider externo.
- chamada direta a API de provider externo fora do OpenRouter MUST ser bloqueada.
- OpenRouter SHOULD operar com logging de prompts/respostas desativado por default (opt-in explicito por policy).
- providers efetivos possuem politicas proprias de retencao/privacidade e MUST ser tratados como variancia de risco.
- provider efetivo MUST ser validado contra `PROVIDERS.yaml`.
- rota `sensitive` sem provider compativel com policy MUST falhar com bloqueio.

## Runtime e Adapters
- runtime oficial de execucao: Nanobot (`nanobot ...`).
- adapter oficial para integracao com ClawWork: `clawmode_integration`.
- wrappers/adapters MUST operar dentro do mesmo contrato de seguranca do runtime:
  - sem bypass de `execution_gateway`;
  - sem bypass de `pre_live_checklist`;
  - sem bypass de challenge HITL e gates `R2/R3`;
  - toda tentativa de bypass MUST abrir incidente `SECURITY_VIOLATION_REVIEW`.

## HITL Operators (Multi-canal)
- fonte de identidade: `./allowlists/OPERATORS.yaml`.
- Telegram (primario):
  - approve/reject/kill MUST validar `from.id` + `chat.id` autorizados e vinculados ao mesmo operador.
- Slack (fallback controlado):
  - approve/reject/kill MUST validar `user_id` autorizado para o operador.
  - `channel_id` MUST estar permitido em `slack_channel_ids` do operador ou em policy aprovada por decision.
  - request MUST validar assinatura HMAC (`SLACK_SIGNING_SECRET`) + janela anti-replay de 5 minutos.
- comandos criticos MUST incluir challenge valido, independente do canal.
- update invalido MUST ser bloqueado e auditado.
- fallback de canal MUST manter os mesmos gates de risco (`R2/R3` + side effects).
- fallback Slack para HITL critico em trading live MUST ficar bloqueado enquanto `slack_user_ids` e `slack_channel_ids` estiverem vazios para operador habilitado.

## Politica de Credenciais de Trading
- credenciais de exchange/broker MUST separar ambientes (`sandbox`, `paper`, `live`).
- credenciais `live` MUST seguir menor privilegio:
  - permitir somente `read/trade` (sem `withdraw`).
  - escopo por conta/subconta dedicado para estrategia.
  - IP allowlist obrigatoria quando suportado.
- qualquer tentativa de emissao de ordem fora do `execution_gateway` MUST ser bloqueada e auditada como violacao.

## Logging Seguro e Retencao
- mascarar token, chave, senha, email e dados pessoais.
- armazenar hash/referencia quando necessario para auditoria.
- por default:
  - nao armazenar prompt bruto,
  - armazenar `prompt_hash` + `prompt_summary` sanitizado.
- excecao para prompt bruto completo:
  - apenas por policy explicita,
  - com criptografia,
  - com retention curta e owner definido.

## Violacao de Politica
- gatilho: comando fora de escopo, provider nao permitido, tentativa de extracao de segredo, acesso indevido.
- acao imediata:
  - bloquear execucao,
  - registrar evidencia,
  - abrir decision `SECURITY_VIOLATION_REVIEW`.

## Links Relacionados
- [Secrets](./SEC-SECRETS.md)
- [Sandboxing](./SEC-SANDBOXING.md)
- [Prompt Injection](./SEC-PROMPT-INJECTION.md)
- [Incident Response](./SEC-INCIDENT-RESPONSE.md)
- [Providers Allowlist](./allowlists/PROVIDERS.yaml)
