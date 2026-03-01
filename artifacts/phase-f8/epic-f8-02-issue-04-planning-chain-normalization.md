# EPIC-F8-02 ISSUE-F8-02-04 normalizacao da cadeia estrutural de planejamento

- data/hora: 2026-03-01 17:10:00 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F8-02-04`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md`, `PM/SCRUM-GOV.md`, `PM/WORK-ORDER-SPEC.md`

## Red
- cenario A: manter coexistencia de `epicos/sprints/tasks` com `Issues/Microtasks` sem precedencia formal.
- resultado esperado: `FAIL` por conflito estrutural aberto.
- cenario B: manter alias `micro-issue` sem definicao canonica de equivalencia com microtask.
- resultado esperado: `FAIL` por ambiguidade de termos.

## Green
- acao:
  - alinhar cadeia canonica em `SCRUM-GOV` com `PRD` e `ROADMAP`;
  - reforcar `Sprint` como janela de capacidade e nao camada de autoridade;
  - publicar glossario anti-ambiguidade em `WORK-ORDER-SPEC`.
- comandos:
  1. `bash scripts/ci/check_architecture_consistency_backlog.sh`
  2. `make ci-quality`

## Refactor
- reduzir entropia sem criar novo epic/fase para auditoria.
- manter rastreabilidade em F8 com issue-level e micro-issues vinculadas.

## Evidencia objetiva
- conflitos e drifts cobertos:
  - `C-02` (cadeia estrutural divergente);
  - `D-MAIN-02` (cadeia tripla de planejamento);
  - `FM-03` e `FM-09`.
- artefatos de suporte:
  - `artifacts/architecture/2026-03-01-architectural-consistency-audit.md`
  - `artifacts/architecture/2026-03-01-architectural-consistency-audit-backlog.md`
  - `PM/audit/ARCH-CONSISTENCY-BACKLOG-2026-03-01.json`

## Alteracoes da issue
- `PM/SCRUM-GOV.md`
- `PRD/ROADMAP.md`
- `PRD/PRD-MASTER.md`
- `PM/WORK-ORDER-SPEC.md`
- `PM/PHASES/feito/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPIC-F8-02-REVISAO-PERIODICA-DE-CONTRATOS-E-DRIFT.md`
- `PM/audit/ARCH-CONSISTENCY-BACKLOG-2026-03-01.json`

