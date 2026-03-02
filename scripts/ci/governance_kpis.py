#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import json
import re
from pathlib import Path

OWNER_PATTERN = re.compile(r"@[A-Za-z0-9_-]+")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate and enforce governance KPI baseline")
    parser.add_argument("--root", default=".")
    parser.add_argument("--output", required=True)
    parser.add_argument("--require-min-global-owners", type=int, default=2)
    parser.add_argument("--require-min-enabled-operators", type=int, default=2)
    parser.add_argument("--max-ci-god-scripts", type=int, default=6)
    parser.add_argument("--god-script-threshold-lines", type=int, default=300)
    parser.add_argument("--require-min-typed-critical-checks-pct", type=float, default=50.0)
    parser.add_argument("--require-min-e2e-chaos-tests", type=int, default=2)
    return parser.parse_args()


def _read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore")


def collect_codeowners_metrics(root: Path) -> dict[str, object]:
    path = root / ".github/CODEOWNERS"
    if not path.exists():
        return {
            "exists": False,
            "global_owner_count": 0,
            "global_owners": [],
            "scoped_rule_count": 0,
            "scoped_rules": [],
        }

    lines = _read_text(path).splitlines()
    global_line = ""
    scoped_rules: list[str] = []
    for raw in lines:
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("*") and not global_line:
            global_line = line
            continue
        if line.startswith("*"):
            continue
        if "@" in line:
            scoped_rules.append(line)

    global_owners = OWNER_PATTERN.findall(global_line)
    return {
        "exists": True,
        "global_owner_count": len(global_owners),
        "global_owners": global_owners,
        "scoped_rule_count": len(scoped_rules),
        "scoped_rules": scoped_rules,
    }


def collect_operator_metrics(root: Path) -> dict[str, object]:
    path = root / "SEC/allowlists/OPERATORS.yaml"
    if not path.exists():
        return {
            "exists": False,
            "enabled_operator_count": 0,
            "enabled_operator_ids": [],
            "backup_operator_id": None,
            "backup_operator_enabled": False,
            "live_ready": False,
        }

    text = _read_text(path)
    backup_match = re.search(r'backup_operator_operator_id:\s*"([^"]+)"', text)
    backup_operator_id = backup_match.group(1) if backup_match else None

    live_ready_match = re.search(r"live_ready:\s*(true|false)", text)
    live_ready = (live_ready_match.group(1) == "true") if live_ready_match else False

    blocks = re.split(r"\n\s*-\s+operator_id:\s*", text)
    enabled_operator_ids: list[str] = []
    for block in blocks[1:]:
        lines = block.splitlines()
        if not lines:
            continue
        operator_id = lines[0].strip().strip('"')
        enabled_match = re.search(r"\n\s+enabled:\s*(true|false)", "\n" + block)
        enabled = (enabled_match.group(1) == "true") if enabled_match else False
        if enabled:
            enabled_operator_ids.append(operator_id)

    return {
        "exists": True,
        "enabled_operator_count": len(enabled_operator_ids),
        "enabled_operator_ids": enabled_operator_ids,
        "backup_operator_id": backup_operator_id,
        "backup_operator_enabled": backup_operator_id in enabled_operator_ids,
        "live_ready": live_ready,
    }


def collect_ci_shell_metrics(root: Path, god_threshold_lines: int) -> dict[str, object]:
    ci_dir = root / "scripts/ci"
    if not ci_dir.exists():
        return {
            "exists": False,
            "total_scripts": 0,
            "total_lines": 0,
            "god_script_threshold_lines": god_threshold_lines,
            "god_scripts": [],
        }

    scripts = sorted(ci_dir.glob("*.sh"))
    total_lines = 0
    god_scripts: list[dict[str, object]] = []
    for script in scripts:
        line_count = _read_text(script).count("\n")
        total_lines += line_count
        if line_count > god_threshold_lines:
            god_scripts.append(
                {
                    "path": script.relative_to(root).as_posix(),
                    "line_count": line_count,
                }
            )

    return {
        "exists": True,
        "total_scripts": len(scripts),
        "total_lines": total_lines,
        "god_script_threshold_lines": god_threshold_lines,
        "god_scripts": god_scripts,
    }


def collect_policy_test_metrics(root: Path) -> dict[str, object]:
    tests_dir = root / "platform/policy-engine/tests"
    if not tests_dir.exists():
        return {
            "exists": False,
            "test_cases": 0,
            "assert_statements": 0,
        }

    test_cases = 0
    assert_statements = 0
    for test_file in tests_dir.rglob("test_*.py"):
        text = _read_text(test_file)
        test_cases += len(re.findall(r"^\s*def\s+test_", text, flags=re.M))
        assert_statements += len(re.findall(r"\bassert", text))

    return {
        "exists": True,
        "test_cases": test_cases,
        "assert_statements": assert_statements,
    }


def collect_phase1_reconstruction_metrics(root: Path) -> dict[str, object]:
    critical_scripts = (
        "scripts/ci/check_phase_f8_weekly_governance.sh",
        "scripts/ci/eval_trading.sh",
        "scripts/ci/check_security.sh",
        "scripts/ci/eval_runtime_contracts.sh",
    )
    typed_count = 0
    for rel in critical_scripts:
        path = root / rel
        if not path.exists():
            continue
        text = _read_text(path)
        if "policy-engine" in text:
            typed_count += 1
    total_critical = len(critical_scripts)
    typed_pct = round((typed_count / total_critical) * 100.0, 2) if total_critical else 0.0

    e2e_tests = len(list((root / "tests/e2e").glob("test_*.py")))
    chaos_tests = len(list((root / "tests/chaos").glob("test_*.py")))
    return {
        "critical_checks_total": total_critical,
        "critical_checks_typed_count": typed_count,
        "critical_checks_typed_pct": typed_pct,
        "e2e_test_files": e2e_tests,
        "chaos_test_files": chaos_tests,
        "e2e_chaos_total_test_files": e2e_tests + chaos_tests,
    }


