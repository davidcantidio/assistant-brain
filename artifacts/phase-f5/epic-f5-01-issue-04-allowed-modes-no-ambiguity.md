# EPIC-F5-01 ISSUE-F5-01-04 Modo permitido por integracao sem ambiguidade

- data/hora: 2026-02-26 18:31:49 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F5-01-04`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md` (`B1-20`, `B1-22`, `B1-23`, `B1-24`)

## Red
- cenario A: remover matriz explicita de modos permitidos do pacote `INTEGRATIONS`.
- resultado esperado: `FAIL` no `eval-integrations` por ausencia de matriz obrigatoria.
- cenario B: manter ambiguidade de modo permitido para AI-Trader/ClawWork.
- resultado esperado: `FAIL` no gate por ausencia de padroes obrigatorios de modo permitido.

## Green
- acao:
  - adicionar matriz explicita em `INTEGRATIONS/README.md` com:
    - `AI-Trader = signal_only`;
    - `ClawWork = lab_isolated(default) / governed(gateway-only)`;
    - `OpenClaw upstream = gateway.control_plane.ws canonico + chatCompletions opcional`.
  - endurecer `scripts/ci/eval_integrations.sh` para exigir a matriz e os tres padroes de modo permitido.
- comando: `make eval-integrations`.
- resultado: `eval-integrations: PASS`.

## Refactor
- comandos:
  1. `make eval-trading`
  2. `make ci-quality`
- resultados:
  - `eval-trading: PASS`
  - `quality-check: PASS`

## Alteracoes da issue
- `INTEGRATIONS/README.md`
  - adiciona matriz canonica de modos permitidos por integracao.
- `scripts/ci/eval_integrations.sh`
  - adiciona checks obrigatorios para matriz e modos permitidos explicitos.
- `PRD/CHANGELOG.md`
  - registra execucao normativa da `ISSUE-F5-01-04`.
- `artifacts/phase-f5/epic-f5-01-issue-04-allowed-modes-no-ambiguity.md`
  - evidencia auditavel do ciclo da issue.


## Auditoria F5 2026-03-01
- escopo da rodada: remediacao documental da F5 e revalidacao dos gates de fase.
- ajuste principal: Template INTEGRATIONS completado com objetivo, modo, contratos, riscos, testes, rollback e policy E2B explicita.
- `make eval-integrations`: `eval-integrations: PASS`
- `make eval-trading`: `eval-trading: PASS`
- evidencia consolidada: `artifacts/phase-f5/validation-summary.md`
