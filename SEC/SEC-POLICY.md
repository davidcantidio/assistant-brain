---
doc_id: "SEC-POLICY.md"
version: "1.0"
status: "active"
owner: "Security"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-015", "RFC-040", "RFC-050"]
---

# Security Policy

## Objetivo
Estabelecer politica de seguranca operacional enforceable para agentes, ferramentas e fluxos do Mission Control.

## Escopo
Inclui:
- menor privilegio por agente e por tarefa
- allowlists de dominio/ferramenta/acao
- tratamento de violacao com bloqueio e decision

Exclui:
- excecoes tacitas sem registro formal
- execucao fora de sandbox para tarefas nao aprovadas

## Regras Normativas
- [RFC-015] MUST aplicar menor privilegio por agente e por Work Order.
- [RFC-015] MUST operar com allowlist explicita de dominios, ferramentas e acoes.
- [RFC-015] MUST bloquear operacao suspeita e abrir `SECURITY_VIOLATION_REVIEW`.
- [RFC-050] MUST redigir logs para remover secrets e PII.
- [RFC-040] MUST exigir decision para override de politica.
- [RFC-015] MUST versionar allowlists executaveis em artefatos dedicados.
- [RFC-015] MUST controlar aprovadores HITL por allowlist de operadores autorizados.
- [RFC-015] MUST exigir segundo fator (challenge) para comandos criticos de aprovacao/kill.

## Menor Privilegio
- cada agente recebe apenas escopos necessarios para sua funcao.
- acesso de escrita em repositorio MUST ser restrito por papel e risco.
- acesso externo MUST ser default-deny e explicitamente liberado.

## Allowlists
- dominios permitidos por categoria (docs, APIs, infra).
- ferramentas locais permitidas por role.
- acoes bloqueadas por default: deploy, execucao externa critica, acesso sensivel.
- artefatos canonicos:
  - `./allowlists/DOMAINS.yaml`
  - `./allowlists/TOOLS.yaml`
  - `./allowlists/ACTIONS.yaml`
  - `./allowlists/OPERATORS.yaml`
- mudanca em allowlist MUST passar por review e trilha de auditoria.

## HITL Operators (Telegram)
- aprovacao/rejeicao/kill MUST validar:
  - `from.id` autorizado;
  - `chat.id` autorizado;
  - vinculacao ao mesmo operador na allowlist.
- comandos criticos MUST incluir desafio adicional aprovado.
- update invalido MUST ser bloqueado e auditado.

## Violacao de Politica
- gatilho: comando fora de escopo, acesso indevido, tentativa de extracao de segredo.
- acao imediata:
  - bloquear execucao.
  - registrar evidencia.
  - abrir decision `SECURITY_VIOLATION_REVIEW`.

## Logging Seguro
- mascarar token, chave, senha, email e dados pessoais.
- armazenar hash/referencia quando necessario para auditoria.
- impedir escrita de segredos em artifacts publicos.

## Links Relacionados
- [Secrets](./SEC-SECRETS.md)
- [Sandboxing](./SEC-SANDBOXING.md)
- [Prompt Injection](./SEC-PROMPT-INJECTION.md)
- [Incident Response](./SEC-INCIDENT-RESPONSE.md)
- [Domains Allowlist](./allowlists/DOMAINS.yaml)
- [Tools Allowlist](./allowlists/TOOLS.yaml)
- [Actions Allowlist](./allowlists/ACTIONS.yaml)
- [Operators Allowlist](./allowlists/OPERATORS.yaml)
