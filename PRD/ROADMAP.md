---
doc_id: "ROADMAP.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-010", "RFC-020", "RFC-035", "RFC-040", "RFC-050", "RFC-060"]
---

# Roadmap

## Objetivo
Definir fases, milestones e criterios objetivos de saida para evolucao do OpenClaw Agent OS com controle de risco.

## Escopo
Inclui:
- planejamento em 3 fases (Mission Control, Trading, Expansao)
- entregas tecnicas minimas por fase
- Definition of Done com metrica verificavel

Exclui:
- especificacao detalhada de cada arquivo tecnico
- tuning de modelo por classe de tarefa
- implementacao de codigo da infraestrutura

## Regras Normativas
- [RFC-040] MUST bloquear inicio de fase nova sem DoD da fase anterior.
- [RFC-010] MUST manter gate por risco em todas as fases.
- [RFC-050] MUST acompanhar custo, latencia, fallback e incidentes por fase.
- [RFC-035] MUST validar degradacao e reconciliacao antes de subir risco operacional.
- [RFC-060] MUST tratar Trading como fase gated por enablement formal.

## Fase 0 - Mission Control Minimo
- Convex com colecoes minimas e funcoes de task/mention/decision/activity.
- OpenClaw runtime configurado para workspace `workspaces/main`.
- `workspaces/ops` e `workspaces/writer` ficam reservados para Fase 2 (sem operacao ativa no MVP).
- Telegram bot com `/approve`, `/reject`, `/kill` e standup diario 11:30 (-03).
- Squad inicial com 4 agentes: Marvin, Formiga, Frederisk e Lupa.
- Observabilidade basica, trilha de auditoria e degraded mode minimo.
- Routing MVP limitado a 3 classes: Dispatcher, RAG Librarian (empresa) e Dev Junior.
- Gate deterministico obrigatorio antes de autonomia: schema + policy + testes.

Backlog de construcao de codigo (obrigatorio na Fase 0):
- implementar contratos `work_order`, `decision`, `task_event` com validacao de schema.
- implementar bot Telegram com autenticacao forte de operador.
- implementar reconciliador de degraded mode (`idempotency_key` + `replay_key`).
- implementar CI gates para allowlists, claims centrais e seguranca.

DoD Fase 0:
- 7 dias de operacao estavel.
- uptime operacional >= 99.0% no periodo piloto.
- reboot sem corrupcao de estado.
- decisions aprovam/rejeitam corretamente.
- wake-up por mention funcional.
- standup diario entregue de forma consistente.
- taxa de falha de tarefa < 10% por hora.
- delay de heartbeat p95 <= 5 minutos vs agenda.
- MTTR <= 30 minutos para incidente operacional.
- backlog envelhecido (>24h) <= 10 tarefas abertas.
- custo cloud dentro do baseline inicial definido em governanca financeira.
- 100% dos claims centrais com eval gate definido e executado.

## Fase 1 - Trading (alto risco)
- Pipeline: backtest -> dry-run -> live.
- Integracao Binance Spot + Freqtrade em sandbox isolado.
- Guardrails obrigatorios de risco e kill switch.
- Aprovar transicao para live somente via decision + checkpoint humano.

DoD Fase 1:
- gating de enablement totalmente verde.
- zero falhas de auditoria em execucao critica.
- incidentes criticos abaixo de threshold.
- latencia e custo dentro do SLA aprovado.

## Fase 2 - Expansao
- Novas verticais e novos escritorios com padrao de governanca comum.
- Dashboard opcional alem do Telegram.
- Migracao para microservices apenas com sinais objetivos persistentes.

DoD Fase 2:
- novas verticais operando sem violacao de politica.
- isolamento de dados entre empresas validado.
- thresholds de saude e custo mantidos por 30 dias.

## Marcos
- M0: estrutura documental normativa completa.
- M1: Mission Control MVP em producao controlada.
- M2: trading habilitado por criterios formais.
- M3: primeira vertical de baixo risco alem da principal.
- M4: escalonamento com governanca sem regressao.

## Links Relacionados
- [PRD Master](./PRD-MASTER.md)
- [Changelog](./CHANGELOG.md)
- [Trading Enablement](../VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md)
- [System Health Thresholds](../EVALS/SYSTEM-HEALTH-THRESHOLDS.md)
- [Decision Protocol](../PM/DECISION-PROTOCOL.md)
