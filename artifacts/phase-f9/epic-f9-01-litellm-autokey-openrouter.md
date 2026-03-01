# EPIC-F9-01 LiteLLM auto-key e OpenRouter opcional

- data/hora: 2026-03-01
- escopo: `EPIC-F9-01`
- fonte de verdade: `PRD/PRD-MASTER.md` (secao Onboarding de Credenciais e Canais F9)

## Cenario de sucesso (auto-key)
- condicao: `LITELLM_MASTER_KEY` + `LITELLM_BASE_URL` + `LITELLM_MODELS` validos.
- fluxo: onboarding interativo chama `generate_litellm_virtual_key.py` com `LITELLM_OUTPUT_MODE=key-only`.
- resultado esperado: `LITELLM_API_KEY` persistida no `.env` e `verify_linux.sh` valida chave nao vazia.

## Cenario de fallback manual
- condicao: falha no endpoint `/key/generate`.
- fluxo: onboarding exige `LITELLM_API_KEY` manual no fallback.
- controle anti-lacuna: onboarding interrompe com erro se a key continuar vazia.
- resultado esperado: setup so conclui quando existe `LITELLM_API_KEY` efetiva.

## OpenRouter opcional
- onboarding pergunta `OPENROUTER_API_KEY` explicitamente.
- `OPENROUTER_API_KEY` vazia/ausente nao bloqueia `scripts/verify_linux.sh`.
- policy preservada: OpenRouter opcional e desabilitado por default ate decision formal.

## Evidencia dos gates
- `bash scripts/ci/check_quality.sh` -> `quality-check: PASS` (inclui `phase-f9-litellm-keygen: PASS`).
- `bash scripts/ci/check_security.sh` -> `security-check: PASS`.
- `bash scripts/ci/eval_models.sh` -> `eval-models: PASS`.
- `bash scripts/verify_linux.sh` -> `PASS` quando `.env` contem `LITELLM_API_KEY` nao vazia.

## Arquivos-chave da entrega
- `scripts/onboard_linux.sh`
- `scripts/verify_linux.sh`
- `generate_litellm_virtual_key.py`
- `scripts/ci/check_phase_f9_litellm_keygen.sh`
- `README.md`
- `DEV/DEV-OPENCLAW-SETUP.md`
- `PM/PHASES/F9-ONBOARDING-CREDENCIAIS-E-CANAIS-AUTOMATIZADOS/EPICS.md`
- `PM/PHASES/F9-ONBOARDING-CREDENCIAIS-E-CANAIS-AUTOMATIZADOS/EPIC-F9-01-LITELLM-AUTOKEY-E-OPENROUTER.md`
