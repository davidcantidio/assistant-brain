---
doc_id: "SEC-SECRETS.md"
version: "1.0"
status: "active"
owner: "Security"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-015", "RFC-050"]
---

# SEC Secrets

## Objetivo
Definir armazenamento, escopo, rotacao e auditoria de segredos operacionais.

## Escopo
Inclui:
- local correto de armazenamento de secrets
- separacao por workspace/empresa
- processo de rotacao e auditoria de acesso

Exclui:
- exposicao de segredo em docs, logs ou repositorio
- uso de credencial compartilhada sem dono

## Regras Normativas
- [RFC-015] MUST armazenar secrets em `.env` local ou secret manager do host.
- [RFC-015] MUST manter escopo minimo de secret por workspace e por servico.
- [RFC-050] MUST registrar acesso administrativo a segredo.
- [RFC-015] MUST proibir commit de `~/.openclaw/`, chaves e tokens.

## Onde os Secrets Vivem
- `.env` local ignorado por git.
- secret manager do host/VPS para runtime e automacoes.
- nunca em markdown, artifacts publicos ou issue tracker.

## Escopo por Workspace
- `workspaces/main`: apenas credenciais operacionais globais.
- `workspaces/ops`: credenciais de infraestrutura.
- `workspaces/writer`: credenciais de conteudo, sem acesso infra.

## Rotacao
- periodicidade minima trimestral para chaves criticas.
- rotacao imediata apos incidente ou suspeita.
- pos-rotacao MUST validar funcionamento de pipelines.

## Auditoria de Acesso
- logar quem acessou, quando, motivo e sistema alvo.
- revisar mensalmente acessos ativos.
- revogar acesso ocioso acima de 30 dias.

## Proibicoes
- commit de `~/.openclaw/`.
- commit de `.env`, `.pem`, `.key` e derivados.
- envio de segredo em chat, log, ticket ou artifact.
- versionar `sessions/*.json` e `sessions/*.jsonl` com payload bruto de conversa.

## Links Relacionados
- [Security Policy](./SEC-POLICY.md)
- [Incident Response](./SEC-INCIDENT-RESPONSE.md)
- [Incident Log Policy](../INCIDENTS/INCIDENT-LOG-POLICY.md)
