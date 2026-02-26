# EPIC-F4-03 ISSUE-F4-03-01 OpenRouter Canonical Rule and Forbidden Phrases

- data/hora: 2026-02-26 17:48:12 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F4-03-01` (regra canonica OpenRouter + linguagem proibida)
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md`

## Red
- cenario A: alterar a frase canonica de OpenRouter apenas em `README.md`.
- comando: `make eval-integrations`.
- resultado: `FAIL` como esperado (`Texto obrigatorio ausente em README.md ...`, `make: *** [eval-integrations] Error 1`).

- cenario B: remover `cloud_adapter_preferred_when_enabled: "openrouter"` de `SEC/allowlists/PROVIDERS.yaml`.
- comando: `make eval-integrations`.
- resultado: `FAIL` como esperado (`make: *** [eval-integrations] Error 1`).

## Green
- acao: restaurar frase canonica e chave obrigatoria da allowlist.
- comando: `make eval-integrations`.
- resultado: `eval-integrations: PASS`.

## Refactor
- comando: `make eval-integrations` (segunda execucao para estabilidade).
- resultado: `eval-integrations: PASS`.

## Alteracoes da issue
- `scripts/ci/eval_integrations.sh`
  - adiciona helpers `search_re_each_file` e `search_fixed_each_file`.
  - endurece regra canonica de OpenRouter para exigir texto exato por arquivo alvo, evitando falso positivo por match parcial em outro documento.
- `artifacts/phase-f4/epic-f4-03-issue-01-openrouter-canonical-rule.md`
  - evidencia auditavel do ciclo TDD da issue.
