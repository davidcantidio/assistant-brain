---
doc_id: "EPIC-F8-04-EXPANSAO-MULTIATIVOS-ENABLEMENT.md"
version: "1.2"
status: "active"
owner: "PM"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-010", "RFC-040", "RFC-050", "RFC-060"]
---

# EPIC-F8-04 Expansao multiativos por enablement

## Objetivo
Concluir backlog multiativos com enablement por classe, mantendo gating hard-risk e decisao formal antes de qualquer live por novo ativo.

## Resultado de Negocio Mensuravel
- novas classes de ativo so entram em live com schema, adapter, validator e eval especificos.
- promocao por classe fica bloqueada sem `shadow_mode` e decisao `R3`.

## Cobertura ROADMAP
- `B2-01`, `B2-02`, `B2-03`, `B2-04`, `B2-05`.

## Source refs (felix)
- `felixcraft.md`: trust ladder e aprovacao proporcional ao risco para acoes de maior impacto.
- `felix-openclaw-pontos-relevantes.md`: expansao gradual com mitigacao de risco e aumento progressivo de autonomia.

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- suites `eval-trading-<asset_class>` em `PASS` para classes habilitadas.
- decisao formal `R3` registrada por classe promovida.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F8-04-01 - Validar schema asset_profile e adapters de venue por classe
**User story**
Como operador, quero contrato de classe de ativo e adapter especifico para evitar live sem requisitos basicos de execucao.

**Metadata da issue**
- **Owner**: `tech-lead-trading`
- **Estimativa**: `0.5d`
- **Dependencias**: `VERTICALS/TRADING/asset_profiles/*.json`, `VERTICALS/TRADING/validator_profiles/*.json`, `VERTICALS/TRADING/venue_adapters/*.json`, `scripts/ci/check_phase_f8_multiasset_contracts.sh`, `artifacts/trading/shadow_mode/SHADOW-F8-04-*.json`, `PM/DECISION-PROTOCOL.md`
- **Mapped requirements**: `R10`
- **Prioridade**: `P1`
- **Checklist QA/Repro**:
  1. rodar `make phase-f8-multiasset-contracts`;
  2. validar cobertura das 3 classes obrigatorias em `asset_profiles` e `venue_adapters`;
  3. validar `execution_path=execution_gateway_only` e `decision_r3_required_for_live=true` nos adapters;
  4. validar links de evidência no report consolidado do epic.
- **Evidence refs**: `VERTICALS/TRADING/asset_profiles/equities_br.json`, `VERTICALS/TRADING/asset_profiles/fii_br.json`, `VERTICALS/TRADING/asset_profiles/fixed_income_br.json`, `scripts/ci/check_phase_f8_multiasset_contracts.sh`

**Plano TDD**
1. `Red`: habilitar classe sem schema `asset_profile` ou sem adapter dedicado.
2. `Green`: exigir schema e adapter por classe com bloqueio de bypass.
3. `Refactor`: consolidar matriz de classes suportadas.

**Criterios de aceitacao**
- Given classe sem schema/adapter, When gate roda, Then resultado deve ser `FAIL`.
- Given classe com schema/adapter validos, When gate roda, Then resultado deve ser `PASS`.

### ISSUE-F8-04-02 - Validar pre_trade_validator extendido e eval-trading por classe
**User story**
Como operador, quero validator e suite por classe para impedir ativacao live sem hard-risk bloqueante.

**Metadata da issue**
- **Owner**: `tech-lead-trading`
- **Estimativa**: `0.5d`
- **Dependencias**: `VERTICALS/TRADING/asset_profiles/*.json`, `VERTICALS/TRADING/validator_profiles/*.json`, `VERTICALS/TRADING/venue_adapters/*.json`, `scripts/ci/check_phase_f8_multiasset_contracts.sh`, `artifacts/trading/shadow_mode/SHADOW-F8-04-*.json`, `PM/DECISION-PROTOCOL.md`
- **Mapped requirements**: `R11`
- **Prioridade**: `P1`
- **Checklist QA/Repro**:
  1. rodar `make eval-trading-multiasset`;
  2. validar `eval_suite_ref` por classe no shadow review;
  3. validar profiles de validator por classe;
  4. validar que classes sem cobertura completa permanecem bloqueadas.
- **Evidence refs**: `scripts/ci/phase_f8_multiasset_enablement.py`, `scripts/ci/fixtures/trading/multiasset/shadow/pass_equities_br.json`, `scripts/ci/fixtures/trading/multiasset/shadow/pass_fii_br.json`, `scripts/ci/fixtures/trading/multiasset/shadow/pass_fixed_income_br.json`

