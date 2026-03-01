# EPIC-F9-01 ISSUE-F9-01-03 OpenRouter opcional no onboarding e docs

- data/hora: 2026-03-01
- escopo: `ISSUE-F9-01-03`
- fonte de verdade: `PRD/PRD-MASTER.md`, `README.md`, `DEV/DEV-OPENCLAW-SETUP.md`

## Red
- risco: drift documental entre onboarding e verify sobre opcionalidade de `OPENROUTER_API_KEY`.

## Green
- `README.md` atualizado para explicitar:
  - fallback manual obrigatorio de `LITELLM_API_KEY` quando auto-geracao falha;
  - `OPENROUTER_API_KEY` opcional, sem bloqueio no verify.
- `DEV/DEV-OPENCLAW-SETUP.md` atualizado para refletir o mesmo contrato.
- `scripts/verify_linux.sh` explicita no output que `OPENROUTER_API_KEY` vazia/ausente e opcional.

## Evidencia objetiva
- comando: `bash scripts/ci/check_quality.sh` -> `PASS`.
- comando: `bash scripts/ci/eval_models.sh` -> `PASS`.
- comando: `bash scripts/verify_linux.sh` -> nao falha por `OPENROUTER_API_KEY` vazia/ausente.

## Mudancas da issue
- `README.md`
- `DEV/DEV-OPENCLAW-SETUP.md`
- `scripts/verify_linux.sh`
- `PM/PHASES/F9-ONBOARDING-CREDENCIAIS-E-CANAIS-AUTOMATIZADOS/EPICS.md`
- `PM/PHASES/F9-ONBOARDING-CREDENCIAIS-E-CANAIS-AUTOMATIZADOS/EPIC-F9-01-LITELLM-AUTOKEY-E-OPENROUTER.md`
- `artifacts/phase-f9/epic-f9-01-litellm-autokey-openrouter.md`
