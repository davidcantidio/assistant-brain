# EPIC-F8-03 ISSUE-F8-03-05 branch governance e ownership de PR com enforcement

- data/hora: 2026-03-01 17:10:00 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F8-03-05`
- fonte de verdade: `.github/CODEOWNERS`, `DEV/DEV-CI-RULES.md`, `scripts/ci/check_pr_governance.sh`

## Red
- cenario A: remover `CODEOWNERS` e manter PR governance apenas declarativa.
- resultado esperado: `FAIL`.
- cenario B: manter policy sem termos minimos de branch protection.
- resultado esperado: `FAIL`.

## Green
- acao:
  - manter `CODEOWNERS` versionado no repositorio;
  - manter policy de branch e merge no `DEV/DEV-CI-RULES.md`;
  - garantir enforcement via `check_pr_governance.sh` no `ci-quality`.
- comandos:
  1. `bash scripts/ci/check_pr_governance.sh`
  2. `make ci-quality`

## Refactor
- manter regra minima de ownership e branch policy como gate de qualidade.
- reduzir risco de regressao silenciosa de governanca documental.

## Evidencia objetiva
- conflitos e drifts cobertos:
  - `C-05`;
  - `D-WT-02`;
  - `FM-10`.
- artefatos de suporte:
  - `PM/audit/ARCH-CONSISTENCY-BACKLOG-2026-03-01.json`
  - `artifacts/architecture/2026-03-01-architectural-consistency-audit-backlog.md`

## Alteracoes da issue
- `.github/CODEOWNERS`
- `DEV/DEV-CI-RULES.md`
- `scripts/ci/check_pr_governance.sh`
- `scripts/ci/check_quality.sh`
- `PM/PHASES/feito/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPIC-F8-03-GOVERNANCA-DE-EVOLUCAO-E-RELEASE.md`
- `PM/audit/ARCH-CONSISTENCY-BACKLOG-2026-03-01.json`

