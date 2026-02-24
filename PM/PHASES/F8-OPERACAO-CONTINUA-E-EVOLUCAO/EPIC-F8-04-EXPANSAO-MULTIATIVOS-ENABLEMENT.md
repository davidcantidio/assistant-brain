---
doc_id: "EPIC-F8-04-EXPANSAO-MULTIATIVOS-ENABLEMENT.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-02-24"
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

## Dependencias
- [Roadmap](../../../PRD/ROADMAP.md)
- [Trading Enablement Criteria](../../../VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md)
- [Trading Risk Rules](../../../VERTICALS/TRADING/TRADING-RISK-RULES.md)
- [Decision Protocol](../../../PM/DECISION-PROTOCOL.md)
