---
doc_id: "EPIC-F7-02-S1-MICRO-LIVE-PRE-LIVE-CHECKLIST.md"
version: "1.2"
status: "done"
owner: "PM"
last_updated: "2026-03-01"
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
- `pre_live_checklist` validado e refletindo o estado real dos itens.
- `promote/live-enablement` exige checklist sem `fail`, mas o epico pode ser concluido documentalmente com decisao `hold`.
- evidencias de prontidao `S1` registradas no artifact do epico.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F7-02-01 - Validar contrato do pre_live_checklist com campos obrigatorios e items[]
**User story**  
Como operador, quero checklist pre-live com contrato minimo obrigatorio, contendo `checklist_id`, `decision_id`, `risk_tier`, `asset_class`, `capital_ramp_level`, `operator_id`, `approved_at` e `items[]`, para evitar decisao subjetiva de habilitacao.

**Metadata da issue**
- **Owner**: `tech-lead-trading`
- **Estimativa**: `1d`
- **Dependencias**: `VERTICALS/TRADING/TRADING-PRD.md`, `PRD/PRD-MASTER.md`, `assistant-brain/artifacts/trading/pre_live_checklist/CHECKLIST-F7-02-S1-20260301-01.json`
- **Mapped requirements**: `R7`, `R9`
- **Prioridade**: `P1`
- **Checklist QA/Repro**:
  1. validar que o checklist canonico contem `checklist_id`, `decision_id`, `risk_tier`, `asset_class`, `capital_ramp_level`, `operator_id`, `approved_at` e `items[]`;
  2. validar que os 8 itens minimos obrigatorios estao presentes no checklist;
  3. rodar `make eval-trading` e confirmar que contrato incompleto reprova e contrato completo passa.
- **Evidence refs**: `assistant-brain/VERTICALS/TRADING/TRADING-PRD.md:171-182`, `assistant-brain/artifacts/trading/pre_live_checklist/CHECKLIST-F7-02-S1-20260301-01.json`

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

**Metadata da issue**
- **Owner**: `tech-lead-trading`
- **Estimativa**: `1d`
- **Dependencias**: `assistant-brain/artifacts/trading/pre_live_checklist/CHECKLIST-F7-02-S1-20260301-01.json`, `ARC/schemas/pre_trade_validator.schema.json`, `scripts/ci/eval_trading.sh`
- **Mapped requirements**: `R2`, `R8`, `R9`
- **Prioridade**: `P1`
- **Checklist QA/Repro**:
  1. validar que o checklist versionado registra `capital_ramp_level=L0`;
  2. validar que `execution_gateway_only=pass` e `pre_trade_validator_active=pass` estao ancorados no checklist JSON;
  3. validar que o contrato versionado do `pre_trade_validator` permanece referenciado;
  4. rodar `make eval-trading` e confirmar `PASS`.
- **Evidence refs**: `assistant-brain/VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md:138-149`, `assistant-brain/ARC/schemas/pre_trade_validator.schema.json`

**Plano TDD**
1. `Red`: simular entrada em `S1` sem `L0` ou sem enforcement de gateway/validator.
2. `Green`: aplicar `capital_ramp_level=L0`, `execution_gateway_only` e `pre_trade_validator_active`.
3. `Refactor`: rerodar `make eval-trading` para confirmar conformidade dos guardrails.

**Criterios de aceitacao**
- Given guardrail critico ausente em `S1`, When `make eval-trading` roda, Then gate deve falhar.
- Given guardrails ativos e alinhados, When `make eval-trading` roda, Then valida trading com `PASS`.

### ISSUE-F7-02-03 - Validar matriz minima do checklist S1 e manter hold enquanto houver item fail
**User story**  
Como operador, quero validar a matriz minima completa do checklist de `S1` para impedir habilitacao sem seguranca operacional minima e manter aprovacao humana por ordem como requisito obrigatorio.

