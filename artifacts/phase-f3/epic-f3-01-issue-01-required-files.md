# EPIC-F3-01 ISSUE-F3-01-01 Required Files Runtime Gate Validation

- data/hora: 2026-03-01 10:00:00 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F3-01-01` (required files: duplicidade + faltantes agregados)
- fonte de verdade: `PRD/PRD-MASTER.md`

## Evidence Contract

### Scenario 1
```yaml
scenario: "Red"
command: "make eval-runtime"
expected_result: "FAIL com indicacao explicita do arquivo faltante"
actual_assert_message: "Arquivo obrigatorio ausente: PRD/CHANGELOG.md"
trace_id_or_ref: "artifact:f3-01-01:red"
status: "PASS"
```

### Scenario 2
```yaml
scenario: "Green"
command: "make eval-runtime"
expected_result: "PASS apos restaurar required_files"
actual_assert_message: "eval-runtime-contracts: PASS"
trace_id_or_ref: "artifact:f3-01-01:green"
status: "PASS"
```

### Scenario 3
```yaml
scenario: "Refactor"
command: "make eval-runtime"
expected_result: "PASS estavel em segunda execucao"
actual_assert_message: "eval-runtime-contracts: PASS"
trace_id_or_ref: "artifact:f3-01-01:refactor"
status: "PASS"
```

## Alteracoes da issue
- `scripts/ci/eval_runtime_contracts.sh`
  - bloqueia caminhos duplicados em `required_files`.
  - agrega todos os `required_files` ausentes e falha em lote.
