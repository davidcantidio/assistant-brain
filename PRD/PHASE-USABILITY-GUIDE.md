---
doc_id: "PHASE-USABILITY-GUIDE.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-02-24"
rfc_refs: ["RFC-001", "RFC-010", "RFC-015", "RFC-040", "RFC-050", "RFC-060"]
---

# Phase Usability Guide

## Objetivo
Definir uma trilha de fases grandes em que cada etapa termina com uso humano real, teste humano objetivo e gate de saida verificavel.

## Escopo
Inclui:
- fases `F1` a `F8` com uso e validacao humana.
- comandos e evidencias minimas para promover fase.
- defaults operacionais para reduzir ambiguidade.

Exclui:
- detalhamento de implementacao interna de cada backlog item.
- bypass de gate por conveniencia.

## Regras Normativas
- [RFC-040] MUST bloquear promocao de fase quando gate de saida falhar.
- [RFC-050] MUST registrar evidencia minima por fase.
- [RFC-015] MUST manter seguranca e policy ativas desde `F2`.
- [RFC-060] MUST manter Trading bloqueado ate cumprimento formal de gate.

## Fases Usaveis (humano + teste + gate)
| Fase | Entregavel usavel | Como usar (humano) | Como testar (humano) | Gate de saida | Evidencia minima |
|---|---|---|---|---|---|
| `F1` Instalacao base OpenClaw | Ambiente local operacional | executar setup local e iniciar operacao no workspace principal | `bash scripts/onboard_linux.sh` e `bash scripts/verify_linux.sh` | `verify_linux.sh` sem erro | log de execucao local e versao `openclaw --version` |
| `F2` Pos-instalacao + baseline de seguranca | Regras minimas de qualidade e seguranca ativas | operar somente com allowlists e policy canonica | `make ci-quality` e `make ci-security` | ambos `PASS` | output dos dois comandos no ciclo da fase |
| `F3` Runtime minimo, memoria e heartbeat | Rotina operacional minima (daily note + ciclo noturno) | registrar atividades em `workspaces/main/memory/YYYY-MM-DD.md` e manter heartbeat | `make eval-runtime` apos atualizar nota diaria | `eval-runtime-contracts: PASS` | nota diaria com secoes obrigatorias + heartbeat alinhado |
| `F4` Onboarding de repositorios e contexto externo | Base integrada de contratos externos | usar `INTEGRATIONS/` para decidir modo permitido por integracao | `make eval-integrations` | `eval-integrations: PASS` | docs e schemas de integracao validos |
| `F5` Integracoes externas governadas | AI-Trader/ClawWork/OpenClaw upstream com modo permitido explicito | operar AI-Trader apenas como `signal_intent` e ClawWork em `lab_isolated` por default | `make eval-integrations` e `make eval-trading` | ambos `PASS` sem bypass | evidencia de bloqueio para ordem direta externa |
| `F6` Operacao humana HITL | Fluxo humano de `approve/reject/kill` definido | usar Telegram como canal primario e Slack apenas fallback validado | checklist do `PM/DECISION-PROTOCOL.md` + `make ci-security` | operador/canal valido + `security-check: PASS` | checklist HITL preenchido com operador autorizado |
| `F7` Trading por estagios (`S0 -> S1 -> S2`) | Uso progressivo com risco controlado | operar `S0` paper/sandbox com aprovacao humana por ordem | `make eval-trading` + revisao do `pre_live_checklist` | `eval-trading: PASS` e checklist sem `fail` | artifact de checklist e estado sem bypass |
| `F8` Operacao continua e evolucao | Cadencia estavel de governanca | rodar rotina semanal de gates e revisao de contratos | `make eval-gates`, `make ci-quality`, `make ci-security` | trio de gates `PASS` | registro semanal de rodada de gates + revisao |

## Defaults e Assumptions
- integracao externa default: `lab_isolated`; modo `governed` so apos gate verde.
- cloud adapter default: `disabled`; habilitacao somente por decision formal.
- trading default: `S0` paper/sandbox antes de qualquer live.
- comando humano critico default: Telegram primario; Slack apenas fallback validado.
- governanca default: doc-first com conformidade validada por gates executaveis.

## Matriz de Promocao (resumo)
- `F1 -> F2`: onboarding e verify concluido.
- `F2 -> F3`: quality e security verdes.
- `F3 -> F4`: runtime/memoria/heartbeat validados.
- `F4 -> F5`: integracoes e schemas verdes.
- `F5 -> F6`: anti-bypass trading confirmado.
- `F6 -> F7`: HITL validado com operador autorizado.
- `F7 -> F8`: readiness de trading sem item `fail`.

## Artefatos de Planejamento por Fase
- `F1`: [EPICS da fase](../PM/PHASES/F1-INSTALACAO-BASE-OPENCLAW/EPICS.md)
- `F2..F8`: pendente de criacao.

## Links Relacionados
- [Roadmap](./ROADMAP.md)
- [PRD Master](./PRD-MASTER.md)
- [Decision Protocol](../PM/DECISION-PROTOCOL.md)
- [Security Policy](../SEC/SEC-POLICY.md)
- [Integrations](../INTEGRATIONS/README.md)
