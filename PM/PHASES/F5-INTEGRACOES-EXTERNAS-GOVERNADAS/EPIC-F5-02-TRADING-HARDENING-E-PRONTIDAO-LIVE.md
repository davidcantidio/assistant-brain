---
doc_id: "EPIC-F5-02-TRADING-HARDENING-E-PRONTIDAO-LIVE.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-02-24"
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
- `make eval-trading` em `PASS`.
- evidencia unica de hardening live consolidada.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F5-02-01 - Validar pre_trade_validator por simbolo e contratos execution_gateway versionados
**User story**
Como operador, quero contratos versionados e validator ativo por simbolo para impedir ordem fora de regra.

**Plano TDD**
1. `Red`: executar ordem com validator inativo ou contrato nao versionado.
2. `Green`: exigir `pre_trade_validator` por simbolo e contrato versionado do gateway.
3. `Refactor`: consolidar evidencias no gate de trading.

**Criterios de aceitacao**
- Given validator/contrato ausente, When `make eval-trading` roda, Then resultado deve ser `FAIL`.
- Given validator/contrato ativos e versionados, When `make eval-trading` roda, Then resultado deve ser `PASS`.

### ISSUE-F5-02-02 - Validar idempotencia client_order_id e reconciliacao de falha parcial
**User story**
Como operador, quero idempotencia por ordem para evitar duplicidade de execucao financeira.

**Plano TDD**
1. `Red`: processar replay de `client_order_id` como ordem nova.
2. `Green`: tratar replay como no-op e registrar reconciliacao.
3. `Refactor`: padronizar trilha de auditoria por ordem.

**Criterios de aceitacao**
- Given replay de `client_order_id`, When processamento ocorre, Then nao deve haver nova ordem executada.
- Given falha parcial, When reconciliacao ocorre, Then o estado final deve ser consistente e auditavel.

### ISSUE-F5-02-03 - Validar fail_closed para engine primaria e single_engine_mode para secundaria
**User story**
Como operador, quero degradacao previsivel por tipo de falha de engine para evitar exposicao indevida.

**Plano TDD**
1. `Red`: manter novas entradas ativas apos falha de engine primaria.
2. `Green`: aplicar `fail_closed` na primaria e `single_engine_mode` apenas para falha secundaria.
3. `Refactor`: alinhar regras de degradacao com runbook de trading.

**Criterios de aceitacao**
- Given falha de engine primaria, When avaliacao ocorre, Then novas entradas devem ficar bloqueadas.
- Given falha de engine secundaria com primaria saudavel, When avaliacao ocorre, Then `single_engine_mode` pode ser aplicado sob policy.

### ISSUE-F5-02-04 - Validar credenciais live no-withdraw IP allowlist e gate CI obrigatorio
**User story**
Como operador, quero credenciais minimamente privilegiadas e CI obrigatorio para reduzir risco operacional.

**Plano TDD**
1. `Red`: aceitar credencial sem no-withdraw/IP allowlist quando suportado ou mudanca de trading sem CI.
2. `Green`: exigir credenciais com politica restrita e `make eval-trading` obrigatorio em CI.
3. `Refactor`: consolidar checklist de prontidao live.

**Criterios de aceitacao**
- Given credencial fora de politica ou sem CI obrigatorio, When revisao ocorre, Then resultado deve ser `hold`.
- Given credencial e CI conforme contrato, When revisao ocorre, Then criterio de prontidao fica `pass`.

### ISSUE-F5-02-05 - Validar runbook de degradacao com posicao aberta e TRADING_BLOCKED
**User story**
Como operador, quero runbook seguro para posicao aberta em degradacao sem perda de controle.

**Plano TDD**
1. `Red`: permitir continuidade live com degradacao sem runbook valido.
2. `Green`: exigir `TRADING_BLOCKED`, snapshot de posicao e plano de reconciliacao.
3. `Refactor`: alinhar gatilhos de incidente critico.

**Criterios de aceitacao**
- Given degradacao sem runbook valido, When pre-condicao live e avaliada, Then resultado deve ser `hold`.
- Given runbook valido e evidenciado, When avaliacao ocorre, Then criterio operacional fica `pass`.

## Artifact Minimo do Epico
- registrar em `artifacts/phase-f5/epic-f5-02-trading-hardening.md`:
  - status de validator/contratos;
  - status de idempotencia/reconciliacao;
  - status de fail_closed/single_engine_mode;
  - status de credenciais e CI;
  - referencias `B*` cobertas.

## Dependencias
- [Trading PRD](../../../VERTICALS/TRADING/TRADING-PRD.md)
- [Trading Risk Rules](../../../VERTICALS/TRADING/TRADING-RISK-RULES.md)
- [Decision Protocol](../../../PM/DECISION-PROTOCOL.md)
- [Roadmap](../../../PRD/ROADMAP.md)
- [Felixcraft Architecture](../../../felixcraft.md)
