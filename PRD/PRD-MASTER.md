---
doc_id: "PRD-MASTER.md"
version: "1.0"
status: "active"
owner: "Marvin"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-010", "RFC-015", "RFC-020", "RFC-025", "RFC-030", "RFC-035", "RFC-040", "RFC-050", "RFC-060"]
---

# PRD Master

## Objetivo
Este documento define a constituicao executiva do OpenClaw Agent OS no modelo "edificio empresarial virtual", com foco em governanca por risco, auditabilidade e escalabilidade controlada.

## Escopo
Inclui:
- visao de produto, organizacao, governanca de risco e fases 0/1/2
- decisoes fechadas e parametros que vao para decision protocol
- referencias para normas tecnicas e operacionais detalhadas

Exclui:
- tabelas extensas de roteamento de modelos
- schemas completos de payload e codigo de implementacao
- playbooks de incidente e regras detalhadas por vertical

## Regras Normativas
- [RFC-001] MUST usar termos normativos MUST/SHOULD/MAY em toda a stack documental.
- [RFC-010] MUST aplicar aprovacao proporcional ao risco (baixo, medio, alto).
- [RFC-015] MUST tratar seguranca como enforceable (sandbox, allowlist, redaction e secrets).
- [RFC-020] MUST executar colaboracao entre empresas via Work Order formal.
- [RFC-025] MUST operar RAG hibrido com isolamento por empresa e citacao por claim.
- [RFC-030] MUST adotar model routing com fallback ladder e SLA p50/p95.
- [RFC-035] MUST operar degraded mode com trilha offline e reconciliacao posterior.
- [RFC-040] MUST limitar Scrum (sprint/task) com override somente por decision.
- [RFC-050] MUST registrar observabilidade e auditoria por tarefa/empresa/decisao.
- [RFC-060] MUST tratar Trading como vertical de alto risco estrutural.

## Visao Executiva
- O sistema opera como um edificio com escritorios por empresa e servicos compartilhados de condominio.
- A execucao padrao e Local + Cloud: local para microtarefas e cloud para supervisao estrategica e risco.
- Perfis oficiais: `VPS-CLOUD` (producao, cloud-first) e `MAC-LOCAL` (dev/pesquisa, local-first).
- O Mission Control (Convex + runtime + Telegram) e o sistema nervoso central.
- O objetivo principal e previsibilidade operacional: determinismo > prompt.

## Estrutura Organizacional Minima
- Diretora IA (cloud): desempate, risco alto, aprovacoes criticas.
- PM: backlog, sprint, capacidade e limites.
- RAG Librarian: curadoria, versionamento, citacoes e drift de politica.
- Controladoria/Financeiro: budget e teto por empresa/tarefa.
- Compliance/Auditoria: aderencia normativa e rastreabilidade.

## Governanca de Risco (Nivel Alto)
- Baixo risco: execucao local com validacao deterministica e log obrigatorio.
- Medio risco: execucao local com revisao cloud por amostragem/checkpoint.
- Alto risco: rascunho local, aprovacao cloud obrigatoria e HITL quando definido.
- Circuit breaker abre task/decision ao exceder tentativas, custo ou tempo.

## Fases e Definition of Done
- Fase 0 (Mission Control MVP):
  - Convex minimo, Telegram approve/reject/kill, 4 agentes (Marvin, Formiga, Frederisk, Lupa), logs e artifacts.
  - inclui backlog de implementacao de codigo (control-plane, validações, eval gates e runbooks), pois este repo ainda esta em fase PRD.
  - DoD MUST: 7 dias estavel, reboot sem corrupcao, decision funcional, wake-up por mention, standup 11:30 -03.
- Fase 1 (Trading):
  - habilitada somente apos criterios de enablement da vertical de alto risco.
- Fase 2 (Expansao):
  - novas verticais/escritorios, UI adicional opcional e migracao para microservices apenas por sinais objetivos.

## Decisoes Fechadas
- Arquitetura padrao Local + Cloud com governanca por risco.
- Mission Control em Convex, HITL por Telegram.
- RAG em duas camadas (geral do condominio + por empresa).
- Degraded mode obrigatorio com persistencia offline e reconciliacao.
- Queda de Convex/Telegram MUST gerar instrucoes de recuperacao para humano (`human_action_required.md`).
- Scrum com limites rigidos e override por decision.
- Fase 0 com routing MVP limitado a 3 classes e gates deterministicas obrigatorias.
- Fonte canonica de memoria/estado operacional no MVP:
  - `workspaces/main/memory/`
  - `workspaces/main/.openclaw/workspace-state.json`

## Regra de Testabilidade de Claims Centrais
- claim central sem eval gate MUST bloquear release de fase.
- automacao com efeito colateral sem idempotencia/rollback MUST ser tratada como stop-ship.

## Decisoes Parametrizaveis (via Decision)
- teto mensal de custo por empresa e por vertical
- cooldown apos loss em trading (3h/6h/12h)
- limiar de drawdown guard (8%-12%)
- modelo/quant padrao por classe de tarefa
- estrategia inicial de trading e ativos habilitados

## Links Relacionados
- [Roadmap](./ROADMAP.md)
- [Changelog](./CHANGELOG.md)
- [Governance Risk](../CORE/GOVERNANCE-RISK.md)
- [ARC Core](../ARC/ARC-CORE.md)
- [Security Policy](../SEC/SEC-POLICY.md)
- [RAG General](../RAG/RAG-GENERAL.md)
- [Decision Protocol](../PM/DECISION-PROTOCOL.md)
- [Deterministic Pipeline](../DEV/DEV-DETERMINISTIC-PIPELINE.md)
- [Trading Enablement](../VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md)
- [RFC Index](../META/RFC-INDEX.md)
