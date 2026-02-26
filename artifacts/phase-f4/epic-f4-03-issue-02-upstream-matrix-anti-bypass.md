# EPIC-F4-03 ISSUE-F4-03-02 Upstream Compatibility Matrix and Anti-Bypass Pipeline

- data/hora: 2026-02-26 17:49:29 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F4-03-02` (matriz upstream + pipeline anti-bypass)
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md` (`B1-22`, `B1-24`)

## Red
- cenario A: remover o marcador `Matriz de Compatibilidade` de `INTEGRATIONS/OPENCLAW-UPSTREAM.md`.
- comando: `make eval-integrations`.
- resultado: `FAIL` como esperado (`Padrao obrigatorio ausente em INTEGRATIONS/OPENCLAW-UPSTREAM.md: Matriz de Compatibilidade`).

- cenario B: remover o pipeline oficial em `VERTICALS/TRADING/TRADING-PRD.md`.
- comando: `make eval-integrations`.
- resultado: `FAIL` como esperado (`Padrao obrigatorio ausente em VERTICALS/TRADING/TRADING-PRD.md: AI-Trader -> signal_intent -> normalizacao/deduplicacao -> pre_trade_validator -> HITL -> execution_gateway`).

- cenario C: remover a regra anti-bypass em `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`.
- comando: `make eval-integrations`.
- resultado: `FAIL` como esperado (`Padrao obrigatorio ausente em VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md: ordem direta originada do AI-Trader MUST ser rejeitado e auditado`).

## Green
- acao: restaurar matriz upstream e regras de pipeline/anti-bypass.
- comando: `make eval-integrations`.
- resultado: `eval-integrations: PASS`.

## Refactor
- comando: `make eval-integrations` (segunda execucao para estabilidade).
- resultado: `eval-integrations: PASS`.

## Alteracoes da issue
- `scripts/ci/eval_integrations.sh`
  - endurece checks de matriz upstream para validacao por arquivo.
  - endurece pipeline oficial e regra anti-bypass para validacao obrigatoria nos dois docs de trading (`TRADING-PRD` e `TRADING-ENABLEMENT-CRITERIA`).
- `artifacts/phase-f4/epic-f4-03-issue-02-upstream-matrix-anti-bypass.md`
  - evidencia auditavel do ciclo TDD da issue.
