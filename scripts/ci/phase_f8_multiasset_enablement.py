#!/usr/bin/env python3
from __future__ import annotations

import argparse
import copy
import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SHADOW_DIR = ROOT / "artifacts/trading/shadow_mode"
DEFAULT_FIXTURE_DIR = ROOT / "scripts/ci/fixtures/trading/multiasset/shadow"
DEFAULT_REPORT_PATH = ROOT / "artifacts/phase-f8/epic-f8-04-multiasset-enablement.md"
DECISION_SCHEMA_PATH = ROOT / "ARC/schemas/decision.schema.json"
ASSET_CLASSES = ("equities_br", "fii_br", "fixed_income_br")
EXPECTED_BACKLOG = ["B2-01", "B2-02", "B2-03", "B2-04", "B2-05"]
EXPECTED_EVAL_REF = {
    "equities_br": "make eval-trading-equities_br",
    "fii_br": "make eval-trading-fii_br",
    "fixed_income_br": "make eval-trading-fixed_income_br",
}
SHADOW_FILE_GLOB = {
    "equities_br": "SHADOW-F8-04-EQUITIES-BR-*.json",
    "fii_br": "SHADOW-F8-04-FII-BR-*.json",
    "fixed_income_br": "SHADOW-F8-04-FIXED-INCOME-BR-*.json",
}


class MultiassetEnablementError(RuntimeError):
    pass


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    render_parser = subparsers.add_parser("render")
    render_parser.add_argument("--report-path", default=str(DEFAULT_REPORT_PATH))
    render_parser.add_argument("--week-id", required=True)
    render_parser.add_argument("--source-of-truth", default="PRD/PRD-MASTER.md")
    render_parser.add_argument("--shadow-dir", default=str(DEFAULT_SHADOW_DIR))

    parse_parser = subparsers.add_parser("parse")
    parse_parser.add_argument("--report-path", default=str(DEFAULT_REPORT_PATH))

    check_parser = subparsers.add_parser("check")
    check_parser.add_argument("--week-id", required=True)
    check_parser.add_argument("--report-path", default=str(DEFAULT_REPORT_PATH))
    check_parser.add_argument("--shadow-dir", default=str(DEFAULT_SHADOW_DIR))
    check_parser.add_argument("--fixture-dir", default=str(DEFAULT_FIXTURE_DIR))

    return parser.parse_args()


def normalize_path(value: str) -> Path:
    path = Path(value)
    if not path.is_absolute():
        path = ROOT / path
    return path


def display_path(path: Path) -> str:
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


def load_json(path: Path) -> object:
    if not path.exists():
        raise MultiassetEnablementError(f"arquivo ausente: {display_path(path)}")
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def expect_dict(value: object, label: str) -> dict[str, object]:
    if not isinstance(value, dict):
        raise MultiassetEnablementError(f"{label} deve ser objeto JSON.")
    return value


