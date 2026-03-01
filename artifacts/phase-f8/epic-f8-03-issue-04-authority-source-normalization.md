# EPIC-F8-03 ISSUE-F8-03-04 normalizacao da fonte de autoridade arquitetural

- data/hora: 2026-03-01 17:10:00 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F8-03-04`
- fonte de verdade: `META/DOCUMENT-HIERARCHY.md`, `README.md`, `workspaces/main/AGENTS.md`, `PRD/PRD-MASTER.md`

## Red
- cenario A: manter precedencia de autoridade paralela entre Felix e PRD.
- resultado esperado: `FAIL` por conflito critico de autoridade.
- cenario B: manter onboarding (`README`/`AGENTS`) com mensagem contraditoria ao PRD.
- resultado esperado: `FAIL` por governanca ambigua.

## Green
- acao:
  - normalizar fonte normativa em `PRD + SEC + ARC`;
  - manter Felix como referencia conceitual com importacao por changelog/traceability;
  - consolidar mensagem de autoridade em documentos de onboarding.
- comandos:
  1. `bash scripts/ci/check_architecture_consistency_backlog.sh`
  2. `make ci-quality`

## Refactor
- preservar contribuicao conceitual de Felix sem precedencia normativa direta.
- reduzir risco de arquitetura paralela ativa por definicao documental.

## Evidencia objetiva
- conflitos e drifts cobertos:
  - `C-01` (autoridade decisoria critica);
  - `D-MAIN-01`;
  - `FM-01` e `FM-04`.
- artefatos de suporte:
  - `artifacts/architecture/2026-03-01-architectural-consistency-audit.md`
  - `artifacts/architecture/2026-03-01-architectural-consistency-audit-backlog.md`
  - `PM/audit/ARCH-CONSISTENCY-BACKLOG-2026-03-01.json`

## Alteracoes da issue
- `META/DOCUMENT-HIERARCHY.md`
- `README.md`
- `workspaces/main/AGENTS.md`
- `PRD/PRD-MASTER.md`
- `PRD/CHANGELOG.md`
- `PM/PHASES/feito/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPIC-F8-03-GOVERNANCA-DE-EVOLUCAO-E-RELEASE.md`
- `PM/audit/ARCH-CONSISTENCY-BACKLOG-2026-03-01.json`

