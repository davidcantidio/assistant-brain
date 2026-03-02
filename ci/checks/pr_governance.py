from __future__ import annotations

import argparse
import sys
from pathlib import Path


def _policy_engine_src(root: Path) -> Path:
    return root / "platform/policy-engine/src"


def _load_helpers(root: Path):
    policy_engine_src = _policy_engine_src(root)
    if str(policy_engine_src) not in sys.path:
        sys.path.append(str(policy_engine_src))
    from policy_engine.utils.codeowners import global_owners, parse_codeowners_file
    from policy_engine.utils.yaml_loader import load_yaml_file

    return global_owners, parse_codeowners_file, load_yaml_file


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate PR governance contract")
    parser.add_argument("--root", default=".")
    parser.add_argument("--contract", default="contracts/governance/review_governance.v1.json")
    parser.add_argument("--codeowners", default=".github/CODEOWNERS")
    parser.add_argument("--policy-doc", default="DEV/DEV-CI-RULES.md")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = Path(args.root).resolve()
    global_owners, parse_codeowners_file, load_yaml_file = _load_helpers(root)

    import json

    contract_path = root / args.contract
    codeowners_path = root / args.codeowners
    policy_doc_path = root / args.policy_doc
    if not contract_path.exists():
        print(f"pr-governance-check: FAIL - contrato ausente: {args.contract}")
        return 1
    if not codeowners_path.exists():
        print(f"pr-governance-check: FAIL - arquivo obrigatorio ausente: {args.codeowners}")
        return 1
    if not policy_doc_path.exists():
        print(f"pr-governance-check: FAIL - documento de policy ausente: {args.policy_doc}")
        return 1

    contract = json.loads(contract_path.read_text(encoding="utf-8"))
    rules = parse_codeowners_file(codeowners_path)
    owners = global_owners(rules)
    min_global_owners = int(contract["min_global_owners"])
    if len(owners) < min_global_owners:
        print(f"pr-governance-check: FAIL - regra global do CODEOWNERS abaixo do minimo ({len(owners)} < {min_global_owners}).")
        return 1

    patterns = [str(item) for item in contract["required_scoped_rules"]]
    rendered_rules = [rule.pattern for rule in rules if rule.pattern != "*"]
    for pattern in patterns:
        if pattern not in rendered_rules:
            print(f"pr-governance-check: FAIL - regra de ownership por dominio ausente em {args.codeowners}: {pattern}")
            return 1

    text = policy_doc_path.read_text(encoding="utf-8", errors="ignore")
    for term in contract["required_policy_terms"]:
        if term not in text:
            print(f"pr-governance-check: FAIL - termo normativo obrigatorio ausente em {args.policy_doc}: {term}")
            return 1

    operators = load_yaml_file(root / "SEC/allowlists/OPERATORS.yaml")
    if not isinstance(operators, dict):
        print("pr-governance-check: FAIL - OPERATORS.yaml invalido.")
        return 1
    readiness = operators.get("readiness", {})
    if not isinstance(readiness, dict):
        print("pr-governance-check: FAIL - readiness ausente em OPERATORS.yaml.")
        return 1
    backup_operator_id = readiness.get("backup_operator_operator_id")
    if contract["require_backup_operator"] and (not isinstance(backup_operator_id, str) or not backup_operator_id.strip()):
        print("pr-governance-check: FAIL - backup operator obrigatorio ausente em OPERATORS.yaml.")
        return 1
    if contract["require_live_ready_false_until_phase1_pass"] and readiness.get("live_ready") is not False:
        print("pr-governance-check: FAIL - live_ready deve permanecer false durante a fase 1.")
        return 1

    if contract["disallow_personal_owner_hardcode"]:
        current_script = (root / "scripts/ci/check_pr_governance.sh").read_text(encoding="utf-8", errors="ignore")
        if "@davidcantidio" in current_script:
            print("pr-governance-check: FAIL - hardcode pessoal encontrado em scripts/ci/check_pr_governance.sh.")
            return 1

    print("pr-governance-check: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
