#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SHADOW_DIR = ROOT / "artifacts/trading/shadow_mode"
DEFAULT_FIXTURE_DIR = ROOT / "scripts/ci/fixtures/trading/multiasset/shadow"
DEFAULT_REPORT_PATH = ROOT / "artifacts/phase-f8/epic-f8-04-multiasset-enablement.md"
ASSET_CLASSES = ("equities_br", "fii_br", "fixed_income_br")
EXPECTED_BACKLOG = ["B2-01", "B2-02", "B2-03", "B2-04", "B2-05"]
EXPECTED_EVAL_REF = {
    "equities_br": "make eval-trading-equities_br",
    "fii_br": "make eval-trading-fii_br",
    "fixed_income_br": "make eval-trading-fixed_income_br",
}
EXPECTED_SHADOW_FILE = {
    "equities_br": "SHADOW-F8-04-EQUITIES-BR-20260301-01.json",
    "fii_br": "SHADOW-F8-04-FII-BR-20260301-01.json",
    "fixed_income_br": "SHADOW-F8-04-FIXED-INCOME-BR-20260301-01.json",
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


def expect_int(value: object, label: str) -> int:
    if not isinstance(value, int) or value < 0:
        raise MultiassetEnablementError(f"{label} deve ser inteiro >= 0.")
    return value


def expect_list(value: object, label: str) -> list[object]:
    if not isinstance(value, list) or not value:
        raise MultiassetEnablementError(f"{label} deve ser lista nao vazia.")
    return value


def validate_file_exists(path_str: str, label: str) -> str:
    path = normalize_path(path_str)
    if not path.exists():
      raise MultiassetEnablementError(f"{label} referencia arquivo ausente: {path_str}")
    return path_str


def validate_shadow_payload(payload: object, asset_class: str, mode: str, source_path: Path) -> dict[str, str]:
    data = expect_dict(payload, display_path(source_path))
    if data.get("schema_version") != "1.0":
        raise MultiassetEnablementError(f"{display_path(source_path)} com schema_version invalido.")
    if data.get("asset_class") != asset_class:
        raise MultiassetEnablementError(f"{display_path(source_path)} com asset_class divergente.")
    shadow_review_id = expect_string(data.get("shadow_review_id"), f"{display_path(source_path)}.shadow_review_id")
    asset_profile_ref = validate_file_exists(expect_string(data.get("asset_profile_ref"), f"{display_path(source_path)}.asset_profile_ref"), "asset_profile_ref")
    validator_profile_ref = validate_file_exists(expect_string(data.get("validator_profile_ref"), f"{display_path(source_path)}.validator_profile_ref"), "validator_profile_ref")
    eval_suite_ref = expect_string(data.get("eval_suite_ref"), f"{display_path(source_path)}.eval_suite_ref")
    if eval_suite_ref != EXPECTED_EVAL_REF[asset_class]:
        raise MultiassetEnablementError(f"{display_path(source_path)} com eval_suite_ref invalido para {asset_class}.")
    status = expect_string(data.get("status"), f"{display_path(source_path)}.status")
    if status not in {"pending_shadow", "completed"}:
        raise MultiassetEnablementError(f"{display_path(source_path)} com status invalido: {status}")
    stability_window = expect_dict(data.get("stability_window"), f"{display_path(source_path)}.stability_window")
    window_label = expect_string(stability_window.get("window_label"), f"{display_path(source_path)}.stability_window.window_label")
    required_sessions = expect_int(stability_window.get("required_sessions"), f"{display_path(source_path)}.stability_window.required_sessions")
    completed_sessions = expect_int(stability_window.get("completed_sessions"), f"{display_path(source_path)}.stability_window.completed_sessions")
    if completed_sessions > required_sessions:
        raise MultiassetEnablementError(f"{display_path(source_path)} com completed_sessions > required_sessions.")
    stability_checks = expect_list(data.get("stability_checks"), f"{display_path(source_path)}.stability_checks")
    for index, item in enumerate(stability_checks):
        entry = expect_dict(item, f"{display_path(source_path)}.stability_checks[{index}]")
        expect_string(entry.get("check_id"), f"{display_path(source_path)}.stability_checks[{index}].check_id")
        check_status = expect_string(entry.get("status"), f"{display_path(source_path)}.stability_checks[{index}].status")
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
    promote_readiness = expect_string(data.get("promote_readiness"), f"{display_path(source_path)}.promote_readiness")
    if promote_readiness not in {"hold", "pass"}:
        raise MultiassetEnablementError(f"{display_path(source_path)} com promote_readiness invalido: {promote_readiness}")
    expect_string(data.get("notes"), f"{display_path(source_path)}.notes")

    if mode == "canonical":
        if status != "pending_shadow":
            raise MultiassetEnablementError(f"{display_path(source_path)} deve permanecer pending_shadow nesta rodada.")
        if decision_id != "not-issued":
            raise MultiassetEnablementError(f"{display_path(source_path)} deve usar decision_id=not-issued nesta rodada.")
        if decision_status != "NOT_REQUIRED_YET":
            raise MultiassetEnablementError(f"{display_path(source_path)} deve usar decision_status=NOT_REQUIRED_YET nesta rodada.")
        if promote_readiness != "hold":
            raise MultiassetEnablementError(f"{display_path(source_path)} deve permanecer hold nesta rodada.")
    elif mode == "fixture":
        if status != "completed":
            raise MultiassetEnablementError(f"{display_path(source_path)} fixture positiva deve usar status=completed.")
        if decision_status != "APPROVED":
            raise MultiassetEnablementError(f"{display_path(source_path)} fixture positiva deve usar decision_status=APPROVED.")
        if decision_id == "not-issued":
            raise MultiassetEnablementError(f"{display_path(source_path)} fixture positiva exige decision_id emitida.")
        if risk_tier != "R3":
            raise MultiassetEnablementError(f"{display_path(source_path)} fixture positiva exige risk_tier=R3.")
        if promote_readiness != "pass":
            raise MultiassetEnablementError(f"{display_path(source_path)} fixture positiva exige promote_readiness=pass.")
        if completed_sessions < required_sessions:
            raise MultiassetEnablementError(f"{display_path(source_path)} fixture positiva exige janela completa.")
    else:
        raise MultiassetEnablementError(f"modo invalido: {mode}")

    adapter_path = ROOT / "VERTICALS/TRADING/venue_adapters" / f"{asset_class}.json"
    if not adapter_path.exists():
        raise MultiassetEnablementError(f"adapter ausente para {asset_class}: {display_path(adapter_path)}")

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
        "promote_readiness": promote_readiness,
        "evidence_ref": display_path(source_path),
        "window_label": window_label,
    }