def evaluate_violations(
    *,
    codeowners: dict[str, object],
    operators: dict[str, object],
    ci_shell: dict[str, object],
    phase1_reconstruction: dict[str, object],
    require_min_global_owners: int,
    require_min_enabled_operators: int,
    max_ci_god_scripts: int,
    require_min_typed_critical_checks_pct: float,
    require_min_e2e_chaos_tests: int,
) -> list[dict[str, str]]:
    violations: list[dict[str, str]] = []

    if not bool(codeowners["exists"]):
        violations.append(
            {
                "id": "CODEOWNERS_MISSING",
                "message": "CODEOWNERS ausente.",
            }
        )
    elif int(codeowners["global_owner_count"]) < require_min_global_owners:
        violations.append(
            {
                "id": "CODEOWNERS_GLOBAL_SPOF",
                "message": (
                    "Regra global do CODEOWNERS abaixo do minimo de owners "
                    f"({codeowners['global_owner_count']} < {require_min_global_owners})."
                ),
            }
        )

    if not bool(operators["exists"]):
        violations.append(
            {
                "id": "OPERATORS_MISSING",
                "message": "SEC/allowlists/OPERATORS.yaml ausente.",
            }
        )
    elif int(operators["enabled_operator_count"]) < require_min_enabled_operators:
        violations.append(
            {
                "id": "OPERATORS_SPOF",
                "message": (
                    "Quantidade de operadores habilitados abaixo do minimo "
                    f"({operators['enabled_operator_count']} < {require_min_enabled_operators})."
                ),
            }
        )
    elif not bool(operators["backup_operator_enabled"]):
        violations.append(
            {
                "id": "OPERATORS_BACKUP_DISABLED",
                "message": "Backup operator configurado, mas nao habilitado.",
            }
        )

    if bool(ci_shell["exists"]) and len(ci_shell["god_scripts"]) > max_ci_god_scripts:
        violations.append(
            {
                "id": "CI_GOD_SCRIPTS_EXCESS",
                "message": (
                    "Quantidade de scripts CI acima do limite de complexidade "
                    f"({len(ci_shell['god_scripts'])} > {max_ci_god_scripts})."
                ),
            }
        )

    typed_pct = float(phase1_reconstruction["critical_checks_typed_pct"])
    if typed_pct < require_min_typed_critical_checks_pct:
        violations.append(
            {
                "id": "PHASE1_TYPED_CHECKS_BELOW_TARGET",
                "message": (
                    "Percentual de checks criticos tipados abaixo do minimo "
                    f"({typed_pct} < {require_min_typed_critical_checks_pct})."
                ),
            }
        )

    e2e_chaos_total = int(phase1_reconstruction["e2e_chaos_total_test_files"])
    if e2e_chaos_total < require_min_e2e_chaos_tests:
        violations.append(
            {
                "id": "PHASE1_E2E_CHAOS_BELOW_TARGET",
                "message": (
                    "Cobertura minima de testes e2e/chaos abaixo do alvo "
                    f"({e2e_chaos_total} < {require_min_e2e_chaos_tests})."
                ),
            }
        )

    return violations


def main() -> int:
    args = parse_args()
    root = Path(args.root).resolve()

    codeowners = collect_codeowners_metrics(root)
    operators = collect_operator_metrics(root)
    ci_shell = collect_ci_shell_metrics(root, args.god_script_threshold_lines)
    policy_tests = collect_policy_test_metrics(root)
    phase1_reconstruction = collect_phase1_reconstruction_metrics(root)

    violations = evaluate_violations(
        codeowners=codeowners,
        operators=operators,
        ci_shell=ci_shell,
        phase1_reconstruction=phase1_reconstruction,
        require_min_global_owners=args.require_min_global_owners,
        require_min_enabled_operators=args.require_min_enabled_operators,
        max_ci_god_scripts=args.max_ci_god_scripts,
        require_min_typed_critical_checks_pct=args.require_min_typed_critical_checks_pct,
        require_min_e2e_chaos_tests=args.require_min_e2e_chaos_tests,
    )

    payload = {
        "schema_version": "1.0",
        "generated_at": dt.datetime.now(tz=dt.timezone.utc)
        .replace(microsecond=0)
        .isoformat()
        .replace("+00:00", "Z"),
        "status": "PASS" if not violations else "FAIL",
        "kpis": {
            "codeowners": codeowners,
            "operators": operators,
            "ci_shell": ci_shell,
            "policy_engine_tests": policy_tests,
            "phase1_reconstruction": phase1_reconstruction,
        },
        "thresholds": {
            "require_min_global_owners": args.require_min_global_owners,
            "require_min_enabled_operators": args.require_min_enabled_operators,
            "max_ci_god_scripts": args.max_ci_god_scripts,
            "god_script_threshold_lines": args.god_script_threshold_lines,
            "require_min_typed_critical_checks_pct": args.require_min_typed_critical_checks_pct,
            "require_min_e2e_chaos_tests": args.require_min_e2e_chaos_tests,
        },
        "violations": violations,
    }

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(payload, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")

    if violations:
        print("governance-kpis-check: FAIL")
        for violation in violations:
            print(f"- {violation['id']}: {violation['message']}")
        return 1

    print("governance-kpis-check: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
