# EPIC-F3-03 ISSUE-F3-03-02 Timezone and Nightly Validation

- data/hora: 2026-03-01 10:35:00 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F3-03-02` (timezone `America/Sao_Paulo` + nightly extraction as 23:00)
- fonte de verdade: `PRD/PRD-MASTER.md`

## Evidence Contract

### Scenario 1
```yaml
scenario: "Red-A"
command: "make eval-runtime"
expected_result: "FAIL quando horario noturno ARC divergir"
actual_assert_message: "[E-RUNTIME-SEARCH-001] padrao obrigatorio nao encontrado: pattern='Nightly extraction de memoria: 23:00' files='ARC/ARC-HEARTBEAT.md'"
trace_id_or_ref: "artifact:f3-03-02:red-a"
status: "PASS"
```

### Scenario 2
```yaml
scenario: "Red-B"
command: "make eval-runtime"
expected_result: "FAIL quando horario workspace divergir"
actual_assert_message: "[E-RUNTIME-SEARCH-001] padrao obrigatorio nao encontrado: pattern='23:00 \\(America/Sao_Paulo\\).*nightly extraction' files='workspaces/main/HEARTBEAT.md'"
trace_id_or_ref: "artifact:f3-03-02:red-b"
status: "PASS"
```

### Scenario 3
```yaml
scenario: "Green/Refactor"
command: "make eval-runtime"
expected_result: "PASS com timezone e schedule canonicos"
actual_assert_message: "eval-runtime-contracts: PASS"
trace_id_or_ref: "artifact:f3-03-02:green-refactor"
status: "PASS"
```

## Alteracoes da issue
- evidencia auditavel com asserts de timezone/schedule e rerun estavel.
