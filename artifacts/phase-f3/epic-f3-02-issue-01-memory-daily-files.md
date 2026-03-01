# EPIC-F3-02 ISSUE-F3-02-01 Memory and Daily Files Validation

- data/hora: 2026-03-01 10:15:00 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F3-02-01` (presenca canonica de `MEMORY.md` e nota diaria `YYYY-MM-DD`)
- fonte de verdade: `PRD/PRD-MASTER.md`

## Evidence Contract

### Scenario 1
```yaml
scenario: "Red-A"
command: "make eval-runtime"
expected_result: "FAIL por ausencia de MEMORY.md"
actual_assert_message: "Arquivo obrigatorio ausente: workspaces/main/MEMORY.md"
trace_id_or_ref: "artifact:f3-02-01:red-a"
status: "PASS"
```

### Scenario 2
```yaml
scenario: "Red-B"
command: "make eval-runtime"
expected_result: "FAIL por ausencia de nota diaria YYYY-MM-DD"
actual_assert_message: "Nenhuma nota diaria encontrada em workspaces/main/memory/YYYY-MM-DD.md"
trace_id_or_ref: "artifact:f3-02-01:red-b"
status: "PASS"
```

### Scenario 3
```yaml
scenario: "Green"
command: "make eval-runtime"
expected_result: "PASS com memoria canonica restaurada"
actual_assert_message: "eval-runtime-contracts: PASS"
trace_id_or_ref: "artifact:f3-02-01:green"
status: "PASS"
```

### Scenario 4
```yaml
scenario: "Refactor"
command: "make eval-runtime"
expected_result: "PASS estavel na segunda execucao"
actual_assert_message: "eval-runtime-contracts: PASS"
trace_id_or_ref: "artifact:f3-02-01:refactor"
status: "PASS"
```

## Alteracoes da issue
- evidencia auditavel do ciclo TDD com `Red-A`, `Red-B`, `Green`, `Refactor`.
