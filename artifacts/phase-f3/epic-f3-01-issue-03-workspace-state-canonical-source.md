# EPIC-F3-01 ISSUE-F3-01-03 Workspace-State Canonical Source Validation

- data/hora: 2026-03-01 10:10:00 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F3-01-03` (unicidade da fonte canonica de workspace state)
- fonte de verdade: `PRD/PRD-MASTER.md`

## Evidence Contract

### Scenario 1
```yaml
scenario: "Red"
command: "make eval-runtime"
expected_result: "FAIL por conflito de fonte canonica"
actual_assert_message: "workspace-state invalido: esperado exatamente 1 caminho canonico em workspaces/*/.openclaw/workspace-state.json; encontrados 2."
trace_id_or_ref: "artifact:f3-01-03:red"
status: "PASS"
```

### Scenario 2
```yaml
scenario: "Green"
command: "make eval-runtime"
expected_result: "PASS com caminho canonico unico"
actual_assert_message: "eval-runtime-contracts: PASS"
trace_id_or_ref: "artifact:f3-01-03:green"
status: "PASS"
```

### Scenario 3
```yaml
scenario: "Refactor"
command: "make eval-runtime"
expected_result: "PASS estavel na segunda execucao"
actual_assert_message: "eval-runtime-contracts: PASS"
trace_id_or_ref: "artifact:f3-01-03:refactor"
status: "PASS"
```

## Alteracoes da issue
- `scripts/ci/eval_runtime_contracts.sh`
  - guarda de unicidade para `workspaces/*/.openclaw/workspace-state.json`.
  - caminho canonico unico em `workspaces/main/.openclaw/workspace-state.json`.
