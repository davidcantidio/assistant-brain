---
doc_id: "ADR-0001-policy-engine-modularization.md"
version: "1.0"
status: "accepted"
owner: "Engineering"
last_updated: "2026-03-02"
---

# ADR-0001: Modularizar o Policy Engine e reduzir acoplamento em Bash

## Contexto
Os gates principais do repositorio ainda concentram regras em scripts Bash extensos com trechos Python inline, gerando baixa testabilidade e alto risco de contradicao entre checks.

## Decisao
- adotar `platform/policy-engine` como camada executavel principal de regras;
- manter `scripts/ci/*.sh` como wrappers finos para compatibilidade de pipeline;
- padronizar validacao de convergencia de policy via `run_policy_engine.py validate --consistency`;
- evoluir estrutura modular:
  - `policy_engine.domain`
  - `policy_engine.application`
  - `policy_engine.adapters`
  - `policy_engine.rules`.

## Consequencias
- curto prazo:
  - convive com legado em Bash durante migracao gradual;
  - reduz risco de checks mutuamente exclusivos.
- medio prazo:
  - aumenta cobertura de testes unitarios/contrato;
  - facilita rastreabilidade de regra por dominio e severidade;
  - viabiliza reducao progressiva de scripts monoliticos.

## Plano de Migracao
1. estabilizar convergencia (P0): remover contradicoes e bloquear regressao.
2. migrar regras runtime/security para classes testaveis no policy-engine.
3. migrar dominios integrations/trading/pm e reduzir Bash para wrappers.
4. definir schema `policy_run_result.v2` com metadados por regra.

## Matriz de Mapeamento (legado -> novo)
| Legado | Novo contrato executavel |
|---|---|
| `scripts/ci/eval_runtime_contracts.sh` | `policy-engine run --domain runtime --format json` |
| `scripts/ci/eval_idempotency_reconciliation.sh` | `policy-engine run --domain runtime --category idempotency --format json` |
| `scripts/ci/check_security.sh` | `policy-engine run --domain security --format json` |
| `scripts/ci/check_policy_convergence.sh` | `policy-engine validate --consistency` |
| bloco inline de qualidade em `scripts/ci/check_quality.sh` | `policy-engine validate --quality` |

## Deprecacao Controlada
- status: ativo com compatibilidade total de `make`.
- scripts legados permanecem como wrappers finos, sem regra de dominio embutida.
- toda regra nova MUST entrar em `platform/policy-engine/contracts/*.v1.yaml` e em modulo Python testavel.