**Metadata da issue**
- **Owner**: `security-lead + product-owner`
- **Estimativa**: `2d`
- **Dependencias**: `assistant-brain/artifacts/trading/pre_live_checklist/CHECKLIST-F7-02-S1-20260301-01.json`, `PM/DECISION-PROTOCOL.md`, `SEC/allowlists/OPERATORS.yaml`
- **Mapped requirements**: `R3`, `R9`, `R13`
- **Prioridade**: `P0`
- **Checklist QA/Repro**:
  1. validar no checklist canonico os 8 itens minimos: `eval_trading_green`, `execution_gateway_only`, `pre_trade_validator_active`, `credentials_live_no_withdraw`, `hitl_channel_ready`, `degraded_mode_runbook_ok`, `backup_operator_enabled`, `explicit_order_approval_active`;
  2. confirmar que 4 itens estao `pass` e 4 itens permanecem `fail`, com `degraded_mode_runbook_ok=pass`;
  3. validar que qualquer item `fail` mantem `TRADING_BLOCKED` e decisao `hold`;
  4. validar que remocao de `TRADING_BLOCKED` so pode ocorrer por decisao formal registrada e que aprovacao humana por ordem permanece mandatória em `S1`.
- **Evidence refs**: `assistant-brain/VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md:138-149`, `assistant-brain/PM/DECISION-PROTOCOL.md:197-204`

**Plano TDD**
1. `Red`: manter pelo menos um item obrigatorio como `fail` no checklist.
2. `Green`: validar a matriz completa de 8 itens com estado real preservado.
3. `Refactor`: consolidar evidencias no artifact do epico e confirmar no checklist final sem mascarar os `fail`.

**Criterios de aceitacao**
- Given a matriz minima de 8 itens do checklist, When o estado real for revisado, Then 4 itens ficam `pass` (`eval_trading_green`, `execution_gateway_only`, `pre_trade_validator_active`, `degraded_mode_runbook_ok`) e 4 itens permanecem `fail` (`credentials_live_no_withdraw`, `hitl_channel_ready`, `backup_operator_enabled`, `explicit_order_approval_active`).
- Given qualquer item `fail`, When checklist e revisado, Then resultado deve ser `hold` e `TRADING_BLOCKED` MUST permanecer ativo.
- Given tentativa de remover `TRADING_BLOCKED` sem decisao formal registrada, When readiness de `S1` e revisado, Then a remocao deve ser negada.
- Given `S1` em operacao assistida, When ordem for avaliada, Then aprovacao humana por ordem permanece mandatória.

## Artifact Minimo do Epico
- registrar resumo em `artifacts/phase-f7/epic-f7-02-s1-readiness.md` com:
  - status do `pre_live_checklist`;
  - status dos guardrails de `S1`;
  - resultado de `make eval-trading`.
- referenciar `artifacts/trading/pre_live_checklist/CHECKLIST-F7-02-S1-20260301-01.json`.

## Resultado desta Rodada
- `make eval-trading` final: `PASS` (`eval-trading: PASS`).
- `make ci-quality` final: `PASS` (`quality-check: PASS`).
- `make ci-security` final: `PASS` (`security-check: PASS`).
- evidencias por issue publicadas:
  - `artifacts/phase-f7/epic-f7-02-issue-01-pre-live-checklist-contract.md`;
  - `artifacts/phase-f7/epic-f7-02-issue-02-s1-guardrails-l0-gateway-validator.md`;
  - `artifacts/phase-f7/epic-f7-02-issue-03-s1-critical-items-hold.md`.
- evidencia consolidada:
  - `artifacts/phase-f7/epic-f7-02-s1-readiness.md`.
- decisao final no escopo do epic: `hold`.
- matriz minima do checklist validada com 8 itens: 4 `pass` e 4 `fail`.
- justificativa: itens criticos de readiness live permanecem `fail` no `pre_live_checklist` (`credentials_live_no_withdraw`, `hitl_channel_ready`, `backup_operator_enabled`, `explicit_order_approval_active`).
- conclusao: `EPIC-F7-02` concluido no escopo documental/tdd desta rodada, sem liberacao de live.

## Dependencias
- [Trading Enablement Criteria](../../../../VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md)
- [Trading Risk Rules](../../../../VERTICALS/TRADING/TRADING-RISK-RULES.md)
- [Security Policy](../../../../SEC/SEC-POLICY.md)
- [Operators Allowlist](../../../../SEC/allowlists/OPERATORS.yaml)
