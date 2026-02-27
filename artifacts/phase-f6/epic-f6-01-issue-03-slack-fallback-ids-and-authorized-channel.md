# EPIC-F6-01 ISSUE-F6-01-03 fallback Slack com IDs preenchidos e canal autorizado

- data/hora: 2026-02-27 16:46:13 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F6-01-03`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md` (`B1-R19`)

## Red
- cenario A: operador habilitado com `slack_ready=true` e `slack_user_ids`/`slack_channel_ids` vazios.
- resultado esperado: `FAIL` no `make ci-security`.
- cenario B: regra documental sem exigencia explicita de `channel_id` autorizado por `slack_channel_ids`.
- resultado esperado: `FAIL` no `make ci-security`.

## Green
- acao:
  - endurecer parser de `SEC/allowlists/OPERATORS.yaml` em `scripts/ci/check_security.sh` para bloquear `slack_ready=true` sem:
    - `slack_user_ids` nao vazio;
    - `slack_channel_ids` nao vazio;
    - IDs sem vazio/duplicidade/colisao entre operadores habilitados;
  - exigir, via checks normativos, regra explicita de `channel_id` autorizado por `slack_channel_ids` e prontidao de fallback Slack com IDs nao vazios.
- comando: `make ci-security`.
- resultado: `security-check: PASS`.

## Refactor
- comando: `make ci-quality`.
- resultado: `quality-check: PASS`.

## Alteracoes da issue
- `scripts/ci/check_security.sh`
- `PRD/CHANGELOG.md`
- `artifacts/phase-f6/epic-f6-01-issue-03-slack-fallback-ids-and-authorized-channel.md`
