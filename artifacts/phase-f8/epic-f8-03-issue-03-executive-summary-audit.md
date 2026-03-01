# EPIC-F8-03 ISSUE-F8-03-03 sumario executivo semanal e auditoria

- data/hora: 2026-03-01 10:13:58 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F8-03-03`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md`, `PM/PHASES/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPICS.md`, `artifacts/phase-f8/weekly-governance/2026-W09.md`

## Red
- cenario A: manter a rodada semanal apenas no relatorio canonicamente tecnico, sem sumario executivo derivado.
- resultado esperado: `hold`.
- cenario B: fechar o epic sem validar coerencia entre `weekly-governance` e `validation-summary`.
- resultado esperado: `hold`.

## Green
- acao:
  - gerar `artifacts/phase-f8/validation-summary-2026-W09.md` a partir do relatorio semanal autoritativo;
  - validar coerencia bidirecional entre summary, relatorio semanal e status dos epics da `F8`;
  - fechar o `EPIC-F8-03` em `feito` sem promover automaticamente a fase.
- comandos:
  1. `make phase-f8-contract-review`
  2. `make phase-f8-weekly-governance`
  3. `make eval-gates`
  4. `make ci-quality`
  5. `make ci-security`
- resultado:
  - `phase-f8-contract-review: PASS`
  - `phase-f8-weekly-governance: decision=hold`
  - `eval-gates: PASS`
  - `quality-check: PASS`
  - `security-check: PASS`

## Refactor
- o `validation-summary` passa a existir como companion obrigatorio do artifact semanal da `F8`.
- o fechamento documental do epic preserva a decisao operacional atual em `hold`.

## Evidencia objetiva
- `artifacts/phase-f8/validation-summary-2026-W09.md` e derivado do relatorio canonico em `artifacts/phase-f8/weekly-governance/2026-W09.md`.
- o summary semanal preserva coerencia com:
  - `decision=hold`
  - `release_review_status=PASS`
  - `phase_transition_status=blocked`
  - `critical_drifts_open=1`
  - status dos epics `EPIC-F8-01..04`.
- logs finais da rodada valida:
  - `artifacts/phase-f8/weekly-governance/logs/2026-W09/20260301T101358-eval-gates.log`
  - `artifacts/phase-f8/weekly-governance/logs/2026-W09/20260301T101358-ci-quality.log`
  - `artifacts/phase-f8/weekly-governance/logs/2026-W09/20260301T101358-ci-security.log`

## Alteracoes da issue
- `scripts/ci/phase_f8_release_governance.py`
- `scripts/ci/run_phase_f8_weekly_governance.sh`
- `scripts/ci/check_phase_f8_weekly_governance.sh`
- `artifacts/phase-f8/weekly-governance/2026-W09.md`
- `artifacts/phase-f8/validation-summary-2026-W09.md`
- `artifacts/phase-f8/epic-f8-03-issue-03-executive-summary-audit.md`
- `artifacts/phase-f8/epic-f8-03-governanca-evolucao-release.md`
- `PM/PHASES/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPICS.md`
- `PM/PHASES/feito/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPIC-F8-03-GOVERNANCA-DE-EVOLUCAO-E-RELEASE.md`
- `PRD/CHANGELOG.md`
