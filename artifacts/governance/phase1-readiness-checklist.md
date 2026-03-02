# Phase 1 Readiness Checklist

- date: 2026-03-02
- status: HOLD
- criteria:
  - backup_operator ativo e validado em gate automatizado.
  - event ledger Postgres operacional com teste de idempotencia/replay.
  - contratos v2 em escrita com leitura v1 telemetrizada.
  - fluxo HITL e side effect financeiro cobertos por e2e.
  - chaos test de fallback de canal em PASS.

## Notes
- `live_ready` MUST permanecer `false` enquanto este checklist nao estiver em `status: PASS`.