def expect_string(value: object, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise MultiassetEnablementError(f"{label} deve ser string nao vazia.")
    return value.strip()


def expect_optional_string(value: object, label: str) -> str | None:
    if value is None:
        return None
    return expect_string(value, label)


def expect_int(value: object, label: str) -> int:
    if not isinstance(value, int) or value < 0:
        raise MultiassetEnablementError(f"{label} deve ser inteiro >= 0.")
    return value


def expect_list(value: object, label: str) -> list[object]:
    if not isinstance(value, list):
        raise MultiassetEnablementError(f"{label} deve ser lista JSON.")
    return value


def expect_non_empty_list(value: object, label: str) -> list[object]:
    items = expect_list(value, label)
    if not items:
        raise MultiassetEnablementError(f"{label} deve ser lista nao vazia.")
    return items


def expect_string_list(value: object, label: str) -> list[str]:
    items = expect_list(value, label)
    normalized: list[str] = []
    for index, item in enumerate(items):
        normalized.append(expect_string(item, f"{label}[{index}]"))
    return normalized


def validate_file_exists(path_str: str, label: str) -> str:
    path = normalize_path(path_str)
    if not path.exists():
        raise MultiassetEnablementError(f"{label} referencia arquivo ausente: {path_str}")
    return display_path(path)


def latest_shadow_path(shadow_dir: Path, asset_class: str) -> Path:
    matches = sorted(shadow_dir.glob(SHADOW_FILE_GLOB[asset_class]))
    if not matches:
        raise MultiassetEnablementError(
            f"sem shadow review canonico para {asset_class} em {display_path(shadow_dir)}"
        )
    return matches[-1]


def load_decision_schema_required_fields() -> set[str]:
    payload = expect_dict(load_json(DECISION_SCHEMA_PATH), display_path(DECISION_SCHEMA_PATH))
    required = set(expect_string_list(payload.get("required"), f"{display_path(DECISION_SCHEMA_PATH)}.required"))
    required_fields = {
        "decision_id",
        "risk_tier",
        "status",
        "explicit_human_approval",
        "approval_evidence_ref",
    }
    missing = sorted(required_fields - required)
    if missing:
        raise MultiassetEnablementError(
            f"{display_path(DECISION_SCHEMA_PATH)} sem campos obrigatorios esperados: {', '.join(missing)}"
        )
    return required


def validate_decision_payload(
    *,
    decision_ref: str,
    expected_decision_id: str,
    expected_decision_status: str,
    expected_risk_tier: str,
) -> str:
    load_decision_schema_required_fields()
    decision_path = normalize_path(decision_ref)
    payload = expect_dict(load_json(decision_path), display_path(decision_path))

    decision_id = expect_string(payload.get("decision_id"), f"{display_path(decision_path)}.decision_id")
    if decision_id != expected_decision_id:
        raise MultiassetEnablementError(
            f"{display_path(decision_path)} com decision_id divergente de shadow review."
        )

    risk_tier = expect_string(payload.get("risk_tier"), f"{display_path(decision_path)}.risk_tier")
    if risk_tier != expected_risk_tier:
        raise MultiassetEnablementError(
            f"{display_path(decision_path)} com risk_tier divergente: {risk_tier}"
        )

    status = expect_string(payload.get("status"), f"{display_path(decision_path)}.status")
    if status != expected_decision_status:
        raise MultiassetEnablementError(
            f"{display_path(decision_path)} com status divergente: {status}"
        )

    explicit_human_approval = payload.get("explicit_human_approval")
    if explicit_human_approval is not True:
        raise MultiassetEnablementError(
            f"{display_path(decision_path)} deve usar explicit_human_approval=true."
        )

    approval_evidence_ref = expect_string(
        payload.get("approval_evidence_ref"),
        f"{display_path(decision_path)}.approval_evidence_ref",
    )
    validate_file_exists(approval_evidence_ref, "approval_evidence_ref")
    return display_path(decision_path)


def validate_shadow_payload(
    payload: object,
    asset_class: str,
    mode: str,
    source_path: Path,
) -> dict[str, object]:
    data = expect_dict(payload, display_path(source_path))
    if data.get("schema_version") != "1.0":
        raise MultiassetEnablementError(f"{display_path(source_path)} com schema_version invalido.")
    if data.get("asset_class") != asset_class:
        raise MultiassetEnablementError(f"{display_path(source_path)} com asset_class divergente.")

    shadow_review_id = expect_string(data.get("shadow_review_id"), f"{display_path(source_path)}.shadow_review_id")
    asset_profile_ref = validate_file_exists(
        expect_string(data.get("asset_profile_ref"), f"{display_path(source_path)}.asset_profile_ref"),
        "asset_profile_ref",
    )
    validator_profile_ref = validate_file_exists(
        expect_string(data.get("validator_profile_ref"), f"{display_path(source_path)}.validator_profile_ref"),
        "validator_profile_ref",
    )
    eval_suite_ref = expect_string(data.get("eval_suite_ref"), f"{display_path(source_path)}.eval_suite_ref")
    if eval_suite_ref != EXPECTED_EVAL_REF[asset_class]:
        raise MultiassetEnablementError(f"{display_path(source_path)} com eval_suite_ref invalido para {asset_class}.")

    status = expect_string(data.get("status"), f"{display_path(source_path)}.status")
    if status not in {"pending_shadow", "completed"}:
        raise MultiassetEnablementError(f"{display_path(source_path)} com status invalido: {status}")

    stability_window = expect_dict(data.get("stability_window"), f"{display_path(source_path)}.stability_window")
    window_label = expect_string(
        stability_window.get("window_label"),
        f"{display_path(source_path)}.stability_window.window_label",
    )
    required_sessions = expect_int(
        stability_window.get("required_sessions"),
        f"{display_path(source_path)}.stability_window.required_sessions",
    )
    completed_sessions = expect_int(
        stability_window.get("completed_sessions"),
        f"{display_path(source_path)}.stability_window.completed_sessions",
    )
    if completed_sessions > required_sessions:
        raise MultiassetEnablementError(f"{display_path(source_path)} com completed_sessions > required_sessions.")

    stability_checks = expect_non_empty_list(data.get("stability_checks"), f"{display_path(source_path)}.stability_checks")
    for index, item in enumerate(stability_checks):
        entry = expect_dict(item, f"{display_path(source_path)}.stability_checks[{index}]")
        expect_string(entry.get("check_id"), f"{display_path(source_path)}.stability_checks[{index}].check_id")
        check_status = expect_string(
            entry.get("status"),
            f"{display_path(source_path)}.stability_checks[{index}].status",
        )
        if check_status not in {"pass", "fail", "pending"}:
            raise MultiassetEnablementError(
                f"{display_path(source_path)}.stability_checks[{index}] com status invalido: {check_status}"
            )
        expect_string(entry.get("notes"), f"{display_path(source_path)}.stability_checks[{index}].notes")

    decision_id = expect_string(data.get("decision_id"), f"{display_path(source_path)}.decision_id")
    decision_status = expect_string(data.get("decision_status"), f"{display_path(source_path)}.decision_status")
    if decision_status not in {"NOT_REQUIRED_YET", "PENDING", "APPROVED", "REJECTED"}:
        raise MultiassetEnablementError(f"{display_path(source_path)} com decision_status invalido: {decision_status}")

    risk_tier_raw = data.get("risk_tier")
    risk_tier = None
    if risk_tier_raw is not None:
        risk_tier = expect_string(risk_tier_raw, f"{display_path(source_path)}.risk_tier")
        if risk_tier not in {"R0", "R1", "R2", "R3"}:
            raise MultiassetEnablementError(f"{display_path(source_path)} com risk_tier invalido: {risk_tier}")

    decision_ref_raw = data.get("decision_ref")
    decision_ref = expect_optional_string(decision_ref_raw, f"{display_path(source_path)}.decision_ref")
    shadow_evidence_refs = expect_string_list(
        data.get("shadow_evidence_refs"),
        f"{display_path(source_path)}.shadow_evidence_refs",
    )
    for index, evidence_ref in enumerate(shadow_evidence_refs):
        validate_file_exists(evidence_ref, f"shadow_evidence_refs[{index}]")

    promote_readiness = expect_string(data.get("promote_readiness"), f"{display_path(source_path)}.promote_readiness")
    if promote_readiness not in {"hold", "pass"}:
        raise MultiassetEnablementError(f"{display_path(source_path)} com promote_readiness invalido: {promote_readiness}")
    expect_string(data.get("notes"), f"{display_path(source_path)}.notes")

    decision_ref_display = "none"
    if status == "pending_shadow":
        if decision_ref is not None:
            raise MultiassetEnablementError(f"{display_path(source_path)} com pending_shadow exige decision_ref=null.")
        if shadow_evidence_refs:
            raise MultiassetEnablementError(f"{display_path(source_path)} com pending_shadow exige shadow_evidence_refs=[].")
        if promote_readiness != "hold":
            raise MultiassetEnablementError(f"{display_path(source_path)} com pending_shadow exige promote_readiness=hold.")
    elif status == "completed":
        if decision_status != "APPROVED":
            raise MultiassetEnablementError(f"{display_path(source_path)} com completed exige decision_status=APPROVED.")
        if decision_id == "not-issued":
            raise MultiassetEnablementError(f"{display_path(source_path)} com completed exige decision_id emitida.")
        if risk_tier != "R3":
            raise MultiassetEnablementError(f"{display_path(source_path)} com completed exige risk_tier=R3.")
        if decision_ref is None:
            raise MultiassetEnablementError(f"{display_path(source_path)} com completed exige decision_ref.")
        if not shadow_evidence_refs:
            raise MultiassetEnablementError(f"{display_path(source_path)} com completed exige shadow_evidence_refs nao vazios.")
        decision_ref_display = validate_decision_payload(
            decision_ref=decision_ref,
            expected_decision_id=decision_id,
            expected_decision_status="APPROVED",
            expected_risk_tier="R3",
        )
        if promote_readiness != "pass":
            raise MultiassetEnablementError(f"{display_path(source_path)} com completed exige promote_readiness=pass.")
        if completed_sessions < required_sessions:
            raise MultiassetEnablementError(f"{display_path(source_path)} com completed exige janela completa.")
    else:
        raise MultiassetEnablementError(f"{display_path(source_path)} com status invalido: {status}")

    if mode == "fixture_positive" and status != "completed":
        raise MultiassetEnablementError(f"{display_path(source_path)} fixture positiva deve usar status=completed.")
    if mode not in {"runtime", "fixture_positive"}:
        raise MultiassetEnablementError(f"modo invalido: {mode}")

    adapter_path = ROOT / "VERTICALS/TRADING/venue_adapters" / f"{asset_class}.json"
    if not adapter_path.exists():
        raise MultiassetEnablementError(f"adapter ausente para {asset_class}: {display_path(adapter_path)}")

    evidence_refs = [display_path(source_path)]
    if decision_ref_display != "none":
        evidence_refs.append(decision_ref_display)
    evidence_refs.extend(validate_file_exists(ref, "shadow_evidence_ref") for ref in shadow_evidence_refs)

    return {
        "asset_class": asset_class,
        "shadow_review_id": shadow_review_id,
        "schema_status": "PASS",
        "adapter_status": "PASS",
        "validator_status": "PASS",
        "suite_status": "PASS",
        "shadow_status": status,
        "decision_id": decision_id,
        "decision_status": decision_status,
        "decision_ref": decision_ref_display,
        "promote_readiness": promote_readiness,
        "evidence_refs": evidence_refs,
        "window_label": window_label,
        "asset_profile_ref": asset_profile_ref,
        "validator_profile_ref": validator_profile_ref,
    }


def canonical_rows(shadow_dir: Path) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    for asset_class in ASSET_CLASSES:
        path = latest_shadow_path(shadow_dir, asset_class)
        rows.append(validate_shadow_payload(load_json(path), asset_class, "runtime", path))
    return rows


def collect_evidence_refs(rows: list[dict[str, object]]) -> list[str]:
    refs: list[str] = []
    for row in rows:
        for ref in row["evidence_refs"]:
            if ref not in refs:
                refs.append(ref)
    return refs


def render_report(args: argparse.Namespace) -> None:
    report_path = normalize_path(args.report_path)
    shadow_dir = normalize_path(args.shadow_dir)
    rows = canonical_rows(shadow_dir)
    overall = "pass" if all(row["promote_readiness"] == "pass" for row in rows) else "hold"
    report_path.parent.mkdir(parents=True, exist_ok=True)

    lines = [
        f"# F8 Multiasset Enablement {args.week_id}",
        "",
        f"- week_id: `{args.week_id}`",
        f"- source_of_truth: `{args.source_of_truth}`",
        f"- artifact_status: `PASS`",
        f"- overall_promote_readiness: `{overall}`",
        f"- reviewed_classes: `{','.join(ASSET_CLASSES)}`",
        "",
        "## Class Status",
        "",
        "| Asset Class | Schema | Adapter | Validator | Suite | Shadow Mode | Decision ID | Decision Status | Promote Readiness |",
        "|---|---|---|---|---|---|---|---|---|",
    ]

    for row in rows:
        lines.append(
            f"| `{row['asset_class']}` | `{row['schema_status']}` | `{row['adapter_status']}` | `{row['validator_status']}` | `{row['suite_status']}` | `{row['shadow_status']}` | `{row['decision_id']}` | `{row['decision_status']}` | `{row['promote_readiness']}` |"
        )

    lines.extend(["", "## Backlog Coverage", ""])
    for backlog_id in EXPECTED_BACKLOG:
        lines.append(f"- `{backlog_id}`")

    lines.extend(["", "## Evidence Refs", ""])
    for ref in collect_evidence_refs(rows):
        lines.append(f"- `{ref}`")

    report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def parse_report(report_path: Path) -> dict[str, object]:
    text = report_path.read_text(encoding="utf-8")
    values: dict[str, str] = {}
    for key in ("week_id", "source_of_truth", "artifact_status", "overall_promote_readiness", "reviewed_classes"):
        match = re.search(rf"^- {re.escape(key)}: `([^`]+)`$", text, re.M)
        if not match:
            raise MultiassetEnablementError(f"{display_path(report_path)} sem campo obrigatorio: {key}")
        values[key] = match.group(1)

    rows: list[dict[str, str]] = []
    row_pattern = re.compile(
        r"^\| `(equities_br|fii_br|fixed_income_br)` \| `([^`]+)` \| `([^`]+)` \| `([^`]+)` \| `([^`]+)` \| `([^`]+)` \| `([^`]+)` \| `([^`]+)` \| `([^`]+)` \|$",
        re.M,
    )
    for match in row_pattern.finditer(text):
        rows.append(
            {
                "asset_class": match.group(1),
                "schema_status": match.group(2),
                "adapter_status": match.group(3),
                "validator_status": match.group(4),
                "suite_status": match.group(5),
                "shadow_status": match.group(6),
                "decision_id": match.group(7),
                "decision_status": match.group(8),
                "promote_readiness": match.group(9),
            }
        )
    if len(rows) != len(ASSET_CLASSES):
        raise MultiassetEnablementError(f"{display_path(report_path)} sem linhas suficientes em Class Status.")

    backlog_section = re.search(r"## Backlog Coverage(.*?)(?:\n## |\Z)", text, re.S)
    if not backlog_section:
        raise MultiassetEnablementError(f"{display_path(report_path)} sem secao Backlog Coverage.")
    backlog = re.findall(r"^- `([^`]+)`$", backlog_section.group(1), re.M)
    if not backlog:
        raise MultiassetEnablementError(f"{display_path(report_path)} sem backlog refs.")

    evidence_section = re.search(r"## Evidence Refs(.*?)(?:\n## |\Z)", text, re.S)
    if not evidence_section:
        raise MultiassetEnablementError(f"{display_path(report_path)} sem secao Evidence Refs.")
    evidence_refs = re.findall(r"^- `([^`]+)`$", evidence_section.group(1), re.M)
    if not evidence_refs:
        raise MultiassetEnablementError(f"{display_path(report_path)} sem evidence refs.")

    return {
        "values": values,
        "rows": rows,
        "backlog": backlog,
        "evidence_refs": evidence_refs,
        "text": text,
    }


def check_report(report_path: Path, shadow_dir: Path, fixture_dir: Path, week_id: str) -> None:
    rows = canonical_rows(shadow_dir)

    fixture_paths = sorted(fixture_dir.glob("*.json"))
    if len(fixture_paths) < 1:
        raise MultiassetEnablementError(f"sem fixtures positivas em {display_path(fixture_dir)}")

    def assert_fixture_invalid(payload: dict[str, object], asset_class: str, fixture_path: Path, case: str) -> None:
        try:
            validate_shadow_payload(payload, asset_class, "fixture_positive", fixture_path)
        except MultiassetEnablementError:
            return
        raise MultiassetEnablementError(
            f"{display_path(fixture_path)} deveria falhar no cenario negativo: {case}"
        )

    for fixture_path in fixture_paths:
        payload = expect_dict(load_json(fixture_path), display_path(fixture_path))
        asset_class = expect_string(
            payload.get("asset_class"),
            f"{display_path(fixture_path)}.asset_class",
        )
        validate_shadow_payload(payload, asset_class, "fixture_positive", fixture_path)

        missing_decision_ref = copy.deepcopy(payload)
        missing_decision_ref["decision_ref"] = None
        assert_fixture_invalid(missing_decision_ref, asset_class, fixture_path, "completed sem decision_ref")

        empty_shadow_evidence = copy.deepcopy(payload)
        empty_shadow_evidence["shadow_evidence_refs"] = []
        assert_fixture_invalid(
            empty_shadow_evidence,
            asset_class,
            fixture_path,
            "completed com shadow_evidence_refs vazio",
        )

        mismatched_decision_id = copy.deepcopy(payload)
        mismatched_decision_id["decision_id"] = "DEC-MISMATCH"
        assert_fixture_invalid(
            mismatched_decision_id,
            asset_class,
            fixture_path,
            "decision_id divergente entre shadow e decision_ref",
        )

    parsed = parse_report(report_path)
    values = parsed["values"]
    if values["week_id"] != week_id:
        raise MultiassetEnablementError(f"{display_path(report_path)} com week_id invalido: {values['week_id']}")
    if values["source_of_truth"] != "PRD/PRD-MASTER.md":
        raise MultiassetEnablementError(f"{display_path(report_path)} com source_of_truth invalido.")
    if values["artifact_status"] != "PASS":
        raise MultiassetEnablementError(f"{display_path(report_path)} com artifact_status invalido.")
    expected_overall = "pass" if all(row["promote_readiness"] == "pass" for row in rows) else "hold"
    if values["overall_promote_readiness"] != expected_overall:
        raise MultiassetEnablementError(
            f"{display_path(report_path)} com overall_promote_readiness divergente: {values['overall_promote_readiness']} != {expected_overall}"
        )
    if values["reviewed_classes"] != ",".join(ASSET_CLASSES):
        raise MultiassetEnablementError(f"{display_path(report_path)} com reviewed_classes invalido.")
    if parsed["backlog"] != EXPECTED_BACKLOG:
        raise MultiassetEnablementError(f"{display_path(report_path)} com backlog divergente.")

    row_map = {row["asset_class"]: row for row in rows}
    for parsed_row in parsed["rows"]:
        expected_row = row_map.get(parsed_row["asset_class"])
        if expected_row is None:
            raise MultiassetEnablementError(f"{display_path(report_path)} com asset_class inesperada.")
        for key in (
            "schema_status",
            "adapter_status",
            "validator_status",
            "suite_status",
            "shadow_status",
            "decision_id",
            "decision_status",
            "promote_readiness",
        ):
            if parsed_row[key] != expected_row[key]:
                raise MultiassetEnablementError(
                    f"{display_path(report_path)} divergente para {parsed_row['asset_class']} no campo {key}."
                )

    expected_evidence = collect_evidence_refs(rows)
    if parsed["evidence_refs"] != expected_evidence:
        raise MultiassetEnablementError(f"{display_path(report_path)} com evidence refs divergentes.")


def main() -> None:
    args = parse_args()
    if args.command == "render":
        render_report(args)
        return
    if args.command == "parse":
        payload = parse_report(normalize_path(args.report_path))
        print(json.dumps(payload, ensure_ascii=True))
        return
    if args.command == "check":
        check_report(
            normalize_path(args.report_path),
            normalize_path(args.shadow_dir),
            normalize_path(args.fixture_dir),
            args.week_id,
        )
        print("phase-f8-multiasset-enablement: PASS")
        return
    raise MultiassetEnablementError(f"comando invalido: {args.command}")


if __name__ == "__main__":
    try:
        main()
    except MultiassetEnablementError as exc:
        print(str(exc))
        sys.exit(1)
