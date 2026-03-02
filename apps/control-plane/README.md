# control-plane

Camada de aplicacao para orquestracao operacional (estado, fila e governanca runtime).

## Implementacao atual (F11)
- validacao schema-first com `jsonschema` para contratos de runtime;
- servicos de dominio para:
  - model catalog (`sync/list`);
  - router decisions;
  - llm runs;
  - budget snapshots/check;
  - A2A delegation;
  - webhook ingest;
- enforce de privacidade por `data_sensitivity` + allowlist de provider;
- idempotencia por endpoint (`route + X-Idempotency-Key`);
- correlacao por `trace_id` para evidencia operacional.

## Backends de telemetria
- `memory` (default para dev/test);
- `postgres` (canonico para runtime), via `OPENCLAW_TELEMETRY_BACKEND=postgres` e `OPENCLAW_TELEMETRY_DSN`.
