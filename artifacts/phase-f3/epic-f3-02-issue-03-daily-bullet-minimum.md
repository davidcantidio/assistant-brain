# EPIC-F3-02 ISSUE-F3-02-03 Daily Bullet Minimum Validation

- data/hora: 2026-03-01 10:25:00 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F3-02-03` (bullet minimo por secao obrigatoria + excecao noturna)
- fonte de verdade: `PRD/PRD-MASTER.md`

## Evidence Contract

### Scenario 1
```yaml
scenario: "Red-A"
command: "make eval-runtime"
expected_result: "FAIL por ausencia de bullet minimo"
actual_assert_message: "workspaces/main/memory/2099-12-30.md: secao 'Decisions Made' sem bullet obrigatorio."
trace_id_or_ref: "artifact:f3-02-03:red-a"
status: "PASS"
```

### Scenario 2
```yaml
scenario: "Red-B"
command: "make eval-runtime"
expected_result: "FAIL por atraso >24h sem incident_ref"
actual_assert_message: "invalid_nightly_memory_cycle_missing_incident_ref deveria falhar, mas passou. (bloqueado no expect_invalid)"
trace_id_or_ref: "artifact:f3-02-03:red-b"
status: "PASS"
```

### Scenario 3
```yaml
scenario: "Green"
command: "make eval-runtime"
expected_result: "PASS com bullets minimos e trilha noturna coerente"
actual_assert_message: "eval-runtime-contracts: PASS"
trace_id_or_ref: "artifact:f3-02-03:green"
status: "PASS"
```

### Scenario 4
```yaml
scenario: "Refactor"
command: "make eval-runtime"
expected_result: "PASS estavel na segunda execucao"
actual_assert_message: "eval-runtime-contracts: PASS"
trace_id_or_ref: "artifact:f3-02-03:refactor"
status: "PASS"
```

## Alteracoes da issue
- evidencia auditavel com cobertura semantica local e trilha de excecao noturna.
