---
doc_id: "FELIX-ALIGNMENT-MATRIX.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-02-24"
rfc_refs: ["RFC-001", "RFC-015", "RFC-040", "RFC-050", "RFC-060"]
---

# Matriz de Alinhamento Felix -> Epics/Issues

## Objetivo
Garantir rastreabilidade explicita entre requisitos/principios de `felixcraft.md` e `felix-openclaw-pontos-relevantes.md` contra backlog de execucao (epics/issues).

## Regras de uso
- cada linha deve apontar para ao menos um `Issue` ativo em `PM/PHASES`.
- divergencia intencional deve ser marcada como `override_documentado` com referencia normativa.
- item sem issue mapeada bloqueia promocao de fase.

## Fonte canonica
- [Felixcraft Architecture](../../felixcraft.md)
- [Felix OpenClaw Pontos Relevantes](../../felix-openclaw-pontos-relevantes.md)
- [Document Hierarchy](../../META/DOCUMENT-HIERARCHY.md)
- [PRD Changelog](../../PRD/CHANGELOG.md)

## Matriz
| Tema Felix | Status | Epic/Issue alvo | Observacao |
|---|---|---|---|
| OpenClaw gateway-first com `bind=loopback` | aligned | `EPIC-F3-01` / `ISSUE-F3-01-02` | contrato runtime e compatibilidade dual mapeados |
| `chatCompletions` opcional sob policy | aligned | `EPIC-F4-02` / `ISSUE-F4-02-03` | sem bypass de policy |
| canais confiaveis vs informacionais | aligned | `EPIC-F6-01` / `ISSUE-F6-01-02` | email nao confiavel para comando |
| challenge + idempotencia em comando critico | aligned | `EPIC-F6-02` / `ISSUE-F6-02-01..03` | ciclo completo HITL |
| fallback Slack com assinatura/anti-replay/challenge | aligned | `EPIC-F6-03` / `ISSUE-F6-03-01` | fallback controlado |
| approval queue para acao sensivel | aligned | `EPIC-F2-01` / `ISSUE-F2-01-03` | bloqueio por canal nao confiavel |
| memoria em camadas com daily notes | aligned | `EPIC-F3-02` / `ISSUE-F3-02-01..03` | memoria canonica e qualidade minima |
| backend semantico `qmd` | aligned | `EPIC-F3-01` / `ISSUE-F3-01-02` | contrato runtime com `memory.backend=qmd` |
| cron de consolidacao noturna de memoria | override_documentado | `EPIC-F3-03` / `ISSUE-F3-03-02` | repositorio adota `23:00 America/Sao_Paulo` (override registrado no changelog) |
| heartbeat operacional com monitoracao de jobs | aligned | `EPIC-F5-03` / `ISSUE-F5-03-01` | monitoracao `stalled` + restart controlado |
| delegacao de tarefas grandes para agente de codigo | aligned | `EPIC-F5-03` / `ISSUE-F5-03-01` | contrato de autonomia operacional |
| evitar execucao em armazenamento volatil para jobs longos | aligned | `EPIC-F5-03` / `ISSUE-F5-03-01` | runbook de sessao isolada + restart |
| proatividade por cron (rotinas periodicas) | aligned | `EPIC-F5-03` / `ISSUE-F5-03-02` | cron com trilha auditavel |
| anti-prompt-injection por confianca de canal | aligned | `EPIC-F2-01` / `ISSUE-F2-01-03` | origem nao confiavel fica bloqueada |
| A2A com allowlist explicita | aligned | `EPIC-F2-03` / `ISSUE-F2-03-05` | delegacao fora de allowlist falha |
| hooks/webhooks com transform tipada | aligned | `EPIC-F2-03` / `ISSUE-F2-03-05` | mapeamento obrigatorio e `trace_id` |
| trilha de custos e otimizacao por classe de tarefa | aligned | `EPIC-F5-03` / `ISSUE-F5-03-03` | governanca de custo, fallback e preset |
| segregacao de contas/ativos do agente (blast radius) | aligned | `EPIC-F5-03` / `ISSUE-F5-03-06` | separar superficie social/email/pagamentos/carteira |
| concessao gradual de permissoes (trust ladder) | aligned | `EPIC-F2-01` / `ISSUE-F2-01-03` e `EPIC-F5-03` / `ISSUE-F5-03-06` | faseamento por risco |
| multi-thread/contexto por canal sem mistura de estado | aligned | `EPIC-F5-01` / `ISSUE-F5-01-04` | modo permitido por integracao e rastreabilidade |

## Criterio de aceite desta matriz
- 100% dos temas criticos de seguranca, memoria, autonomia e trading com issue mapeada.
- toda divergencia explicita com status `override_documentado` e referencia normativa.
