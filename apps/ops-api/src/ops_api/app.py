from __future__ import annotations

from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from control_plane.errors import ControlPlaneError
from control_plane.service import ControlPlaneService
from ops_api.deps import get_service, require_auth, require_idempotency_key
from ops_api.response import error, ok
from ops_api.service import HITLService, ReplayRejectedError, build_hitl_service


def create_app(
    service: ControlPlaneService | None = None,
    *,
    hitl_service: HITLService | None = None,
) -> FastAPI:
    app = FastAPI(title="OpenClaw Ops API", version="1.0", docs_url="/docs", redoc_url=None)

    resolved_service = service or get_service()
    resolved_hitl_service = hitl_service or build_hitl_service()

    @app.exception_handler(ControlPlaneError)
    async def _control_plane_error(_: Request, exc: ControlPlaneError) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content=error(exc.code, exc.message),
        )

    @app.exception_handler(HTTPException)
    async def _http_error(_: Request, exc: HTTPException) -> JSONResponse:
        detail = exc.detail if isinstance(exc.detail, str) else str(exc.detail)
        return JSONResponse(status_code=exc.status_code, content=error("HTTP_ERROR", detail))

    @app.exception_handler(RequestValidationError)
    async def _validation_error(_: Request, exc: RequestValidationError) -> JSONResponse:
        return JSONResponse(
            status_code=422,
            content=error("REQUEST_VALIDATION_ERROR", str(exc)),
        )

    @app.exception_handler(ReplayRejectedError)
    async def _replay_error(_: Request, exc: ReplayRejectedError) -> JSONResponse:
        return JSONResponse(
            status_code=409,
            content=error("REPLAY_REJECTED", str(exc)),
        )

    @app.get("/v1/model-catalog/models")
    async def list_model_catalog(
        provider: str | None = None,
        status: str | None = None,
        risk_scope: str | None = None,
        capability: str | None = None,
    ) -> dict[str, object]:
        data = resolved_service.list_models(
            provider=provider,
            status=status,
            risk_scope=risk_scope,
            capability=capability,
        )
        return ok(data)

    @app.get("/v1/traces/{trace_id}")
    async def get_trace_snapshot(trace_id: str) -> dict[str, object]:
        return ok(resolved_service.trace_snapshot(trace_id))

    @app.post("/v1/model-catalog/sync", dependencies=[Depends(require_auth)])
    async def post_model_catalog_sync(
        request: Request,
        idempotency_key: str = Depends(require_idempotency_key),
    ) -> dict[str, object]:
        payload = await _as_object(request)
        return ok(resolved_service.sync_model_catalog(payload, idempotency_key=idempotency_key))

    @app.post("/v1/router/decide", dependencies=[Depends(require_auth)])
    async def post_router_decide(
        request: Request,
        idempotency_key: str = Depends(require_idempotency_key),
    ) -> dict[str, object]:
        payload = await _as_object(request)
        return ok(resolved_service.decide_router(payload, idempotency_key=idempotency_key))

    @app.post("/v1/runs", dependencies=[Depends(require_auth)])
    async def post_runs(
        request: Request,
        idempotency_key: str = Depends(require_idempotency_key),
    ) -> dict[str, object]:
        payload = await _as_object(request)
        return ok(resolved_service.ingest_run(payload, idempotency_key=idempotency_key))

    @app.post("/v1/budget/snapshots", dependencies=[Depends(require_auth)])
    async def post_budget_snapshots(
        request: Request,
        idempotency_key: str = Depends(require_idempotency_key),
    ) -> dict[str, object]:
        payload = await _as_object(request)
        return ok(resolved_service.ingest_budget_snapshot(payload, idempotency_key=idempotency_key))

    @app.post("/v1/budget/check", dependencies=[Depends(require_auth)])
    async def post_budget_check(
        request: Request,
        idempotency_key: str = Depends(require_idempotency_key),
    ) -> dict[str, object]:
        payload = await _as_object(request)
        return ok(resolved_service.check_budget(payload, idempotency_key=idempotency_key))

    @app.post("/v1/a2a/delegate", dependencies=[Depends(require_auth)])
    async def post_a2a_delegate(
        request: Request,
        idempotency_key: str = Depends(require_idempotency_key),
    ) -> dict[str, object]:
        payload = await _as_object(request)
        return ok(resolved_service.delegate_a2a(payload, idempotency_key=idempotency_key))

    @app.post("/v1/hooks/ingest", dependencies=[Depends(require_auth)])
    async def post_hooks_ingest(
        request: Request,
        idempotency_key: str = Depends(require_idempotency_key),
    ) -> dict[str, object]:
        payload = await _as_object(request)
        return ok(resolved_service.ingest_webhook(payload, idempotency_key=idempotency_key))

    @app.post("/internal/hitl/approve", dependencies=[Depends(require_auth)])
    async def post_hitl_approve(
        request: Request,
        _idempotency_key: str = Depends(require_idempotency_key),
    ) -> dict[str, object]:
        payload = await _as_object(request)
        try:
            result = resolved_hitl_service.handle_action("approve", payload)
        except ValueError as exc:
            raise HTTPException(status_code=422, detail=str(exc)) from exc
        return ok(
            {
                "decision_status": result.status,
                "decision_id": result.decision_id,
                "event_id": result.event_id,
                "ledger_status": result.ledger_status,
                "action": result.action,
            }
        )

    @app.post("/internal/hitl/reject", dependencies=[Depends(require_auth)])
    async def post_hitl_reject(
        request: Request,
        _idempotency_key: str = Depends(require_idempotency_key),
    ) -> dict[str, object]:
        payload = await _as_object(request)
        try:
            result = resolved_hitl_service.handle_action("reject", payload)
        except ValueError as exc:
            raise HTTPException(status_code=422, detail=str(exc)) from exc
        return ok(
            {
                "decision_status": result.status,
                "decision_id": result.decision_id,
                "event_id": result.event_id,
                "ledger_status": result.ledger_status,
                "action": result.action,
            }
        )

    @app.post("/internal/hitl/kill", dependencies=[Depends(require_auth)])
    async def post_hitl_kill(
        request: Request,
        _idempotency_key: str = Depends(require_idempotency_key),
    ) -> dict[str, object]:
        payload = await _as_object(request)
        try:
            result = resolved_hitl_service.handle_action("kill", payload)
        except ValueError as exc:
            raise HTTPException(status_code=422, detail=str(exc)) from exc
        return ok(
            {
                "decision_status": result.status,
                "decision_id": result.decision_id,
                "event_id": result.event_id,
                "ledger_status": result.ledger_status,
                "action": result.action,
            }
        )

    return app


async def _as_object(request: Request) -> dict[str, object]:
    payload = await request.json()
    if not isinstance(payload, dict):
        raise ControlPlaneError(
            code="INVALID_JSON_PAYLOAD",
            message="request payload must be a JSON object",
            status_code=422,
        )
    return payload
