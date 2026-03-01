# EPIC-F8-03 ISSUE-F8-03-06 harmonizacao do pipeline multi-modelo com contratos canonicos

- data/hora: 2026-03-01 17:10:00 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F8-03-06`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/CHANGELOG.md`, `ARC/ARC-MODEL-ROUTING.md`, `DEV/DEV-TECH-LEAD-SPEC.md`, `PM/DECISION-PROTOCOL.md`

## Red
- cenario A: manter pipeline `M30 -> M14-Code -> Codex 5` sem status normativo fechado.
- resultado esperado: `FAIL`.
- cenario B: manter papeis do pipeline sem harmonizacao transversal em `ARC/DEV/PM`.
- resultado esperado: `FAIL`.

## Green
- acao:
  - declarar status unico (`proposta` ou `norma`) para o pipeline;
  - alinhar contratos de roteamento, papeis e decisao no mesmo ciclo;
  - manter checker de coerencia arquitetural no `ci-quality`.
- comandos:
  1. `bash scripts/ci/check_architecture_consistency_backlog.sh`
  2. `make ci-quality`

## Refactor
- manter pipeline de codigo abaixo da `Issue`, no nivel de `Microtask` e `PR`.
- impedir nova camada de planejamento paralela.

## Evidencia objetiva
- conflitos e drifts cobertos:
  - `C-04`;
  - `D-WT-01` e `D-FELIX-01`;
  - `FM-02`, `FM-05`, `FM-07`.
- artefatos de suporte:
  - `artifacts/architecture/2026-03-01-multi-model-pipeline-impact.md`
  - `PM/audit/ARCH-CONSISTENCY-BACKLOG-2026-03-01.json`
  - `scripts/ci/check_architecture_consistency_backlog.sh`

## Alteracoes da issue
- `PRD/PRD-MASTER.md`
- `PRD/CHANGELOG.md`
- `ARC/ARC-MODEL-ROUTING.md`
- `DEV/DEV-TECH-LEAD-SPEC.md`
- `DEV/DEV-JUNIOR-SPEC.md`
- `PM/DECISION-PROTOCOL.md`
- `scripts/ci/check_architecture_consistency_backlog.sh`
- `PM/PHASES/feito/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPIC-F8-03-GOVERNANCA-DE-EVOLUCAO-E-RELEASE.md`

