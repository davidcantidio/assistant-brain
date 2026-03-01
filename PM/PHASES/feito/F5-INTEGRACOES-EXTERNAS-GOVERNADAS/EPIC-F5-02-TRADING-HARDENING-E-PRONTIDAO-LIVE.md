---
doc_id: "EPIC-F5-02-TRADING-HARDENING-E-PRONTIDAO-LIVE.md"
version: "1.2"
status: "done"
owner: "PM"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-010", "RFC-015", "RFC-050", "RFC-060"]
---

# EPIC-F5-02 Trading hardening e prontidao live

## Objetivo
Formalizar hardening de execucao de ordens, degradacao segura, credenciais live e gate CI obrigatorio antes de qualquer aumento de risco.

## Resultado de Negocio Mensuravel
- ordem e reconciliacao operam com idempotencia controlada.
- live permanece bloqueado quando pre-condicoes de credencial/canal/operador nao forem satisfeitas.

## Cobertura ROADMAP
- `B1-05`, `B1-06`, `B1-07`, `B1-08`, `B1-09`, `B1-10`, `B1-12`, `B2-R04`.

## Source refs (felix)
- `felixcraft.md`: trust ladder, approval queue, no money movement without explicit approval.
- `felix-openclaw-pontos-relevantes.md`: remocao incremental de gargalos com mitigacao de risco e controles de contingencia.

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- `make eval-trading` e `make eval-integrations` em `PASS` no mesmo ciclo.
- evidencia unica de hardening live consolidada no artifact do epico e em `artifacts/phase-f5/validation-summary.md`.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F5-02-01 - Validar pre_trade_validator por simbolo e contratos execution_gateway versionados
**Owner** `Tech Lead Trading`
**Estimativa** `1d`
**Dependencias**
- `ARC/schemas/execution_gateway.schema.json`
- `ARC/schemas/pre_trade_validator.schema.json`
- `artifacts/phase-f5/epic-f5-02-issue-01-validator-contracts.md`
**Labels** `prio:high`, `risk:trading`, `blocking-release`, `needs-qa`, `needs-owner`
**Definition of Ready**
- contratos de `execution_gateway` e `pre_trade_validator` identificados e versionados.
- limites por simbolo e `capital_ramp_level` alinhados com a classe habilitada.
**Definition of Done**
- `capital_ramp_level` por simbolo aparece explicitamente nos ACs e no QA.
- contratos quebrados ou sem versionamento reprovam o gate.
- artifact registra cenarios por simbolo e por nivel de rampa.
**User story**
Como operador, quero contratos versionados e validator ativo por simbolo para impedir ordem fora de regra.

**Plano TDD**
1. `Red`: executar ordem com validator inativo ou contrato nao versionado.
2. `Green`: exigir `pre_trade_validator` por simbolo e contrato versionado do gateway.
3. `Refactor`: consolidar evidencias no gate de trading.

**Criterios de aceitacao**
- Given `capital_ramp_level` ausente para um simbolo habilitado, When `make eval-trading` roda, Then resultado deve ser `FAIL`.
- Given contrato versionado sem campos obrigatorios de `execution_gateway` ou `pre_trade_validator`, When `make eval-trading` roda, Then resultado deve ser `FAIL`.
- Given simbolo dentro do nivel de rampa permitido e contratos completos, When `make eval-trading` roda, Then resultado deve ser `PASS`.

**Passos QA**
1. Executar validacao negativa com `capital_ramp_level` ausente para um simbolo ativo.
2. Executar validacao negativa com contrato versionado incompleto.
3. Executar validacao positiva por simbolo e anexar evidencias do nivel de rampa no artifact.

### ISSUE-F5-02-02 - Validar idempotencia client_order_id e reconciliacao de falha parcial
**Owner** `Tech Lead Trading`
**Estimativa** `1d`
**Dependencias**
- `VERTICALS/TRADING/TRADING-PRD.md`
- `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`
- `artifacts/phase-f5/epic-f5-02-issue-02-idempotency-reconciliation.md`
**Labels** `prio:p0`, `risk:financial`, `blocking-release`, `needs-qa`, `needs-owner`
**Definition of Ready**
- chaves `client_order_id`, `idempotency_key` e `reconciliation_status` mapeadas no contrato.
- cenario de replay concorrente definido para a mesma ordem.
**Definition of Done**
- replay concorrente e replay sequencial ficam descritos como cenarios distintos.
- reconciliacao determina estado final consistente e auditavel.
- artifact registra os traces de no-op e reconciliacao.
**User story**
Como operador, quero idempotencia por ordem para evitar duplicidade de execucao financeira.

