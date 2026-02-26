# EPIC-F5-03 ISSUE-F5-03-06 segregacao de contas e credenciais por superficie

- data/hora: 2026-02-26 20:42:00 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F5-03-06`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md` (`B1-R14`)

## Red
- cenario A: superficie sem segregacao explicita entre `agent_account_id` e `personal_account_id`.
- resultado esperado: `FAIL` no `make ci-security`.
- cenario B: superficie sem `minimum_scope` (least privilege) ou sem `segregation_enforced=true`.
- resultado esperado: `FAIL` no `make ci-security`.

## Green
- acao:
  - criar `SEC/allowlists/AGENT-IDENTITY-SURFACES.yaml` com superfícies `social/email/pagamentos/carteira`;
  - endurecer `scripts/ci/check_security.sh` para validar segregacao, least privilege e diferenca obrigatoria entre contas pessoal/agente;
  - alinhar `SEC/SEC-POLICY.md` e `PRD/PRD-MASTER.md` ao contrato de blast radius.
- comando: `make ci-security`.
- resultado: `security-check: PASS`.

## Refactor
- comandos:
  1. `make eval-runtime`
  2. `make eval-gates`
- resultados:
  - `eval-runtime-contracts: PASS`
  - `eval-gates: PASS`

## Alteracoes da issue
- `SEC/allowlists/AGENT-IDENTITY-SURFACES.yaml` (novo)
- `scripts/ci/check_security.sh`
- `SEC/SEC-POLICY.md`
- `PRD/PRD-MASTER.md`
- `PRD/CHANGELOG.md`
- `artifacts/phase-f5/epic-f5-03-issue-06-account-credential-segregation-blast-radius.md`
