# EPIC-F8-01 ISSUE-F8-01-04 trilha minima de microtask e check de coerencia arquitetural

- data/hora: 2026-03-01 17:10:00 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F8-01-04`
- fonte de verdade: `PRD/PRD-MASTER.md`, `ARC/schemas/architecture_consistency_backlog.schema.json`, `PM/audit/ARCH-CONSISTENCY-BACKLOG-2026-03-01.json`

## Red
- cenario A: manter contrato de microtask sem trilha minima em `runs`.
- resultado esperado: `FAIL` no checker de consistencia.
- cenario B: manter micro-issues sem campos obrigatorios de ownership e evidencia.
- resultado esperado: `FAIL` no checker de consistencia.

## Green
- acao:
  - criar o contrato `architecture_consistency_backlog.schema.json`;
  - publicar backlog maquina-consumivel com `micro_issues` auditaveis;
  - acoplar `check_architecture_consistency_backlog.sh` ao `ci-quality`.
- comandos:
  1. `bash scripts/ci/check_architecture_consistency_backlog.sh`
  2. `make architecture-consistency-backlog-check`
  3. `make ci-quality`

## Refactor
- manter o backlog de auditoria como trilho unico para conflito/drift/failure mode.
- manter `runs` como trilha minima declarada para convergencia com contrato de microtask.

## Evidencia objetiva
- artefatos canonicamente gerados:
  - `ARC/schemas/architecture_consistency_backlog.schema.json`
  - `PM/audit/ARCH-CONSISTENCY-BACKLOG-2026-03-01.json`
  - `artifacts/architecture/2026-03-01-architectural-consistency-audit-backlog.md`
- checks cobertos:
  - cobertura dos 12 failure modes obrigatorios;
  - vinculo de conflitos `Critica/Alta` com issue e micro-issue;
  - validacao de links/evidencias referenciadas.

## Alteracoes da issue
- `ARC/schemas/architecture_consistency_backlog.schema.json`
- `PM/audit/ARCH-CONSISTENCY-BACKLOG-2026-03-01.json`
- `artifacts/architecture/2026-03-01-architectural-consistency-audit-backlog.md`
- `scripts/ci/check_architecture_consistency_backlog.sh`
- `scripts/ci/check_quality.sh`
- `Makefile`
- `PM/PHASES/feito/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPIC-F8-01-CADENCIA-SEMANAL-DE-GATES.md`

