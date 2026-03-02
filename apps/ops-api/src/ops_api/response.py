from __future__ import annotations


def ok(data: dict[str, object]) -> dict[str, object]:
    return {
        "status": "ok",
        "data": data,
        "error": {"code": None, "message": None},
    }


def error(code: str, message: str) -> dict[str, object]:
    return {
        "status": "error",
        "data": {},
        "error": {"code": code, "message": message},
    }
