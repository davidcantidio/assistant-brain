---
doc_id: "RAG-EVALS-TESTS.md"
version: "1.0"
status: "active"
owner: "RAG Librarian"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-025", "RFC-050"]
---

# RAG Evals Tests

## Objetivo
Definir suite de testes de RAG por empresa com formato repetivel e relatorio auditavel.

## Escopo
Inclui:
- casos de teste por empresa
- formato de execucao e coleta de resultado
- criterios de aprovacao/reprovacao

Exclui:
- avaliacao sem gabarito
- liberacao de uso critico sem score minimo

## Regras Normativas
- [RFC-025] MUST manter suite por empresa com cobertura de casos reais e adversariais.
- [RFC-025] MUST testar citacao, precisao, vazamento e injecao.
- [RFC-050] MUST publicar relatorio com score e recomendacao de acao.
- [RFC-025] MUST separar execucao entre holdout fixo e suite rolling temporal.

## Formato de Caso de Teste
```yaml
test_id: "RAG-TEST-001"
empresa: "main"
question: "..."
expected_claims:
  - "..."
required_sources:
  - "doc_id:chunk_id"
risk_level: "baixo|medio|alto"
```

## Execucao
- rodar suite completa por release de indice/modelo.
- registrar tempo, fonte retornada e aderencia ao gabarito.
- marcar falhas criticas automaticamente.
- rodar `holdout_fixed` em toda release.
- rodar `rolling_weekly` diariamente com janela dos ultimos 7 dias.
- preservar historico por empresa para detectar drift temporal.

## Relatorio
- score por categoria (citacao, precisao, leakage, injection).
- comparacao com baseline anterior.
- recomendacao: aprovar, condicional, bloquear.

## Links Relacionados
- [RAG Evals](../RAG/RAG-EVALS.md)
- [RAG Ingestion](../RAG/RAG-INGESTION.md)
- [SEC Prompt Injection](../SEC/SEC-PROMPT-INJECTION.md)
