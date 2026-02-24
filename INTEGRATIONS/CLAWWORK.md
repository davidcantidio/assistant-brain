---
doc_id: "INTEGRATIONS-CLAWWORK.md"
version: "1.0"
status: "active"
owner: "Architecture"
last_updated: "2026-02-24"
rfc_refs: ["RFC-015", "RFC-030", "RFC-050", "RFC-060"]
---

# Integration - ClawWork

## Objetivo
Usar ClawWork como harness economico de avaliacao sem permitir bypass das politicas de gateway, allowlist e retencao.

## Modo Permitido
- modo `lab_isolated` e default.
- modo `governed` MUST rotear toda chamada LLM via OpenClaw Gateway.
- chamada direta a provider externo no modo `governed` MUST ser bloqueada.

## Fora de Escopo e Bloqueios
- resultados de ClawWork nao podem executar ordem financeira ou alterar policy sem decision.
- credenciais de provider e sandbox nao podem ser compartilhadas entre `lab_isolated` e runtime de producao.
- execucao com E2B em modo `governed` exige allowlist explicita e politica de dados para ambiente externo.

## Threat Model (resumo)
- risco de bypass de gateway ao usar chamadas diretas OpenAI/OpenRouter.
- risco de exfiltracao de dado sensivel para sandbox externo (E2B).
- risco de telemetria economica enviesada por acoplamento a um unico provider.

## Contratos/Schemas
- ingestao economica MUST seguir [economic_run](../ARC/schemas/economic_run.schema.json).
- `economic_run.provider_path` e obrigatorio para rastrear cadeia de provider/adaptador efetivo.
- `total_cost_usd` deve ser computado de forma agnostica de provider; OpenRouter e fonte opcional quando habilitado por decision.

## Checklist de Testes/Gates
- `make eval-integrations`.
- teste negativo: em `governed`, chamada direta externa sem gateway deve falhar.
- teste de policy de dados: payload sensivel nao permitido para E2B deve ser bloqueado.
- teste de metrica: ingestao de custo com `provider_path` preenchido em todos os runs.

## Rollback / Fail-Closed
- qualquer violacao em modo `governed` MUST derrubar para `lab_isolated` e abrir `SECURITY_VIOLATION_REVIEW`.
- rollback nao remove artifacts de auditoria; apenas bloqueia uso operacional governado ate nova decision.
