---
doc_id: "SYSTEM-HEALTH-THRESHOLDS.md"
version: "1.4"
status: "active"
owner: "Frederisk"
last_updated: "2026-02-24"
rfc_refs: ["RFC-001", "RFC-030", "RFC-050"]
---

# System Health Thresholds

## Objetivo
Definir limites operacionais de custo, latencia, confiabilidade, fallback, privacidade e incidentes com acao automatica padronizada.

## Escopo
Inclui:
- thresholds de saude do sistema
- acoes automaticas em violacao
- criterios de escalation para decision
- contrato executavel de idempotencia/rollback para auto-acoes

Exclui:
- tuning manual sem registro
- ignorar alerta recorrente

## Regras Normativas
- [RFC-050] MUST monitorar thresholds continuamente.
- [RFC-050] MUST abrir task automatica em violacao.
- [RFC-030] MUST ajustar model routing ao detectar degradacao.
- [RFC-001] MUST abrir decision se violacao persistir apos mitigacao.
- [RFC-050] MUST aplicar anti-storm controls antes de abrir task/decision em massa.
- [RFC-050] MUST bloquear release quando claim central nao tiver eval gate ativo.
- [RFC-050] MUST aplicar efeito colateral automatico somente com `automation_action_id` idempotente.

## Thresholds
| Categoria | Threshold inicial | Acao |
|---|---|---|
| Custo diario | > 90% teto | fallback agressivo + decision de budget |
| Burn-rate horario | > 130% baseline | reduzir carga + bloquear nao critico |
| Latencia p95 | > 2x SLA por 30 min | task de tuning + reducao de carga |
| Falha de tarefa | > 10% em 1h | circuit breaker por classe |
| Fallback em cascata | > 3 por tarefa | escalar cloud/humano |
| Parse rate (structured) | < 98% em janela | bloquear rota + abrir tuning |
| Tool success rate (tools) | < 95% em janela | trocar preset/provider e abrir decision |
| Worker local sem capacidade | `context_fit=false` ou `latency_p95` acima do limite por task_type | escalar para supervisor pago + registrar fallback |
| Incidente critico | >= 1 | ativar degraded mode e checklist incidente |

## Calibragem por Fase
- Fase 0 (aquecimento, 2-4 semanas):
  - thresholds mais tolerantes para reduzir falso positivo.
  - ajustar semanalmente por baseline real.
- Fase 1+:
  - reduzir tolerancia gradualmente por classe critica.
  - bloquear regressao repetida com gate automatico.

## Anti-Storm Controls (obrigatorio)
- `debounce_window`: 10 minutos por sinal.
- `cooldown_window`: 30 minutos apos acao automatica.
- `coalescing_key`: agrupar alertas por classe+causa.
- `max_auto_tasks_per_hour`: 6 por escritorio.
- `max_auto_decisions_per_hour`: 3 por escritorio.
- `max_pending_decisions_global`: 10.

## Contrato Minimo de Auto-Acao
```yaml
schema_version: "1.2"
automation_action_id: "AUTO-UUID"
coalescing_key: "<office>:<metric>:<cause>"
idempotency_key: "IDEMP-UUID"
rollback_plan_ref: "artifact://..."
status: "CREATED|APPLIED|NO_OP_DUPLICATE|ROLLED_BACK|FAILED"
```

## Acoes Automaticas
- abrir task de mitigacao com owner.
- notificar Telegram com severidade.
- registrar evento no activity feed e incident log.
- abrir decision para ajuste estrutural quando persistente.
- nunca abrir mais de 1 decision para a mesma `coalescing_key` durante `cooldown_window`.
- auto-acao sem `rollback_plan_ref` MUST degradar para `notify-only`.

## EVAL Gates de Claims Centrais (obrigatorio)
| Claim central | Gate minimo | Threshold inicial | Acao em falha |
|---|---|---|---|
| OpenClaw gateway programatico padrao | chamada programatica fora do gateway OpenClaw | 0 casos | bloquear release + abrir incident |
| requested/effective model/provider auditavel | run sem campos de roteamento | 0 casos | bloquear pipeline + task de contrato |
| provider allowlist aplicada por sensibilidade | rota sensitive fora de allowlist | 0 casos | bloquear comando + incidente de seguranca |
| ZDR em fluxo sensitive | run sensitive sem policy ZDR quando exigido | 0 casos | stop-ship + incidente de seguranca |
| comando HITL idempotente | replay sem efeito colateral | 100% | bloquear execucao + abrir incident |
| lifecycle de challenge HITL completo | challenge expirado/duplicado aceito | 0 casos | bloquear comando critico + incidente |
| Work Order schema/version/idempotency validos | WO invalido aceito | 0 casos | bloquear ingest + task de contrato |
| reconciliacao offline sem duplicidade | eventos duplicados pos-replay | 0 casos | manter degraded + abrir decision |
| allowlists aplicadas corretamente | taxa de bloqueio de acao proibida | 100% | bloquear deploy + incidente |
| trilha auditavel integra (hash-chain) | quebra de cadeia | 0 casos | stop-ship + incidente de integridade |
| budget governor ativo por LiteLLM/supervisores | snapshot de custo desatualizado > 10 min | 0 casos | bloquear tarefas nao criticas |
| roteamento por papel (local bracal vs supervisor pago) | task de revisao critica executada fora de supervisor pago | 0 casos | bloquear release + abrir incidente |
| fallback auditavel obrigatorio | run sem `requested_model/effective_model/fallback_step/reason` | 0 casos | bloquear pipeline + task de contrato |
| email nao confiavel para comando | comando executado a partir de email sem confirmacao em canal confiavel | 0 casos | bloquear comando + incidente |
| aprovacao humana explicita em side effect financeiro | ordem/acao financeira executada sem aprovacao por ordem | 0 casos | stop-ship + incidente |
| `execution_gateway` como unico caminho de ordem live | ordem emitida fora do gateway | 0 casos | stop-ship + incidente de seguranca |
| `make eval-trading` executavel para release de trading | comando ausente/falha em CI | 0 casos | bloquear merge/deploy de trading |
| engine primaria indisponivel => `fail_closed` | nova entrada aceita com engine primaria indisponivel | 0 casos | stop-ship + incidente |
| fallback HITL trading com operadores validos | comando critico por Slack sem IDs allowlist validos | 0 casos | bloquear comando + incidente |
| degradacao com posicao aberta sem `UNMANAGED_EXPOSURE` persistente | `UNMANAGED_EXPOSURE` > 10 min | 0 casos | manter `TRADING_BLOCKED` + `SEV-1` |

## Regra de Release
- qualquer claim central sem gate definido/executado => release bloqueada.
- excecao apenas por decision explicita de risco, com prazo de correcao.

## Links Relacionados
- [ARC Observability](../ARC/ARC-OBSERVABILITY.md)
- [ARC Model Routing](../ARC/ARC-MODEL-ROUTING.md)
- [Incident Log Policy](../INCIDENTS/INCIDENT-LOG-POLICY.md)
