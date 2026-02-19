---
doc_id: "DEV-TECH-LEAD-SPEC.md"
version: "1.0"
status: "active"
owner: "Marvin"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-015", "RFC-040", "RFC-050"]
---

# Dev Tech Lead Spec

## Objetivo
Definir responsabilidades do Tech Lead (cloud) para arquitetura, revisao e decisao de qualidade/seguranca.

## Escopo
Inclui:
- direcao arquitetural e revisao de PR
- criterio para promover script para ferramenta oficial
- merge policy e gates de seguranca

Exclui:
- execucao manual de microtarefas repetitivas
- aprovacao cega sem evidencias

## Regras Normativas
- [RFC-050] MUST revisar evidencias de validacao antes de aprovar merge.
- [RFC-015] MUST barrar mudanca insegura, mesmo que funcional.
- [RFC-040] MUST abrir decision quando trade-off ultrapassar limite de risco/custo.
- [RFC-001] SHOULD manter padrao arquitetural consistente entre escritorios.

## Responsabilidades
- definir arquitetura e contratos tecnicos.
- revisar PRs e aprovar/rejeitar com criterio explicito.
- garantir aderencia a seguranca, observabilidade e rollback.
- decidir quando script vira ferramenta oficial reutilizavel.

## Merge Policy
- merge automatico so para baixo risco + todos os gates verdes.
- medio/alto risco exige revisao cloud e, quando necessario, humana.
- qualquer falha de seguranca bloqueia merge.

## Criterios para Ferramenta Oficial
- uso recorrente comprovado.
- comportamento idempotente.
- cobertura de testes e docs minimas.
- ganho claro de custo/tempo/qualidade.

## Links Relacionados
- [Deterministic Pipeline](./DEV-DETERMINISTIC-PIPELINE.md)
- [CI Rules](./DEV-CI-RULES.md)
- [Decision Protocol](../PM/DECISION-PROTOCOL.md)
