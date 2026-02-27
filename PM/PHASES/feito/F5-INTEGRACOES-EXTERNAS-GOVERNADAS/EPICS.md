---
doc_id: "PHASE-F5-EPICS.md"
version: "1.2"
status: "active"
owner: "PM"
last_updated: "2026-02-26"
rfc_refs: ["RFC-001", "RFC-010", "RFC-015", "RFC-040", "RFC-050", "RFC-060"]
---

# F5 Integracoes Externas Governadas - Epics

## Objetivo da Fase
Operar AI-Trader, ClawWork e OpenClaw upstream em modo governado, sem bypass de risco, com autonomia operacional controlada e blast radius reduzido.

## Gate de Saida da Fase
Comandos obrigatorios:

```bash
make eval-integrations
make eval-trading
```

Criterio objetivo:
- ambos os comandos em `PASS` no mesmo ciclo.
- evidencia objetiva de anti-bypass e segregacao de identidade/credenciais.

## Epics da Fase
| Epic ID | Nome | Objetivo | Status | Documento |
|---|---|---|---|---|
| `EPIC-F5-01` | Integracoes governadas e anti-bypass | fechar regras de integracao externa sem caminho direto de ordem para venue | done | [EPIC-F5-01-INTEGRACOES-GOVERNADAS-E-ANTI-BYPASS.md](./EPIC-F5-01-INTEGRACOES-GOVERNADAS-E-ANTI-BYPASS.md) |
| `EPIC-F5-02` | Trading hardening e prontidao live | cobrir controles operacionais de ordem, degradacao, credenciais e CI de trading | done | [EPIC-F5-02-TRADING-HARDENING-E-PRONTIDAO-LIVE.md](./EPIC-F5-02-TRADING-HARDENING-E-PRONTIDAO-LIVE.md) |
| `EPIC-F5-03` | Autonomia operacional e blast radius | formalizar cron/heartbeat/delegacao longa e segregacao de contas/ativos do agente | done | [EPIC-F5-03-AUTONOMIA-OPERACIONAL-E-BLAST-RADIUS.md](./EPIC-F5-03-AUTONOMIA-OPERACIONAL-E-BLAST-RADIUS.md) |

## Escopo Desta Entrega
- fase `F5` adicionada para remover lacuna entre `F4` e `F6` do overlay de fases usaveis.
- epicos `EPIC-F5-01..03` cobrem `B1-*` e refinos `B1-R*` remanescentes de alto impacto.
- cada issue desta fase deve referenciar:
  - ao menos um item de `PRD/ROADMAP.md` (`B*`);
  - ao menos uma fonte `felixcraft.md` ou `felix-openclaw-pontos-relevantes.md`.
