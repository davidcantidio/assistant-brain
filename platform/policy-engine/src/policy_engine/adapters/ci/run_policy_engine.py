#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from policy_engine.application.convergence import validate_policy_convergence
from policy_engine.application.quality import validate_quality
from policy_engine.engine import run_domain
from policy_engine.reporting.json_report import to_json


def parse_run_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run policy engine domains")
    parser.add_argument(
        "--domain",
        choices=("runtime", "security", "governance", "trading", "all"),
        default="all",
    )
    parser.add_argument("--format", choices=("json",), default="json")
    parser.add_argument("--category", default="")
    parser.add_argument("--root", default=".")
    parser.add_argument("--output", default="")
    return parser.parse_args(argv)


def parse_validate_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate policy convergence and quality")
    parser.add_argument("--consistency", action="store_true")
    parser.add_argument("--quality", action="store_true")
    parser.add_argument("--root", default=".")
    parser.add_argument("--output", default="")
    return parser.parse_args(argv)


def parse_args(argv: list[str]) -> tuple[str, argparse.Namespace]:
    if not argv:
        return "run", parse_run_args(argv)
    if argv[0] == "run":
        return "run", parse_run_args(argv[1:])
    if argv[0] == "validate":
        return "validate", parse_validate_args(argv[1:])
    return "run", parse_run_args(argv)


def _emit(payload: str, output: str) -> None:
    if output:
        Path(output).write_text(payload + "\n", encoding="utf-8")
    else:
        print(payload)


def main() -> int:
    mode, args = parse_args(sys.argv[1:])
    root = Path(args.root).resolve()

    if mode == "validate":
        selected_checks = int(args.consistency) + int(args.quality)
        if selected_checks != 1:
            raise SystemExit("validate mode requires exactly one of --consistency or --quality")

        if args.consistency:
            errors = validate_policy_convergence(root)
            check_name = "policy_convergence"
        else:
            errors = validate_quality(root)
            check_name = "quality"

        payload = json.dumps(
            {
                "schema_version": "1.0",
                "check": check_name,
                "status": "PASS" if not errors else "FAIL",
                "errors": errors,
            },
            ensure_ascii=True,
            indent=2,
        )
        _emit(payload, args.output)
        return 1 if errors else 0

    category = args.category.strip() or None
    result = run_domain(args.domain, root, category=category)
    payload = to_json(result)
    _emit(payload, args.output)
    return 1 if result.failed_rules > 0 else 0


if __name__ == "__main__":
    raise SystemExit(main())
