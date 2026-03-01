# EPIC-F8-02 ISSUE-F8-02-01 revisao contratual semanal canonica e conformidade

- data/hora: 2026-03-01 08:49:53 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F8-02-01`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/PHASE-USABILITY-GUIDE.md`, `PM/PHASES/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPIC-F8-02-REVISAO-PERIODICA-DE-CONTRATOS-E-DRIFT.md`, `artifacts/phase-f8/contract-review/2026-W09.md`

## Red
- cenario A: executar o fechamento semanal da `F8` sem artifact canonico de `contract-review`.
- resultado esperado: `hold`.
- cenario B: usar `CONTRACT_REVIEW_STATUS` manual como fonte default do runner semanal.
- resultado esperado: `hold`.

## Green
- acao:
  - adicionar target `make phase-f8-contract-review`;
  - criar parser/validator canonico de `contract-review` para ler `contract_review_status` e `critical_drifts_open`;
  - ligar o runner semanal ao artifact `artifacts/phase-f8/contract-review/2026-W09.md`;
  - publicar a primeira revisao real da semana `2026-W09` cobrindo `runtime`, `integrations`, `trading` e `security`.
- comandos:
  1. `make phase-f8-contract-review`
  2. `make phase-f8-weekly-governance`
  3. `bash scripts/ci/check_phase_f8_weekly_governance.sh`
- resultado:
  - `phase-f8-contract-review: PASS`
  - `phase-f8-weekly-governance: decision=hold`
  - `phase-f8-weekly-governance: PASS`

## Refactor
- manter override por variavel de ambiente apenas para testes do runner semanal.
- preservar o formato do relatorio semanal da `F8`, mas trocar a fonte default do status contratual para o artifact canonico.

## Evidencia objetiva
- artifact canonico publicado:
  - `artifacts/phase-f8/contract-review/2026-W09.md`
- dominos revisados:
  - `runtime`: `PASS`
  - `integrations`: `PASS`
  - `trading`: `FAIL`
  - `security`: `PASS`
- drift aberto detectado na rodada:
  - `DRIFT-F8-2026-W09-01`
  - severidade: `critical`
  - motivo: `F8` ativa apesar de `F7 -> F8` seguir em `hold` com itens criticos de `S1` ainda em `fail`
- relatorio semanal regravado:
  - `artifacts/phase-f8/weekly-governance/2026-W09.md`
  - `contract_review_status=PASS`
  - `critical_drifts_open=1`
  - `decision=hold`
- logs adicionais da rodada:
  - `artifacts/phase-f8/weekly-governance/logs/2026-W09/20260301T084953-eval-gates.log`
  - `artifacts/phase-f8/weekly-governance/logs/2026-W09/20260301T084953-ci-quality.log`
  - `artifacts/phase-f8/weekly-governance/logs/2026-W09/20260301T084953-ci-security.log`

## Alteracoes da issue
- `Makefile`
- `scripts/ci/phase_f8_contract_review.py`
- `scripts/ci/read_phase_f8_contract_review.sh`
- `scripts/ci/check_phase_f8_contract_review.sh`
- `scripts/ci/run_phase_f8_weekly_governance.sh`
- `scripts/ci/check_phase_f8_weekly_governance.sh`
- `artifacts/phase-f8/contract-review/2026-W09.md`
- `artifacts/phase-f8/weekly-governance/2026-W09.md`
- `artifacts/phase-f8/epic-f8-02-issue-01-contract-review-conformity.md`
- `PRD/CHANGELOG.md`
