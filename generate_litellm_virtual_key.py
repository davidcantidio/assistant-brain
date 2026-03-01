#!/usr/bin/env python3
import json
import os
import sys
import urllib.error
import urllib.request
from typing import Any, Dict, List, Optional


def env(name: str, default: Optional[str] = None) -> str:
    val = os.getenv(name, default)
    if not val:
        raise SystemExit(f"Missing env var: {name}")
    return val


def parse_models(raw: str) -> List[str]:
    models = [m.strip() for m in raw.split(",") if m.strip()]
    if not models:
        raise SystemExit("No models provided. Set LITELLM_MODELS='gpt-4o,claude-3-5-sonnet,...'")
    return models


def output_mode() -> str:
    mode = os.getenv("LITELLM_OUTPUT_MODE", "pretty").strip().lower()
    if mode not in {"pretty", "key-only", "json"}:
        raise SystemExit("Invalid LITELLM_OUTPUT_MODE. Use: pretty|key-only|json")
    return mode


def generate_key() -> Dict[str, Any]:
    proxy_url = env("LITELLM_PROXY_URL")  # e.g. http://localhost:4000
    master_key = env("LITELLM_MASTER_KEY")  # must start with sk-
    models = parse_models(env("LITELLM_MODELS"))

    # Optional knobs
    key_alias = os.getenv("LITELLM_KEY_ALIAS")  # e.g. "assistant-brain-ci"
    user_email = os.getenv("LITELLM_USER_EMAIL")  # metadata example
    team_id = os.getenv("LITELLM_TEAM_ID")  # if you use teams
    max_budget = os.getenv("LITELLM_MAX_BUDGET")  # e.g. "5.0"
    budget_duration = os.getenv("LITELLM_BUDGET_DURATION")  # e.g. "30d"
    soft_budget = os.getenv("LITELLM_SOFT_BUDGET")  # e.g. "1.0"

    payload: Dict[str, Any] = {
        "models": models,
        "metadata": {},
    }

    if user_email:
        payload["metadata"]["user"] = user_email

    # These fields are used across LiteLLM docs/examples for key generation/config
    if key_alias:
        payload["key_alias"] = key_alias
    if team_id:
        payload["team_id"] = team_id
    if max_budget:
        payload["max_budget"] = float(max_budget)
    if budget_duration:
        payload["budget_duration"] = budget_duration
    if soft_budget:
        payload["soft_budget"] = float(soft_budget)

    url = proxy_url.rstrip("/") + "/key/generate"
    headers = {
        "Authorization": f"Bearer {master_key}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }

    body = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=body, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            response_body = response.read().decode("utf-8")
            data = json.loads(response_body)
            status_code = response.getcode()
    except urllib.error.HTTPError as exc:
        error_body = exc.read().decode("utf-8", errors="replace")
        raise SystemExit(f"LiteLLM error {exc.code}: {error_body}") from exc
    except urllib.error.URLError as exc:
        raise SystemExit(f"LiteLLM connection error: {exc}") from exc

    return {"status_code": status_code, "response": data}


def find_generated_key(data: Dict[str, Any]) -> Optional[str]:
    return (
        data.get("key")
        or data.get("token")
        or data.get("api_key")
        or data.get("data", {}).get("key")
    )


def main() -> None:
    result = generate_key()
    response_data = result["response"]
    generated_key = find_generated_key(response_data)
    mode = output_mode()

    if mode == "key-only":
        if not generated_key:
            raise SystemExit("Generated key not found in LiteLLM response.")
        print(generated_key)
        return

    if mode == "json":
        print(json.dumps(response_data))
        return

    print("=== LiteLLM /key/generate response ===")
    print(json.dumps(response_data, indent=2))

    if generated_key:
        print("\n=== GENERATED_VIRTUAL_KEY (store this in GitHub Secrets) ===")
        print(generated_key)
    else:
        print("\nWARNING: Could not find generated key field in response. Check output above.", file=sys.stderr)


if __name__ == "__main__":
    main()
