---
doc_id: "EPIC-F4-03-COERENCIA-NORMATIVA-E-GATE.md"
version: "1.1"
status: "active"
owner: "PM"
last_updated: "2026-02-26"
rfc_refs: ["RFC-001", "RFC-015", "RFC-030", "RFC-040", "RFC-050", "RFC-060"]
---

# EPIC-F4-03 Coerencia normativa anti-drift e gate

## Objetivo
Garantir coerencia normativa entre docs e allowlists de integracao, bloquear drift e consolidar evidencia de fase para decisao de promocao.

## Resultado de Negocio Mensuravel
- drift documental relevante vira falha objetiva de gate.
- fase encerra com evidencia unica e decisao rastreavel de promocao.

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- `make eval-integrations` executado com sucesso.
- evidencia consolidada de fase registrada com decisao `promote|hold`.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F4-03-01 - Validar regra canonica OpenRouter e frases proibidas
**User story**  
Como operador, quero linguagem normativa unica sobre OpenRouter para evitar ambiguidade de operacao.

**Plano TDD**
1. `Red`: introduzir frase proibida ou remover trecho canonico em docs/allowlist e executar `make eval-integrations`.
2. `Green`: restaurar frase canonica e remover linguagem proibida.
3. `Refactor`: rerodar `make eval-integrations` e registrar evidencias.

**Criterios de aceitacao**
- Given linguagem OpenRouter ambigua ou proibida, When `make eval-integrations` roda, Then o gate falha.
- Given frase canonica consistente e allowlist alinhada, When `make eval-integrations` roda, Then retorna `PASS`.

### ISSUE-F4-03-02 - Validar matriz de compatibilidade upstream e pipeline anti-bypass
**User story**  
Como operador, quero confirmar compatibilidade upstream e bloqueio de bypass para manter seguranca de integracao e trading.

**Plano TDD**
1. `Red`: remover matriz de compatibilidade ou trecho de pipeline anti-bypass e executar `make eval-integrations`.
2. `Green`: restaurar matriz WS canonico + HTTP opcional e pipeline de bloqueio de bypass.
3. `Refactor`: rerodar `make eval-integrations` para confirmar integridade.

**Criterios de aceitacao**
- Given matriz ou pipeline anti-bypass ausente, When `make eval-integrations` roda, Then o gate falha.
- Given matriz e pipeline completos, When `make eval-integrations` roda, Then retorna `PASS`.

### ISSUE-F4-03-03 - Consolidar evidencia de fase e decisao promote hold
**User story**  
Como operador, quero artifact unico da fase para decidir promocao sem lacunas de auditoria.

**Plano TDD**
1. `Red`: manter evidencias dispersas sem resumo unico de fase.
2. `Green`: consolidar evidencias em artifact unico com decisao `promote|hold`.
3. `Refactor`: validar links do artifact com `make ci-quality`.

**Criterios de aceitacao**
- Given evidencias nao consolidadas, When revisao de fase ocorre, Then a promocao fica bloqueada.
- Given artifact unico com resultado de gate e decisao final, When revisao de fase ocorre, Then a fase fica apta a promover conforme criterio formal.

## Artifact Minimo do Epico
- `artifacts/phase-f4/validation-summary.md` com:
  - status de `make eval-integrations`;
  - status dos epicos `EPIC-F4-01..EPIC-F4-03`;
  - decisao de fase (`promote|hold`) e justificativa.

## Resultado desta Rodada
- `make eval-integrations` final: `PASS` (`eval-integrations: PASS`).
- `make ci-quality` final: `PASS` (`quality-check: PASS`).
- evidencias por issue publicadas:
  - `artifacts/phase-f4/epic-f4-03-issue-01-openrouter-canonical-rule.md`;
  - `artifacts/phase-f4/epic-f4-03-issue-02-upstream-matrix-anti-bypass.md`;
  - `artifacts/phase-f4/epic-f4-03-issue-03-phase-evidence-promote-hold.md`.
- evidencia consolidada do epico:
  - `artifacts/phase-f4/epic-f4-03-coerencia-normativa-gate.md`.
- evidencia consolidada da fase:
  - `artifacts/phase-f4/validation-summary.md`.
- conclusao: `EPIC-F4-03` concluido no escopo documental/tdd desta rodada.

## Dependencias
- [README](../../../README.md)
- [Roadmap](../../../PRD/ROADMAP.md)
- [PRD Master](../../../PRD/PRD-MASTER.md)
- [ARC Core](../../../ARC/ARC-CORE.md)
- [ARC Model Routing](../../../ARC/ARC-MODEL-ROUTING.md)
- [Security Policy](../../../SEC/SEC-POLICY.md)
- [Providers Allowlist](../../../SEC/allowlists/PROVIDERS.yaml)
- [Integrations OpenClaw Upstream](../../../INTEGRATIONS/OPENCLAW-UPSTREAM.md)
- [Trading PRD](../../../VERTICALS/TRADING/TRADING-PRD.md)
- [Trading Enablement Criteria](../../../VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md)
- [Eval Integrations Script](../../../scripts/ci/eval_integrations.sh)
