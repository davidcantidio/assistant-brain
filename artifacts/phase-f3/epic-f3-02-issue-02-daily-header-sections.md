# EPIC-F3-02 ISSUE-F3-02-02 Daily Header and Required Sections Validation

- data/hora: 2026-03-01 10:20:00 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F3-02-02` (header `# YYYY-MM-DD`, secoes obrigatorias e trilha noturna)
- fonte de verdade: `PRD/PRD-MASTER.md`

## Evidence Contract

### Scenario 1
```yaml
scenario: "Red-A"
command: "make eval-runtime"
expected_result: "FAIL por cabecalho invalido"
actual_assert_message: "workspaces/main/memory/2099-12-31.md: cabecalho diario invalido (esperado '# YYYY-MM-DD')."
trace_id_or_ref: "artifact:f3-02-02:red-a"
status: "PASS"
```

### Scenario 2
```yaml
scenario: "Red-B"
command: "make eval-runtime"
expected_result: "FAIL por atraso >24h sem incident_ref"
actual_assert_message: "invalid_nightly_memory_cycle_missing_incident_ref deveria falhar, mas passou. (bloqueado no expect_invalid)"
trace_id_or_ref: "artifact:f3-02-02:red-b"
status: "PASS"
```

### Scenario 3
```yaml
scenario: "Green"
command: "make eval-runtime"
expected_result: "PASS com estrutura valida e trilha noturna auditavel"
actual_assert_message: "eval-runtime-contracts: PASS"
trace_id_or_ref: "artifact:f3-02-02:green"
status: "PASS"
```

### Scenario 4
```yaml
scenario: "Refactor"
command: "make eval-runtime"
expected_result: "PASS estavel na segunda execucao"
actual_assert_message: "eval-runtime-contracts: PASS"
trace_id_or_ref: "artifact:f3-02-02:refactor"
status: "PASS"
```

## Alteracoes da issue
- cobertura de cabecalho/secoes e auditoria noturna com `incident_ref` para atraso >24h.
