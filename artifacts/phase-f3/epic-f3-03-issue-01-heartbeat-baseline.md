# EPIC-F3-03 ISSUE-F3-03-01 Heartbeat Baseline Validation

- data/hora: 2026-03-01 10:30:00 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F3-03-01` (baseline oficial de 15 minutos + cobertura de autonomia)
- fonte de verdade: `PRD/PRD-MASTER.md`

## Evidence Contract

### Scenario 1
```yaml
scenario: "Red-A"
command: "make eval-runtime"
expected_result: "FAIL quando baseline ARC divergir de 15 minutos"
actual_assert_message: "[E-RUNTIME-SEARCH-001] padrao obrigatorio nao encontrado: pattern='base global: 15 minutos' files='ARC/ARC-HEARTBEAT.md'"
trace_id_or_ref: "artifact:f3-03-01:red-a"
status: "PASS"
```

### Scenario 2
```yaml
scenario: "Red-B"
command: "make eval-runtime"
expected_result: "FAIL quando baseline workspace divergir de 15 minutos"
actual_assert_message: "[E-RUNTIME-SEARCH-001] padrao obrigatorio nao encontrado: pattern='Baseline oficial: 15 minutos' files='workspaces/main/HEARTBEAT.md'"
trace_id_or_ref: "artifact:f3-03-01:red-b"
status: "PASS"
```

### Scenario 3
```yaml
scenario: "Red-C"
command: "make eval-runtime"
expected_result: "FAIL quando stalled_threshold_checks != 2"
actual_assert_message: "invalid_ops_autonomy_contract_stalled_threshold deveria falhar, mas passou. (bloqueado no expect_invalid)"
trace_id_or_ref: "artifact:f3-03-01:red-c"
status: "PASS"
```

### Scenario 4
```yaml
scenario: "Green/Refactor"
command: "make eval-runtime"
expected_result: "PASS com baseline e autonomia alinhados"
actual_assert_message: "eval-runtime-contracts: PASS"
trace_id_or_ref: "artifact:f3-03-01:green-refactor"
status: "PASS"
```

## Alteracoes da issue
- `scripts/ci/eval_runtime_contracts.sh`
  - baseline do ARC com checks obrigatorios explicitos.
  - mensagens assertivas para falhas de padrao obrigatorio.
