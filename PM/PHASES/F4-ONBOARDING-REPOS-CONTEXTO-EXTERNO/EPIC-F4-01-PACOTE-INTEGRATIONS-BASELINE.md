---
doc_id: "EPIC-F4-01-PACOTE-INTEGRATIONS-BASELINE.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-02-24"
rfc_refs: ["RFC-001", "RFC-015", "RFC-030", "RFC-040", "RFC-050", "RFC-060"]
---

# EPIC-F4-01 Pacote INTEGRATIONS baseline

## Objetivo
Garantir que o pacote documental de integracoes esteja completo e aplicavel como contrato unico de onboarding de contexto externo.

## Resultado de Negocio Mensuravel
- operador consegue identificar rapidamente o modo permitido por integracao sem depender de interpretacao ad hoc.
- bloqueio de integracao incompleta ocorre antes de promover fase.

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- `make eval-integrations` executado com sucesso.
- evidencia de conformidade do pacote `INTEGRATIONS/` registrada no artifact do epico.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F4-01-01 - Validar presenca dos docs obrigatorios em INTEGRATIONS
**User story**  
Como operador, quero garantir que todos os documentos obrigatorios de integracao existam para evitar onboarding incompleto.

**Plano TDD**
1. `Red`: simular ausencia de doc obrigatorio e executar `make eval-integrations`.
2. `Green`: restaurar todos os docs obrigatorios em `INTEGRATIONS/`.
3. `Refactor`: rerodar `make eval-integrations` para validar estabilidade.

**Criterios de aceitacao**
- Given doc obrigatorio ausente, When `make eval-integrations` roda, Then o gate falha com indicacao do arquivo faltante.
- Given pacote documental completo, When `make eval-integrations` roda, Then nao ha falha por ausencia de doc obrigatorio.

### ISSUE-F4-01-02 - Validar regra mandataria AI-Trader signal_intent only
**User story**  
Como operador, quero garantir que AI-Trader opere apenas como sinal para impedir bypass de execucao financeira.

**Plano TDD**
1. `Red`: remover regra de `signal_intent` only ou permitir ordem direta e executar `make eval-integrations`.
2. `Green`: restaurar regras obrigatorias de bloqueio e auditoria para ordem direta originada de AI-Trader.
3. `Refactor`: rerodar `make eval-integrations` e registrar evidencia.

**Criterios de aceitacao**
- Given regra mandataria ausente ou ambigua, When `make eval-integrations` roda, Then o gate falha.
- Given regras `signal_intent` only e anti-bypass explicitas, When `make eval-integrations` roda, Then retorna `PASS`.

### ISSUE-F4-01-03 - Validar regra mandataria ClawWork lab_isolated governed gateway-only
**User story**  
Como operador, quero validar modos de operacao do ClawWork para manter governanca de chamada externa.

**Plano TDD**
1. `Red`: remover regra de default `lab_isolated` ou permitir chamada direta em modo `governed`.
2. `Green`: restaurar regra de `lab_isolated` default, `governed` via gateway-only e bloqueio de chamada direta.
3. `Refactor`: rerodar `make eval-integrations` para confirmar conformidade.

**Criterios de aceitacao**
- Given default/modo governed fora do contrato, When `make eval-integrations` roda, Then o gate falha.
- Given contrato ClawWork completo com politica E2B explicita, When `make eval-integrations` roda, Then retorna `PASS`.

## Artifact Minimo do Epico
- registrar resumo em `artifacts/phase-f4/epic-f4-01-integrations-baseline.md` com:
  - status dos docs obrigatorios de integracao;
  - status de regras AI-Trader e ClawWork;
  - resultado final de `make eval-integrations`.

## Dependencias
- [Integrations Readme](../../../INTEGRATIONS/README.md)
- [Integration AI-Trader](../../../INTEGRATIONS/AI-TRADER.md)
- [Integration ClawWork](../../../INTEGRATIONS/CLAWWORK.md)
- [Integration OpenClaw Upstream](../../../INTEGRATIONS/OPENCLAW-UPSTREAM.md)
- [Eval Integrations Script](../../../scripts/ci/eval_integrations.sh)
