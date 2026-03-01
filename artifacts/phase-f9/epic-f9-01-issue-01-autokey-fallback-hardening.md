# EPIC-F9-01 ISSUE-F9-01-01 auto-key fallback manual sem lacuna

- data/hora: 2026-03-01
- escopo: `ISSUE-F9-01-01`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PM/PHASES/F9-ONBOARDING-CREDENCIAIS-E-CANAIS-AUTOMATIZADOS/EPIC-F9-01-LITELLM-AUTOKEY-E-OPENROUTER.md`

## Red
- comando: `bash scripts/verify_linux.sh`
- cenario: `.env` com `LITELLM_API_KEY` vazio.
- resultado: `FAIL` com mensagem de chave vazia (lacuna bloqueada).

## Green
- comando: `bash scripts/ci/check_quality.sh`
- resultado: `quality-check: PASS`.

- comando: `bash scripts/verify_linux.sh` com chave temporaria sanitizada (`sk-litellm-f9-issue01-test`) apenas para validacao local.
- resultado: `verify: PASS (0 erro(s), 0 aviso(s)).`

## Mudancas da issue
- `scripts/onboard_linux.sh`
  - exige fallback manual nao vazio apos falha de `/key/generate`.
  - bloqueia conclusao do onboarding interativo sem `LITELLM_API_KEY` efetiva.
- `scripts/verify_linux.sh`
  - valida `LITELLM_API_KEY` com valor nao vazio.

## Criterio de aceite atendido
- auto-geracao com falha nao permite onboarding com lacuna de `LITELLM_API_KEY`.
- verify detecta e bloqueia `.env` com `LITELLM_API_KEY` vazia.
