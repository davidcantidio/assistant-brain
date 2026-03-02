# event-ledger

Ledger operacional append-only para eventos criticos de decisao e execucao.

## Objetivo
- registrar eventos com idempotencia forte;
- rejeitar replay nao autorizado para a mesma chave idempotente;
- manter trilha auditavel por stream.

## Contrato
- storage: PostgreSQL;
- migracoes SQL em `migrations/`;
- API Python em `src/event_ledger/`.