**Plano TDD**
1. `Red`: processar replay de `client_order_id` como ordem nova.
2. `Green`: tratar replay como no-op e registrar reconciliacao.
3. `Refactor`: padronizar trilha de auditoria por ordem.

**Criterios de aceitacao**
- Given duas requisicoes simultaneas com o mesmo `client_order_id`, When o processamento ocorre em paralelo, Then apenas uma execucao financeira pode ser aceita.
- Given falha parcial de execucao, When a reconciliacao ocorre, Then o `reconciliation_status` final deve ser consistente, auditavel e conter `reconciliation_trace_id`.
- Given replay sequencial da mesma ordem, When o processamento ocorre, Then o resultado deve ser `no-op` com trilha auditavel preservada.

**Passos QA**
1. Executar cenario concorrente com duas tentativas simultaneas do mesmo `client_order_id`.
2. Executar cenario de falha parcial e validar o `reconciliation_status` final.
3. Executar replay sequencial e anexar o trace de `no-op` no artifact.

### ISSUE-F5-02-03 - Validar fail_closed para engine primaria e single_engine_mode para secundaria
**Owner** `Tech Lead Trading`
**Estimativa** `1d`
**Dependencias**
- `VERTICALS/TRADING/TRADING-PRD.md`
- `INCIDENTS/DEGRADED-MODE-PROCEDURE.md`
- `artifacts/phase-f5/epic-f5-02-issue-03-fail-closed-single-engine.md`
**Labels** `prio:high`, `risk:trading`, `blocking-release`, `needs-qa`
**Definition of Ready**
- distincao entre engine primaria e secundaria descrita no runbook.
- tempo alvo de bloqueio conhecido para falha da engine primaria.
**Definition of Done**
- falha da engine primaria bloqueia novas entradas de forma mensuravel.
- `single_engine_mode` so aparece para secundaria com primaria saudavel.
- artifact registra os cenarios de degradacao e retorno seguro.
**User story**
Como operador, quero degradacao previsivel por tipo de falha de engine para evitar exposicao indevida.

**Plano TDD**
1. `Red`: manter novas entradas ativas apos falha de engine primaria.
2. `Green`: aplicar `fail_closed` na primaria e `single_engine_mode` apenas para falha secundaria.
3. `Refactor`: alinhar regras de degradacao com runbook de trading.

**Criterios de aceitacao**
- Given falha da engine primaria, When a avaliacao ocorre, Then novas entradas devem ficar bloqueadas em ate `60s` e o estado deve permanecer `TRADING_BLOCKED`.
- Given falha da engine secundaria com primaria saudavel, When a avaliacao ocorre, Then `single_engine_mode` pode ser aplicado sob policy e sem desbloquear bypass de risco.
- Given falha secundaria com primaria nao saudavel, When a avaliacao ocorre, Then resultado deve ser `FAIL` e `single_engine_mode` deve permanecer proibido.

**Passos QA**
1. Simular falha da engine primaria e medir o tempo ate `TRADING_BLOCKED`.
2. Simular falha secundaria com primaria saudavel e validar o modo degradado permitido.
3. Simular falha secundaria com primaria nao saudavel e registrar o bloqueio esperado.

### ISSUE-F5-02-04 - Validar credenciais live no-withdraw IP allowlist e gate CI obrigatorio
**Owner** `Security Lead`
**Estimativa** `1d`
**Dependencias**
- `SEC/allowlists/ACTIONS.yaml`
- `.github/workflows/ci-trading.yml`
- `artifacts/phase-f5/epic-f5-02-issue-04-credentials-ci-gate.md`
**Labels** `prio:p0`, `risk:security`, `compliance-review`, `blocking-release`, `needs-qa`
**Definition of Ready**
- lista de providers live e capacidade de `IP allowlist` conhecida.
- workflow de CI para trading identificado no repositorio.
**Definition of Done**
- evidencia minima por provider fica descrita para `no-withdraw` e `IP allowlist`.
- ausencia de etapa `make eval-trading` no workflow vira bloqueio explicito de merge.
- artifact registra o checklist por provider e por pipeline.
**User story**
Como operador, quero credenciais minimamente privilegiadas e CI obrigatorio para reduzir risco operacional.

**Plano TDD**
1. `Red`: aceitar credencial sem no-withdraw/IP allowlist quando suportado ou mudanca de trading sem CI.
2. `Green`: exigir credenciais com politica restrita e `make eval-trading` obrigatorio em CI.
3. `Refactor`: consolidar checklist de prontidao live.

