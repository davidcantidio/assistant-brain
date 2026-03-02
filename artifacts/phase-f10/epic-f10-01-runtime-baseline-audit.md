# F10 / EPIC-F10-01 - Runtime Baseline Audit

## Contexto
- data baseline: `2026-03-02`
- profile baseline: `active`
- objetivo: capturar estado real antes da convergencia PRD -> Runtime.

## Snapshot operacional (sanitizado)
- runtime state dir: `~/.openclaw`
- gateway: `bind=loopback`, `port=18789`, `mode=local`
- canais:
  - Telegram: configurado
  - Slack: habilitado sem credencial ativa
- heartbeat observado no runtime (baseline): `30m`
- heartbeat esperado no `.env`: `15m`

## Inventarios gerados
- `artifacts/phase-f10/runtime-inventory-active-baseline.json`
  - `snapshot_id=RTS-20260302-005544-active`
  - `hash=f25dff952da4da238f6dace0f936a72e2de76ad6d57cd1e86b3839537c4e5c68`
- `artifacts/phase-f10/runtime-inventory-active-post.json`
  - `snapshot_id=RTS-20260302-005648-active`
  - `hash=ce3d860375e441dcbcb9a66dc537c49d8f6e10461404e66ecb770b8fdf3a3608`

## Gaps priorizados
1. `P0` - drift de heartbeat (`30m -> 15m`) para alinhamento com baseline operacional.
2. `P1` - formalizar merge plan com preserve/enforce para evitar mudanca manual.
3. `P1` - validar no-loss por diff automatizado antes de promocao ativa.

## Evidencias relacionadas
- `scripts/runtime/export_runtime_state.sh`
- `scripts/runtime/build_runtime_merge_plan.py`
- `artifacts/phase-f10/runtime-merge-plan-active.json`
