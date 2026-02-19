---
doc_id: "DEV-DETERMINISTIC-PIPELINE.md"
version: "1.0"
status: "active"
owner: "Marvin"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-050"]
---

# Dev Deterministic Pipeline

## Objetivo
Definir pipeline script-first para transformar tarefas recorrentes em execucao previsivel e auditavel.

## Escopo
Inclui:
- fluxo de automacao deterministica
- idempotencia, validacao e versionamento
- rollback operacional

Exclui:
- automacao sem teste
- acao irreversivel sem plano de retorno

## Regras Normativas
- [RFC-001] MUST priorizar script/ferramenta sobre prompt em tarefa repetitiva.
- [RFC-050] MUST validar deterministamente antes de promover automacao.
- [RFC-050] MUST versionar e registrar artifacts de execucao.

## Pipeline Script-First
1. LLM local propoe script/funcao.
2. gerar testes e validacoes.
3. executar em sandbox.
4. registrar outputs e metricas.
5. promover para ferramenta oficial quando estavel.

## Idempotencia
- script MUST poder rodar mais de uma vez sem efeito colateral inesperado.
- usar chaves de idempotencia para operacoes com estado.
- registrar checksum de entrada/saida quando aplicavel.

## Validacoes Deterministicas
- lint + typecheck + testes.
- schema validation para json/yaml/sql.
- policy checks de seguranca.

## Versionamento e Rollback
- versionar script e configuracao juntos.
- cada versao MUST definir estrategia de rollback.
- rollback testado SHOULD existir para classes criticas.

## Links Relacionados
- [Dev Principles](./DEV-PRINCIPLES.md)
- [CI Rules](./DEV-CI-RULES.md)
- [ARC Core](../ARC/ARC-CORE.md)
