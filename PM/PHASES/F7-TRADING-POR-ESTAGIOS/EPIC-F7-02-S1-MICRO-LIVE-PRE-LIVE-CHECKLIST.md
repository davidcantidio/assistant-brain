---
doc_id: "EPIC-F7-02-S1-MICRO-LIVE-PRE-LIVE-CHECKLIST.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-02-24"
rfc_refs: ["RFC-001", "RFC-010", "RFC-050", "RFC-060"]
---

# EPIC-F7-02 S1 micro-live pre-live checklist

## Objetivo
Fechar prontidao de `S1 - Micro-live` com checklist contratual e guardrails hard-risk, mantendo desbloqueio condicionado a evidencias formais.

## Resultado de Negocio Mensuravel
- entrada em `S1` ocorre com risco inicial controlado e checklist verificavel.
- equipe reduz risco de live prematuro sem pre-condicoes criticas.

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- `make eval-trading` executado com sucesso.
- `pre_live_checklist` validado sem item `fail`.
- evidencias de prontidao `S1` registradas no artifact do epico.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F7-02-01 - Validar contrato do pre_live_checklist com campos obrigatorios e items[]
**User story**  
Como operador, quero checklist pre-live com contrato minimo obrigatorio para evitar decisao subjetiva de habilitacao.

**Plano TDD**
1. `Red`: usar checklist sem campos obrigatorios ou sem `items[]`.
2. `Green`: preencher checklist com todos os campos obrigatorios do contrato.
3. `Refactor`: revisar consistencia entre checklist e criterios de enablement.

**Criterios de aceitacao**
- Given checklist sem campos obrigatorios, When revisao de pre-live ocorre, Then resultado deve ser `hold`.
- Given checklist completo com `items[]` validos, When revisao de pre-live ocorre, Then item contratual fica `pass`.

### ISSUE-F7-02-02 - Validar guardrails de entrada em S1 capital_ramp_level L0 execution_gateway_only pre_trade_validator_active
**User story**  
Como operador, quero guardrails de entrada em `S1` para evitar exposicao acima do nivel aprovado.

**Plano TDD**
1. `Red`: simular entrada em `S1` sem `L0` ou sem enforcement de gateway/validator.
2. `Green`: aplicar `capital_ramp_level=L0`, `execution_gateway_only` e `pre_trade_validator_active`.
3. `Refactor`: rerodar `make eval-trading` para confirmar conformidade dos guardrails.

**Criterios de aceitacao**
- Given guardrail critico ausente em `S1`, When `make eval-trading` roda, Then gate deve falhar.
- Given guardrails ativos e alinhados, When `make eval-trading` roda, Then valida trading com `PASS`.

### ISSUE-F7-02-03 - Validar itens criticos credentials_live_no_withdraw hitl_channel_ready backup_operator_enabled explicit_order_approval_active
**User story**  
Como operador, quero validar os itens criticos de operacao live para impedir habilitacao sem seguranca operacional minima.

**Plano TDD**
1. `Red`: manter pelo menos um item critico como `fail` no checklist.
2. `Green`: ajustar todos os itens criticos para `pass` com evidencia vinculada.
3. `Refactor`: consolidar evidencias no artifact do epico e confirmar no checklist final.

**Criterios de aceitacao**
- Given qualquer item critico com `fail`, When checklist e revisado, Then resultado deve ser `hold`.
- Given todos os itens criticos com `pass` e evidencias, When checklist e revisado, Then fase fica apta para decisao de `S1`.

## Artifact Minimo do Epico
- registrar resumo em `artifacts/phase-f7/epic-f7-02-s1-readiness.md` com:
  - status do `pre_live_checklist`;
  - status dos guardrails de `S1`;
  - resultado de `make eval-trading`.
- referenciar `artifacts/trading/pre_live_checklist/<checklist_id>.json`.

## Dependencias
- [Trading Enablement Criteria](../../../VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md)
- [Trading Risk Rules](../../../VERTICALS/TRADING/TRADING-RISK-RULES.md)
- [Security Policy](../../../SEC/SEC-POLICY.md)
- [Operators Allowlist](../../../SEC/allowlists/OPERATORS.yaml)
