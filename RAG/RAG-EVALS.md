---
doc_id: "RAG-EVALS.md"
version: "1.0"
status: "active"
owner: "RAG Librarian"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-025", "RFC-050"]
---

# RAG Evals

## Objetivo
Definir avaliacao continua de qualidade e seguranca do RAG por empresa para liberar uso critico com confianca.

## Escopo
Inclui:
- suite de avaliacoes por empresa
- testes de citacao, precisao, vazamento e injecao
- thresholds e acoes de bloqueio

Exclui:
- avaliacao informal sem baseline
- promocao para uso critico sem score minimo

## Regras Normativas
- [RFC-025] MUST manter eval suite por empresa com 20-50 perguntas representativas.
- [RFC-025] MUST testar citacao, precisao factual, vazamento e prompt injection.
- [RFC-050] MUST bloquear uso critico abaixo do threshold.
- [RFC-050] MUST abrir task de correcao quando regressao for detectada.
- [RFC-025] MUST manter conjunto holdout fixo e janela rolling semanal para detectar drift.
- [RFC-025] MUST responder com abstencao quando evidencia for insuficiente.

## Suite Minima por Empresa
- 20-50 perguntas com gabarito e fontes esperadas.
- cobertura de casos faceis, medios e adversariais.
- amostras de dados sensiveis para teste de isolamento.
- split obrigatorio:
  - `holdout_fixed`: nao usado em tuning.
  - `rolling_weekly`: amostra dos ultimos 7 dias.

## Metricas
- citation coverage (claims com fonte valida).
- factual accuracy.
- leakage rate inter-empresa.
- injection resilience.
- tempo medio de resposta por classe.
- abstention precision (abstencao correta vs incorreta).

## Mitigacoes Operacionais de RAG
- claim-checker deterministico:
  - cada claim critica precisa de pelo menos 1 citacao valida.
- citation coverage gate:
  - resposta critica sem cobertura minima MUST ser bloqueada.
- policy drift gate:
  - doc desatualizado MUST impedir resposta normativa.
- abstencao controlada:
  - se evidencias forem insuficientes, responder "nao conclusivo" + abrir task de coleta.

## Thresholds e Acoes
- citation coverage < 95%: bloquear respostas criticas.
- leakage > 0: bloquear indice e abrir incident.
- accuracy < 90%: rebaixar para uso nao critico.
- regressao > 5 pontos vs baseline: abrir decision de rollback.

## Nota sobre Convex
- Convex resolve sincronizacao/estado em tempo real.
- Convex nao substitui avaliacao de qualidade (precisao, leakage, citacao, drift) do RAG.

## Links Relacionados
- [RAG Tests](../EVALS/RAG-EVALS-TESTS.md)
- [RAG Ingestion](./RAG-INGESTION.md)
- [SEC Prompt Injection](../SEC/SEC-PROMPT-INJECTION.md)
