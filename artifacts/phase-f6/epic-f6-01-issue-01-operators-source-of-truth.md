# EPIC-F6-01 ISSUE-F6-01-01 operadores HITL como fonte de verdade

- data/hora: 2026-02-27 16:41:18 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F6-01-01`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md` (`B0-02`, `B0-19`)

## Red
- cenario A: operador habilitado sem `display_name` ou sem `telegram_user_id` valido.
- resultado esperado: `FAIL` no `make ci-security`.
- cenario B: colisao de identidade (`operator_id`, `telegram_user_id` ou `telegram_chat_id` duplicado entre operadores habilitados).
- resultado esperado: `FAIL` no `make ci-security`.

## Green
- acao:
  - endurecer parser de `SEC/allowlists/OPERATORS.yaml` em `scripts/ci/check_security.sh` para validar:
    - `operator_id` obrigatorio e unico;
    - `display_name` obrigatorio para operador habilitado;
    - `telegram_user_id` unico e numerico para operador habilitado;
    - `telegram_chat_ids` nao vazio, numerico, sem duplicidade e sem compartilhamento entre operadores habilitados;
    - vinculo de identidade Telegram (`telegram_user_id` presente em `telegram_chat_ids`) para operador habilitado.
- comando: `make ci-security`.
- resultado: `security-check: PASS`.

## Refactor
- comando: `make ci-quality`.
- resultado: `quality-check: PASS`.

## Alteracoes da issue
- `scripts/ci/check_security.sh`
- `PRD/CHANGELOG.md`
- `artifacts/phase-f6/epic-f6-01-issue-01-operators-source-of-truth.md`