**Plano TDD**
1. `Red`: operar classe sem regras de calendario/lote/tick/notional/custo.
2. `Green`: exigir validator estendido + suite `eval-trading-<asset_class>`.
3. `Refactor`: padronizar cobertura de cenario bloqueante por classe.

**Criterios de aceitacao**
- Given validator/suite incompletos, When gate roda, Then resultado deve ser `FAIL`.
- Given validator/suite completos, When gate roda, Then resultado deve ser `PASS`.

### ISSUE-F8-04-03 - Validar shadow_mode e criterio de promote por classe com decisao R3
**User story**
Como operador, quero fase de shadow e decisao `R3` por classe para evitar promocao sem historico minimo.

**Metadata da issue**
- **Owner**: `product-owner + tech-lead-trading`
- **Estimativa**: `1d`
- **Dependencias**: `VERTICALS/TRADING/asset_profiles/*.json`, `VERTICALS/TRADING/validator_profiles/*.json`, `VERTICALS/TRADING/venue_adapters/*.json`, `scripts/ci/check_phase_f8_multiasset_enablement.sh`, `artifacts/trading/shadow_mode/SHADOW-F8-04-*.json`, `PM/DECISION-PROTOCOL.md`
- **Mapped requirements**: `R12`, `R7`
- **Prioridade**: `P0`
- **Checklist QA/Repro**:
  1. validar regra por status: `pending_shadow` vs `completed`;
  2. validar `decision_ref` obrigatorio para `completed` e aderência com `decision.schema.json`;
  3. validar `shadow_evidence_refs` nao vazio para `completed`;
  4. rodar `make phase-f8-multiasset-enablement` com cenarios positivo e negativos.
- **Evidence refs**: `scripts/ci/phase_f8_multiasset_enablement.py`, `ARC/schemas/shadow_mode_review.schema.json`, `ARC/schemas/decision.schema.json`, `artifacts/phase-f8/epic-f8-04-issue-03-shadow-r3-promote-hold.md`

**Plano TDD**
1. `Red`: promover classe sem `shadow_mode` e sem decisao `R3`.
2. `Green`: exigir historico de shadow + decisao `R3` para promote live.
3. `Refactor`: consolidar checklist de promote por classe.

**Criterios de aceitacao**
- Given classe sem shadow ou sem `R3`, When revisao ocorre, Then resultado deve ser `hold`.
- Given classe com shadow validado e decisao `R3`, When revisao ocorre, Then criterio de promote fica `pass`.

## Artifact Minimo do Epico
- registrar em `artifacts/phase-f8/epic-f8-04-multiasset-enablement.md`:
  - classes revisadas;
  - status de schema/adapter/validator/suite;
  - status de shadow_mode e decisao `R3`;
  - referencias `B*` cobertas.

## Resultado desta Rodada
- `make phase-f8-multiasset-contracts` final: `PASS`.
- `make eval-trading-multiasset` final: `PASS`.
- `make phase-f8-multiasset-enablement` final: `PASS`.
- evidencias por issue publicadas:
  - `artifacts/phase-f8/epic-f8-04-issue-01-asset-profile-venue-adapters.md`;
  - `artifacts/phase-f8/epic-f8-04-issue-02-validator-evals-by-class.md`;
  - `artifacts/phase-f8/epic-f8-04-issue-03-shadow-r3-promote-hold.md`.
- evidencias consolidadas:
  - `artifacts/phase-f8/epic-f8-04-multiasset-enablement.md`;
  - `artifacts/trading/shadow_mode/SHADOW-F8-04-EQUITIES-BR-20260301-01.json`;
  - `artifacts/trading/shadow_mode/SHADOW-F8-04-FII-BR-20260301-01.json`;
  - `artifacts/trading/shadow_mode/SHADOW-F8-04-FIXED-INCOME-BR-20260301-01.json`.
- promote readiness por classe:
  - `equities_br`: `hold`
  - `fii_br`: `hold`
  - `fixed_income_br`: `hold`
- conclusao:
  - `EPIC-F8-04` concluido no escopo documental/tdd desta rodada.
  - nenhuma classe multiativos foi promovida para live.
  - `shadow_mode` e decision `R3` permanecem obrigatorios antes de qualquer promote.

## Dependencias
- [Roadmap](../../../../PRD/ROADMAP.md)
- [Trading Enablement Criteria](../../../../VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md)
- [Trading Risk Rules](../../../../VERTICALS/TRADING/TRADING-RISK-RULES.md)
- [Decision Protocol](../../../../PM/DECISION-PROTOCOL.md)
