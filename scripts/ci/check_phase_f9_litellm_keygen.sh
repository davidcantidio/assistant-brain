#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

python3 - <<'PY'
import contextlib
import importlib.util
import io
import json
import os
import sys
from pathlib import Path

SCRIPT_PATH = Path("generate_litellm_virtual_key.py")


def fail(msg: str) -> None:
    print(msg)
    sys.exit(1)


source = SCRIPT_PATH.read_text(encoding="utf-8")
if "import requests" in source:
    fail("phase-f9-litellm-keygen: FAIL (dependency requests ainda presente)")

spec = importlib.util.spec_from_file_location("litellm_keygen", SCRIPT_PATH)
if spec is None or spec.loader is None:
    fail("phase-f9-litellm-keygen: FAIL (nao foi possivel carregar generate_litellm_virtual_key.py)")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class MockResponse:
    def __init__(self, payload: dict, status_code: int = 200) -> None:
        self._payload = payload
        self._status_code = status_code

    def read(self) -> bytes:
        return json.dumps(self._payload).encode("utf-8")

    def getcode(self) -> int:
        return self._status_code

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb) -> bool:
        return False


def run_main_with_payload(payload: dict) -> tuple[str, str | None]:
    original_urlopen = module.urllib.request.urlopen
    original_env = dict(os.environ)

    def fake_urlopen(_req, timeout=30):
        _ = timeout
        return MockResponse(payload)

    module.urllib.request.urlopen = fake_urlopen
    os.environ["LITELLM_PROXY_URL"] = "http://127.0.0.1:4000"
    os.environ["LITELLM_MASTER_KEY"] = "sk-master-test"
    os.environ["LITELLM_MODELS"] = "codex-main,claude-review"
    os.environ["LITELLM_OUTPUT_MODE"] = "key-only"

    stdout_buffer = io.StringIO()
    stderr_buffer = io.StringIO()
    exit_message = None
    try:
        with contextlib.redirect_stdout(stdout_buffer), contextlib.redirect_stderr(stderr_buffer):
            module.main()
    except SystemExit as exc:
        exit_message = str(exc)
    finally:
        module.urllib.request.urlopen = original_urlopen
        os.environ.clear()
        os.environ.update(original_env)

    _ = stderr_buffer.getvalue()
    return stdout_buffer.getvalue(), exit_message


# Scenario 1: key-only success returns only the key
success_stdout, success_exit = run_main_with_payload({"key": "sk-litellm-generated-test"})
if success_exit is not None:
    fail(f"phase-f9-litellm-keygen: FAIL (key-only sucesso retornou erro: {success_exit})")
if success_stdout.strip() != "sk-litellm-generated-test":
    fail(
        "phase-f9-litellm-keygen: FAIL (key-only nao retornou somente a chave; "
        f"stdout={success_stdout!r})"
    )

# Scenario 2: missing key must fail explicitly
missing_stdout, missing_exit = run_main_with_payload({"status": "ok"})
if missing_stdout.strip():
    fail("phase-f9-litellm-keygen: FAIL (resposta sem chave nao deveria imprimir stdout)")
if not missing_exit or "Generated key not found" not in missing_exit:
    fail(
        "phase-f9-litellm-keygen: FAIL (mensagem de erro explicita ausente para resposta sem chave)"
    )

print("phase-f9-litellm-keygen: PASS")
PY
