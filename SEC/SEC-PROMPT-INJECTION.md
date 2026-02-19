---
doc_id: "SEC-PROMPT-INJECTION.md"
version: "1.0"
status: "active"
owner: "Security"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-015", "RFC-025"]
---

# SEC Prompt Injection

## Objetivo
Mitigar risco de prompt injection e data poisoning em entradas externas e fluxo de RAG.

## Escopo
Inclui:
- separacao formal entre instrucao e dado
- validacao de formato antes de inferencia
- proibicao de execucao direta baseada em conteudo externo

Exclui:
- confianca implicita em texto de fonte nao validada
- bypass de filtro por urgencia operacional

## Regras Normativas
- [RFC-015] MUST tratar todo conteudo externo como DATA, nunca como INSTRUCTION.
- [RFC-015] MUST usar wrappers de separacao de contexto.
- [RFC-025] MUST validar formato/metadata antes de enviar ao LLM.
- [RFC-015] MUST proibir execucao direta de comandos originados em dado externo.

## Wrapper Padrao
- bloco `SYSTEM/INSTRUCTION`: politica e tarefa autorizada.
- bloco `DATA`: conteudo recuperado, sem permissao de comando.
- bloco `OUTPUT_SCHEMA`: formato esperado e validacoes.

## Controles Minimos
- sanitizacao de markdown/html/script.
- detecao de padroes de injecao em prompt e documentos.
- bloqueio de resposta sem citacao em tarefa critica.
- denylist de instrucoes maliciosas conhecidas.

## Fluxo Seguro
1. receber conteudo externo.
2. classificar origem e sensibilidade.
3. aplicar sanitizacao e validacao de schema.
4. executar inferencia sob wrapper.
5. validar saida antes de qualquer acao.

## Links Relacionados
- [Security Policy](./SEC-POLICY.md)
- [RAG Ingestion](../RAG/RAG-INGESTION.md)
- [RAG Evals](../RAG/RAG-EVALS.md)
