---
doc_id: "SEC-SANDBOXING.md"
version: "1.1"
status: "active"
owner: "Security"
last_updated: "2026-02-20"
rfc_refs: ["RFC-001", "RFC-015", "RFC-035", "RFC-050"]
---

# SEC Sandboxing

## Objetivo
Definir limites e regras de execucao em sandbox para reduzir superficie de risco e preservar reproducibilidade.

## Escopo
Inclui:
- regras de rede e filesystem
- limites de recursos e timeout
- rollback/idempotencia e tratamento de falha

Exclui:
- execucao irrestrita em host
- bypass de controle sem decision aprovada

## Regras Normativas
- [RFC-015] MUST operar sem rede por padrao, salvo allowlist explicita.
- [RFC-015] MUST bloquear diretorios sensiveis fora do escopo da tarefa.
- [RFC-050] MUST registrar tempo, memoria e comandos executados.
- [RFC-035] MUST acionar circuit breaker em falha recorrente de sandbox.

## Politica de Execucao
- rede: deny-by-default.
- excecao de rede para Trading:
  - acesso externo a exchange/broker MUST ocorrer somente via `execution_gateway`.
  - workers/agentes de analise MUST NOT chamar endpoints de ordem diretamente.
  - dominios de venue MUST existir em `SEC/allowlists/DOMAINS.yaml`.
- filesystem: acesso apenas ao workspace autorizado.
- processos: bloquear elevacao de privilegio e comandos destrutivos nao aprovados.

## Limites
- timeout por tarefa (ex.: 120s default, ajustavel por classe).
- memoria maxima por job com hard cap.
- maximo de retries por etapa antes de escalation.

## Idempotencia e Rollback
- tarefas com efeito colateral MUST ter plano de rollback.
- scripts SHOULD ser idempotentes por design.
- falha parcial MUST gerar artifact de estado para reconciliacao.

## Falha de Sandbox
- abrir incident/task automatica.
- pausar classe de tarefa afetada.
- escalar para revisao cloud/humana se impacto alto.

## Links Relacionados
- [Security Policy](./SEC-POLICY.md)
- [ARC Degraded Mode](../ARC/ARC-DEGRADED-MODE.md)
- [Incident Response](./SEC-INCIDENT-RESPONSE.md)
