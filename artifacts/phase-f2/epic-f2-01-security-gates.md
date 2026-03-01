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

### Auditoria complementar
- `eval-risk-gates` passa a validar `PM/policies/f2-risk-gate-matrix.json`.
- tiers `R2/R3` agora exigem `Gatekeeper/Reviewer` e `pre_live_checklist_required=true`.
- o gate agregado da fase considera a matriz executavel antes de promover.

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

### Auditoria complementar
- fluxos `sensitive` agora exigem coerencia entre provider allowlist restrita, `require_zdr=true`, `no_fallback_default=true` e `pin_provider_default=true`.
- a validacao executavel tambem exige retention minima compativel com ZDR para payloads sensiveis.

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

### Auditoria complementar
- `decision.schema.json` agora exige `side_effect_class`, `explicit_human_approval`, `approval_evidence_ref` e `approval_signature_valid`.
- side effect financeiro sem `explicit_human_approval=true`, `challenge_status=VALIDATED` e `approver_operator_id` valido passa a falhar.
- aprovacao em `slack` sem assinatura valida passa a ser bloqueada.

## Validacao final do epico

1. `make ci-quality` -> PASS (`quality-check: PASS`)
2. `make ci-security` -> PASS (`security-check: PASS`)
3. `make eval-risk-gates` -> PASS (`eval-risk-gates: PASS`)
4. `make eval-gates` -> PASS (`eval-gates: PASS`)
5. `make phase-f2-gate` -> PASS (`phase-f2-gate: PASS`)

## Rastreabilidade

- Roadmap: `B0-14`, `B0-15`, `B0-16`, `B0-19`, `B0-21`.
- Source refs:
  - `felixcraft.md` (Trust Ladder, Approval Queue Pattern, Email Security HARD RULES).
  - `felix-openclaw-pontos-relevantes.md` (canais autenticados vs informacionais).
