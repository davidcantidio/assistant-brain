# runtime contracts

Contratos versionados do bounded context de runtime.

## Artefatos ativos
- `ops_api.v1.yaml`: contrato de superficie HTTP interna (`/v1/*`) para control-plane runtime-first.

## Escopo do `ops_api.v1`
- auth bearer obrigatoria em endpoints mutaveis.
- `X-Idempotency-Key` obrigatorio em `POST`.
- envelope de resposta unico (`status/data/error`).
- validacao schema-first contra `ARC/schemas/*` para:
  - model catalog;
  - router decision;
  - llm run;
  - credits snapshot;
  - budget policy/check;
  - A2A delegation;
  - webhook ingest.
