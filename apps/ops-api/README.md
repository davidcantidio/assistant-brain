# ops-api

Superficie de API interna para operacao e automacao segura.

## Implementacao atual (F11)
Base local:
- `http://127.0.0.1:18901/v1`

Endpoints:
- `POST /model-catalog/sync`
- `GET /model-catalog/models`
- `POST /router/decide`
- `POST /runs`
- `POST /budget/snapshots`
- `POST /budget/check`
- `POST /a2a/delegate`
- `POST /hooks/ingest`
- `POST /internal/hitl/approve`
- `POST /internal/hitl/reject`
- `POST /internal/hitl/kill`

Regras:
- `Authorization: Bearer ${OPENCLAW_OPS_API_TOKEN}` obrigatorio para `POST`;
- `X-Idempotency-Key` obrigatorio para `POST`;
- resposta padrao:
  - `status: ok|error`
  - `data: {}`
  - `error: { code, message }`
- payload HITL minimo:
  - `decision_id`, `command_id`, `operator_id`, `channel`, `challenge_id`, `signature_or_proof`, `evidence_ref`.

Execucao local:
```bash
PYTHONPATH=apps/control-plane/src:apps/ops-api/src python3 -m ops_api.run
```
