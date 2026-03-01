# EPIC-F3-01 ISSUE-F3-01-02 Runtime Schema A2A/Hooks/Gateway Validation

- data/hora: 2026-03-01 10:05:00 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F3-01-02` (schema/runtime contract + A2A/hooks/gateway)
- fonte de verdade: `PRD/PRD-MASTER.md`

## Evidence Contract

### Scenario 1
```yaml
scenario: "Red"
command: "make eval-runtime"
expected_result: "FAIL ao remover required fields mandatarios"
actual_assert_message: "invalid_missing_top_required deveria falhar, mas passou. (bloqueado no expect_invalid)"
trace_id_or_ref: "artifact:f3-01-02:red"
status: "PASS"
```

### Scenario 2
```yaml
scenario: "Green"
command: "make eval-runtime"
expected_result: "PASS com schema runtime valido"
actual_assert_message: "eval-runtime-contracts: PASS"
trace_id_or_ref: "artifact:f3-01-02:green"
status: "PASS"
```

### Scenario 3
```yaml
scenario: "Refactor"
command: "make eval-runtime"
expected_result: "PASS mantendo regressao protegida por fixtures invalidas"
actual_assert_message: "eval-runtime-contracts: PASS"
trace_id_or_ref: "artifact:f3-01-02:refactor"
status: "PASS"
```

## Alteracoes da issue
- `scripts/ci/eval_runtime_contracts.sh`
  - validacao estrutural de `openclaw_runtime_config`.
  - cenarios `valid/invalid` para bloquear drift contratual de A2A/hooks/gateway.
