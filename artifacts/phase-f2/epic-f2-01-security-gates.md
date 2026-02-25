# EPIC-F2-01 Security and Gates Validation

- data/hora: 2026-02-25 19:00:02 -0300
- host alvo: Darwin arm64
- escopo: EPIC-F2-01 (baseline de seguranca e gates obrigatorios)
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md`, `SEC/SEC-POLICY.md`, `PM/DECISION-PROTOCOL.md`

## ISSUE-F2-01-01 - Gates obrigatorios e fail-fast

### Red
- acao: simular gate faltante com falha forcada em `eval-gates` no gate agregado.
- comando: `make phase-f2-gate`
- resultado: FAIL (`exit 2`)
- evidencia:
  - `[phase-f2-gate] running ci-quality` -> `quality-check: PASS`
  - `[phase-f2-gate] running ci-security` -> `security-check: PASS`
  - `[phase-f2-gate] running eval-gates` -> `forced red: eval-gates unavailable`
  - `make: *** [phase-f2-gate] Error 1`

### Green
- acao: restaurar baseline canonico e rerodar gate agregado.
- comando: `make phase-f2-gate`
- resultado: PASS (`phase-f2-gate: PASS`)

### Refactor
- comando: `make phase-f2-gate`
- resultado: PASS

## ISSUE-F2-01-02 - Baseline de privacidade, allowlists e operadores

### Red
- acao: remover temporariamente secao de classificacao de sensibilidade em `SEC/SEC-POLICY.md`.
- comando: `make ci-security`
- resultado: FAIL (`exit 2`)
- evidencia: `make: *** [ci-security] Error 1`

### Green
- acao: restaurar policy canonica e rerodar gate de seguranca.
- comando: `make ci-security`
- resultado: PASS (`security-check: PASS`)

### Refactor
- comando: `make ci-security`
- resultado: PASS

## ISSUE-F2-01-03 - Canal confiavel e approval queue

### Red
- acao: remover temporariamente token `UNTRUSTED_COMMAND_SOURCE` em `PM/DECISION-PROTOCOL.md`.
- comando: `make ci-security`
- resultado: FAIL (`exit 2`)
- evidencia: `make: *** [ci-security] Error 1`

### Green
- acao: restaurar `DECISION-PROTOCOL` canonico e rerodar gate.
- comando: `make ci-security`
- resultado: PASS (`security-check: PASS`)

### Refactor
- comando: `make ci-security`
- resultado: PASS

## Validacao final do epico

1. `make ci-quality` -> PASS (`quality-check: PASS`)
2. `make ci-security` -> PASS (`security-check: PASS`)
3. `make eval-gates` -> PASS (`eval-gates: PASS`)
4. `make phase-f2-gate` -> PASS (`phase-f2-gate: PASS`)

## Rastreabilidade

- Roadmap: `B0-14`, `B0-15`, `B0-16`, `B0-19`, `B0-21`.
- Source refs:
  - `felixcraft.md` (Trust Ladder, Approval Queue Pattern, Email Security HARD RULES).
  - `felix-openclaw-pontos-relevantes.md` (canais autenticados vs informacionais).
