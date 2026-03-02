---
doc_id: "REPO-HYGIENE.md"
version: "1.0"
status: "active"
owner: "PM+Engineering"
last_updated: "2026-03-02"
rfc_refs: ["RFC-001", "RFC-040", "RFC-050"]
---

# Repo Hygiene

## Objetivo
Definir regras permanentes para reduzir ruido estrutural e manter o repositorio previsivel, auditavel e deterministico nos gates de qualidade.

## Escopo
Inclui:
- politica de artifacts (estavel vs temporario)
- regras de versionamento para arquivos gerados
- checklist minima de PR anti-caos
- enforcement em CI para ruido tecnico

Exclui:
- convergencia funcional de PRD para runtime
- mudancas de estado operacional em `~/.openclaw*`

## Regras Normativas
- [RFC-001] MUST manter separacao explicita entre fonte canonica e saida gerada.
- [RFC-040] MUST manter gates de qualidade deterministas, sem acoplamento rigido a data corrente.
- [RFC-050] MUST manter trilha auditavel de limpeza estrutural e decisoes de organizacao.

## Politica de Artifacts
### 1) Artifact estavel (versionado)
- markdown consolidado de epico/fase em `artifacts/phase-*/*.md`.
- evidencias finais que explicam resultado, impacto e criterio de aceite.

### 2) Artifact temporario/gerado (nao versionado)
- snapshots JSON de runtime (`runtime-inventory`, `runtime-merge-plan`, `runtime-convergence-report`).
- backups locais e outputs de canario/rollout.
- local padrao: `artifacts/generated/`.

### 3) Regra de conflito
- quando um artifact tiver duvida de classe, prevalece a politica conservadora:
  - versionar somente resumo estavel em Markdown;
  - manter dados brutos em `artifacts/generated/`.

## Regras de Ruido Tecnico (nunca versionar)
- caches/compilados: `__pycache__/`, `*.pyc`.
- lixo de editor: `*.swp`, `*.swo`, `*.tmp`.
- lixo de sistema: `.DS_Store`.
- estado local/sensivel: `.openclaw/`, tokens, secrets e logs locais.

## Determinismo de CI
- checks semanais MUST usar fallback para o ultimo baseline disponivel quando a semana corrente ainda nao tiver artifact.
- `make ci-quality` MUST continuar executavel sem criacao manual de arquivo semanal no dia.

## Checklist Anti-Caos de PR
- `make ci-quality` e `make ci-security` verdes.
- nenhum arquivo gerado ou cache no indice git.
- docs auxiliares coerentes com a hierarquia de `META/DOCUMENT-HIERARCHY.md`.
- mudanca normativa registrada em `PRD/CHANGELOG.md`.

## Links Relacionados
- [Document Hierarchy](./DOCUMENT-HIERARCHY.md)
- [Changelog](../PRD/CHANGELOG.md)
- [Quality Check](../scripts/ci/check_quality.sh)