**Criterios de aceitacao**
- Given credencial com permissao de saque ativa, When a revisao ocorre, Then resultado deve ser `hold`.
- Given provider com suporte a `IP allowlist` sem evidencia minima mascarada do controle aplicado, When a revisao ocorre, Then resultado deve ser `hold`.
- Given workflow de trading sem etapa explicita `make eval-trading`, When a revisao ocorre, Then resultado deve ser `FAIL` e bloquear merge.

**Passos QA**
1. Revisar o checklist por provider para `no-withdraw` e `IP allowlist`.
2. Validar o workflow `.github/workflows/ci-trading.yml` com etapa explicita de gate.
3. Anexar no artifact as evidencias mascaradas por provider e o resultado do pipeline.

### ISSUE-F5-02-05 - Validar runbook de degradacao com posicao aberta e TRADING_BLOCKED
**Owner** `Ops Lead`
**Estimativa** `1d`
**Dependencias**
- `ARC/ARC-DEGRADED-MODE.md`
- `INCIDENTS/DEGRADED-MODE-PROCEDURE.md`
- `artifacts/phase-f5/epic-f5-02-issue-05-degraded-open-position-runbook.md`
**Labels** `prio:high`, `risk:operations`, `blocking-release`, `needs-qa`
**Definition of Ready**
- gatilhos de `TRADING_BLOCKED`, snapshot e reconciliacao mapeados no runbook.
- criterio de retorno seguro definido para reabrir operacao.
**Definition of Done**
- ausencia de runbook ou de snapshot bloqueia prontidao live.
- retorno seguro depende de reconciliacao e checklist completo.
- artifact registra bloqueio, snapshots e autorizacao de retorno.
**User story**
Como operador, quero runbook seguro para posicao aberta em degradacao sem perda de controle.

**Plano TDD**
1. `Red`: permitir continuidade live com degradacao sem runbook valido.
2. `Green`: exigir `TRADING_BLOCKED`, snapshot de posicao e plano de reconciliacao.
3. `Refactor`: alinhar gatilhos de incidente critico.

**Criterios de aceitacao**
- Given degradacao com posicao aberta e sem runbook valido, When a pre-condicao live e avaliada, Then resultado deve ser `hold`.
- Given degradacao com snapshots ausentes, When a pre-condicao live e avaliada, Then resultado deve ser `hold`.
- Given reconciliacao concluida, snapshots preservados e checklist de retorno seguro completo, When a avaliacao ocorre, Then criterio operacional deve ficar `PASS`.

**Passos QA**
1. Simular degradacao com posicao aberta e ausencia de runbook.
2. Simular degradacao com snapshot ausente.
3. Validar a trilha de reconciliacao e a autorizacao de retorno seguro no artifact.

## Artifact Minimo do Epico
- registrar em `artifacts/phase-f5/epic-f5-02-trading-hardening.md`:
  - status de validator/contratos;
  - status de idempotencia/reconciliacao;
  - status de fail_closed/single_engine_mode;
  - status de credenciais e CI;
  - referencias `B*` cobertas;
  - referencia cruzada para `artifacts/phase-f5/validation-summary.md`.

## Resultado desta Rodada
- `make eval-trading` final: registrar em `artifacts/phase-f5/validation-summary.md`.
- `make eval-integrations` final: registrar em `artifacts/phase-f5/validation-summary.md`.
- `make ci-quality` final: sem regressao documental esperada para os markdowns da F5.
- evidencias por issue publicadas:
  - `artifacts/phase-f5/epic-f5-02-issue-01-validator-contracts.md`;
  - `artifacts/phase-f5/epic-f5-02-issue-02-idempotency-reconciliation.md`;
  - `artifacts/phase-f5/epic-f5-02-issue-03-fail-closed-single-engine.md`;
  - `artifacts/phase-f5/epic-f5-02-issue-04-credentials-ci-gate.md`;
  - `artifacts/phase-f5/epic-f5-02-issue-05-degraded-open-position-runbook.md`.
- evidencia consolidada do epico:
  - `artifacts/phase-f5/epic-f5-02-trading-hardening.md`.
- conclusao: `EPIC-F5-02` corrigido para atender a auditoria documental da F5.

## Dependencias
- [Trading PRD](../../../../VERTICALS/TRADING/TRADING-PRD.md)
- [Trading Risk Rules](../../../../VERTICALS/TRADING/TRADING-RISK-RULES.md)
- [Decision Protocol](../../../../PM/DECISION-PROTOCOL.md)
- [Roadmap](../../../../PRD/ROADMAP.md)
- [Felixcraft Architecture](../../../../felixcraft.md)
