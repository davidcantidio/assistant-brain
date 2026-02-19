---
doc_id: "TRADING-ENABLEMENT-CRITERIA.md"
version: "1.0"
status: "active"
owner: "Frederisk"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-050", "RFC-060"]
---

# Trading Enablement Criteria

## Objetivo
Definir gate formal para habilitar e manter trading, garantindo que alto risco so opere sob condicoes controladas.

## Escopo
Inclui:
- criterios obrigatorios de enablement
- condicoes de bloqueio automatico
- checkpoint humano e decision para desbloqueio

Exclui:
- ativacao por conveniencia
- bypass de criterio minimo

## Regras Normativas
- [RFC-060] MUST considerar trading como alto risco estrutural.
- [RFC-060] MUST habilitar trading somente com todos os criterios verdes.
- [RFC-050] MUST bloquear automaticamente ao violar criterio em producao.
- [RFC-060] MUST exigir decision + checkpoint humano para reabilitar.

## Criterios de Habilitacao (todos obrigatorios)
- 7 dias sem incidentes criticos.
- 7 dias corridos de dry-run antes de qualquer live.
- retrabalho abaixo do threshold definido.
- zero falhas de auditoria em tarefas criticas.
- latencia dentro do SLA para operacoes de trading.
- zero violacoes das regras hard de risco durante dry-run.

## Bloqueio Automatico
- qualquer violacao de criterio MUST:
  - bloquear trading imediatamente;
  - abrir decision de reavaliacao;
  - notificar humano responsavel.

## Checkpoint Humano
- habilitacao inicial live.
- troca de estrategia principal.
- aumento de risco ou mudanca de limite.

## Evidencias para Reabilitacao
- causa raiz tratada.
- testes de regressao e dry-run aprovados.
- auditoria de logs sem anomalia.
- aprovacao em decision registrada.

## Links Relacionados
- [Trading PRD](./TRADING-PRD.md)
- [Trading Risk Rules](./TRADING-RISK-RULES.md)
- [Decision Protocol](../../PM/DECISION-PROTOCOL.md)
- [System Health Thresholds](../../EVALS/SYSTEM-HEALTH-THRESHOLDS.md)
