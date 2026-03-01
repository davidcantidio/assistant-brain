# EPIC-F3-03 ISSUE-F3-03-03 Critical Channel and Financial Rules Validation

- data/hora: 2026-03-01 10:40:00 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F3-03-03` (enforcement simulado: canal confiavel + aprovacao humana explicita)
- fonte de verdade: `PRD/PRD-MASTER.md`

## Evidence Contract

### Scenario 1
```yaml
scenario: "Red-A"
command: "make eval-runtime"
expected_result: "FAIL para input_channel=email sem confirmacao em canal confiavel"
actual_assert_message: "[E-F3-033-RED-A] scenario_red_a_email_untrusted bloqueado: email sem confirmacao em canal confiavel."
trace_id_or_ref: "TRACE-F3-033-RED-A"
status: "PASS"
```

### Scenario 2
```yaml
scenario: "Red-B"
command: "make eval-runtime"
expected_result: "FAIL para financial_side_effect=true sem explicit_human_approval"
actual_assert_message: "[E-F3-033-RED-B] scenario_red_b_financial_without_approval bloqueado: side effect financeiro sem aprovacao humana explicita."
trace_id_or_ref: "TRACE-F3-033-RED-B"
status: "PASS"
```

### Scenario 3
```yaml
scenario: "Green"
command: "make eval-runtime"
expected_result: "PASS para canal confiavel + aprovacao explicita + trace_id valido"
actual_assert_message: "policy_execution_contract: PASS"
trace_id_or_ref: "TRACE-F3-033-GREEN"
status: "PASS"
```

### Scenario 4
```yaml
scenario: "Refactor"
command: "make eval-runtime"
expected_result: "PASS estavel apos rerun"
actual_assert_message: "eval-runtime-contracts: PASS"
trace_id_or_ref: "TRACE-F3-033-REFACTOR"
status: "PASS"
```

## Alteracoes da issue
- `scripts/ci/eval_runtime_contracts.sh`
  - adiciona bloco Python de enforcement operacional simulado para canal/aprovacao financeira.
  - adiciona codigos assertivos para cenarios invalidos e validos.