def canonical_rows(shadow_dir: Path) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for asset_class in ASSET_CLASSES:
        path = shadow_dir / EXPECTED_SHADOW_FILE[asset_class]
        rows.append(validate_shadow_payload(load_json(path), asset_class, "canonical", path))
    return rows


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

    lines.extend(
        [
            "",
            "## Backlog Coverage",
            "",
        ]
    )
    for backlog_id in EXPECTED_BACKLOG:
        lines.append(f"- `{backlog_id}`")

    lines.extend(
        [
            "",
            "## Evidence Refs",
            "",
        ]
    )
    for row in rows:
        lines.append(f"- `{row['evidence_ref']}`")

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


def check_report(report_path: Path, shadow_dir: Path, fixture_dir: Path) -> None:
    rows = canonical_rows(shadow_dir)
    if any(row["promote_readiness"] != "hold" for row in rows):
        raise MultiassetEnablementError("os artifacts canonicos desta rodada devem permanecer em hold.")
    fixture_paths = sorted(fixture_dir.glob("*.json"))
    if len(fixture_paths) < 1:
        raise MultiassetEnablementError(f"sem fixtures positivas em {display_path(fixture_dir)}")
    for fixture_path in fixture_paths:
        payload = load_json(fixture_path)
        asset_class = expect_string(expect_dict(payload, display_path(fixture_path)).get("asset_class"), f"{display_path(fixture_path)}.asset_class")
        validate_shadow_payload(payload, asset_class, "fixture", fixture_path)

    parsed = parse_report(report_path)
    values = parsed["values"]
    if values["week_id"] != "2026-W09":
        raise MultiassetEnablementError(f"{display_path(report_path)} com week_id invalido: {values['week_id']}")
    if values["source_of_truth"] != "PRD/PRD-MASTER.md":
        raise MultiassetEnablementError(f"{display_path(report_path)} com source_of_truth invalido.")
    if values["artifact_status"] != "PASS":
        raise MultiassetEnablementError(f"{display_path(report_path)} com artifact_status invalido.")
    if values["overall_promote_readiness"] != "hold":
        raise MultiassetEnablementError(f"{display_path(report_path)} deve manter overall_promote_readiness=hold.")
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

    expected_evidence = [row["evidence_ref"] for row in rows]
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
