# EPIC-F9-01 ISSUE-F9-01-02 keygen maquina-consumivel com check CI dedicado

- data/hora: 2026-03-01
- escopo: `ISSUE-F9-01-02`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PM/PHASES/F9-ONBOARDING-CREDENCIAIS-E-CANAIS-AUTOMATIZADOS/EPIC-F9-01-LITELLM-AUTOKEY-E-OPENROUTER.md`

## Red
- cenario: regressao no contrato `LITELLM_OUTPUT_MODE=key-only` sem validação automatica.
- risco: onboarding shell-consumivel quebra silenciosamente.

## Green
- novo checker: `scripts/ci/check_phase_f9_litellm_keygen.sh`.
- cobertura do checker:
  - bloqueia dependencia `requests` no gerador;
  - valida `key-only` com sucesso retornando somente a chave;
  - valida erro explicito quando resposta nao contem key.
- integracao em gate:
  - `scripts/ci/check_quality.sh` passa a executar o checker;
  - `Makefile` ganha alvo `phase-f9-litellm-keygen`.

## Evidencia objetiva
- comando: `bash scripts/ci/check_phase_f9_litellm_keygen.sh`
- resultado esperado: `phase-f9-litellm-keygen: PASS`.

- comando: `bash scripts/ci/check_quality.sh`
- resultado esperado: `quality-check: PASS` com check F9 incluído.

## Mudancas da issue
- `scripts/ci/check_phase_f9_litellm_keygen.sh`
- `scripts/ci/check_quality.sh`
- `Makefile`
