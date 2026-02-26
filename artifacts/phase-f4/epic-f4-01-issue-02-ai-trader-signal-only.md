# EPIC-F4-01 ISSUE-F4-01-02 AI-Trader Signal-Only Validation

- data/hora: 2026-02-26 15:12:55 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F4-01-02` (regra mandataria AI-Trader `signal_intent` only)
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md` (`B1-22`)

## Red
- cenario A: ambiguar regra `MUST operar somente como gerador de signal_intent`.
- cenario B: ambiguar bloqueio `MUST NOT enviar order_intent diretamente`.
- cenario C: remover bloqueio/auditoria explicita para ordem direta originada do AI-Trader.
- comando em todos os cenarios: `make eval-integrations`.
- resultado observado em todos os cenarios: `FAIL` (`make: *** [eval-integrations] Error 1`).

## Green
- acao: restaurar integralmente as regras mandatarias no `INTEGRATIONS/AI-TRADER.md`.
- comando: `make eval-integrations`.
- resultado: `eval-integrations: PASS`.

## Refactor
- comando: `make eval-integrations` (segunda execucao para estabilidade).
- resultado: `eval-integrations: PASS`.

## Alteracoes da issue
- `artifacts/phase-f4/epic-f4-01-issue-02-ai-trader-signal-only.md`
  - evidencia auditavel do ciclo TDD da issue.
