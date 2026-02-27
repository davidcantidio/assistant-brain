# EPIC-F6-01 ISSUE-F6-01-02 canal confiavel Telegram primario e email nao confiavel

- data/hora: 2026-02-27 16:43:44 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F6-01-02`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md` (`B0-21`)

## Red
- cenario A: regra de canal com texto ambiguo que permita interpretar email como canal confiavel de comando.
- resultado esperado: `FAIL` no `make ci-security`.
- cenario B: ausencia de regra explicita de Telegram como canal primario HITL em um dos documentos normativos.
- resultado esperado: `FAIL` no `make ci-security`.

## Green
- acao:
  - endurecer `scripts/ci/check_security.sh` para exigir por arquivo normativo (`PM/DECISION-PROTOCOL.md`, `SEC/SEC-POLICY.md`, `PRD/PRD-MASTER.md`):
    - Telegram como canal primario;
    - Slack apenas como fallback controlado;
    - email explicitamente nao confiavel para comando;
  - bloquear linguagem ambigua sobre confianca de email em docs de canal/comando.
- comando: `make ci-security`.
- resultado: `security-check: PASS`.

## Refactor
- comando: `make ci-quality`.
- resultado: `quality-check: PASS`.

## Alteracoes da issue
- `scripts/ci/check_security.sh`
- `PRD/CHANGELOG.md`
- `artifacts/phase-f6/epic-f6-01-issue-02-trusted-channel-telegram-primary-email-untrusted.md`
