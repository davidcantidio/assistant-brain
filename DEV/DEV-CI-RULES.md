---
doc_id: "DEV-CI-RULES.md"
version: "1.4"
status: "active"
owner: "Marvin"
last_updated: "2026-02-24"
rfc_refs: ["RFC-001", "RFC-015", "RFC-050"]
---

# Dev CI Rules

## Objetivo
Definir gates de CI para garantir qualidade minima, seguranca e compliance de roteamento antes de merge/deploy.

## Escopo
Inclui:
- checks obrigatorios de qualidade
- checks de seguranca
- checks de claims centrais
- condicoes de bloqueio de merge

Exclui:
- bypass manual sem trilha de aprovacao
- merge sem execucao de testes obrigatorios

## Regras Normativas
- [RFC-050] MUST executar lint, typecheck e testes antes de merge.
- [RFC-015] MUST executar verificacoes de seguranca obrigatorias.
- [RFC-050] MUST executar gates obrigatorios em GitHub Actions.
- [RFC-001] SHOULD manter pipeline reproduzivel e versionado.

## Gates Obrigatorios
- lint/style.
- typecheck.
- testes unitarios/minimos.
- validacao de schema de artifacts.
- execucao de eval gates centrais (`claim gates`).
- em mudancas sob `VERTICALS/TRADING/*`: `make eval-trading` MUST executar e passar.

## Gates de Seguranca e Policy
- secret scan em alteracoes.
- dependencia critica com CVE aberto bloqueia merge.
- validacao de allowlists versionadas:
  - `SEC/allowlists/*.yaml` incluindo `PROVIDERS.yaml`.
- bloqueio de merge para:
  - rota sensitive sem policy adequada,
  - uso programatico fora do gateway OpenClaw.

## Gates de Roteamento
- valida schema de `models_catalog`.
- valida contrato de `router_presets`.
- valida presenca de campos `requested/effective` em fixtures de `llm_runs`.
- valida fallback policy (`no_fallback` em rotas sensiveis quando exigido).

## Plataforma de CI
- plataforma oficial: GitHub Actions.
- workflows minimos obrigatorios:
  - `ci-quality.yml` (lint/typecheck/tests)
  - `ci-security.yml` (secret scan, allowlists, policy)
  - `ci-routing.yml` (catalog/presets/router contracts)
  - `ci-evals.yml` (claim gates e suites de avaliacao)
  - `ci-trading.yml` (harness `eval-trading`, contratos `execution_gateway`/`pre_trade_validator`, cenarios hard-risk)

## Criterios de Merge
- todos os gates verdes.
- sem violacao de policy de seguranca/privacidade.
- sem regressao em claims centrais.
- excecao apenas por decision registrada.

## Links Relacionados
- [Security Policy](../SEC/SEC-POLICY.md)
- [System Health Thresholds](../EVALS/SYSTEM-HEALTH-THRESHOLDS.md)
- [ARC Model Routing](../ARC/ARC-MODEL-ROUTING.md)
