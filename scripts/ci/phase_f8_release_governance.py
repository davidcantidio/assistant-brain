#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


WEEKLY_FIELD_ORDER = [
    "week_id",
    "executed_at",
    "source_of_truth",
    "prior_phase_decision",
    "phase_transition_status",
    "blocking_reason",
    "eval_gates_status",
    "ci_quality_status",
    "ci_security_status",
    "contract_review_status",
    "critical_drifts_open",
    "decision",
    "release_review_status",
    "release_justification",
    "residual_risk_summary",
    "rollback_plan",
    "summary_artifact",
    "risk_notes",
    "next_actions",
]

LOG_KEYS = ["eval-gates", "ci-quality", "ci-security"]
SUMMARY_FIELD_ORDER = [
    "week_id",
    "weekly_report",
    "decision",
    "release_review_status",
    "release_justification",
    "phase_transition_status",
    "blocking_reason",
    "residual_risk_summary",
    "rollback_plan",
    "next_actions",
    "contract_review_status",
    "critical_drifts_open",
]
SUMMARY_GATE_KEYS = [
    "eval_gates_status",
    "ci_quality_status",
    "ci_security_status",
]


def strip_ticks(value: str) -> str:
    value = value.strip()
    if value.startswith("`") and value.endswith("`"):
        return value[1:-1]
    return value


def read_prior_phase_status(summary_path: Path) -> dict[str, str]:
    if not summary_path.exists():
        return {
            "prior_phase_decision": "hold",
            "phase_transition_status": "blocked",
            "blocking_reason": "phase_transition_blocked: F7 validation summary ausente; F8 permanece recuada ate promote formal.",
        }

    text = summary_path.read_text(encoding="utf-8")
    section_match = re.search(
        r"## Decisao de fase \(F7 -> F8\)(.*?)(?:\n## |\Z)",
        text,
        re.S,
    )
    section_text = section_match.group(1) if section_match else text
    decision_match = re.search(r"^- decisao: `([^`]+)`$", section_text, re.M)
    prior_phase_decision = decision_match.group(1) if decision_match else "hold"

    if prior_phase_decision == "promote":
        return {
            "prior_phase_decision": "promote",
            "phase_transition_status": "ready",
            "blocking_reason": "none",
        }

    return {
        "prior_phase_decision": "hold",
        "phase_transition_status": "blocked",
        "blocking_reason": "phase_transition_blocked: F7 -> F8 permanece hold; ativacao prematura da F8 foi recuada ao contrato de promocao entre fases.",
    }


def emit_prior_phase_status(status: dict[str, str], fmt: str) -> None:
    if fmt == "json":
        print(json.dumps(status, ensure_ascii=True))
        return

    for key in ("prior_phase_decision", "phase_transition_status", "blocking_reason"):
        print(f"{key.upper()}={json.dumps(status[key], ensure_ascii=True)}")


def parse_weekly_report(report_path: Path) -> dict[str, object]:
    text = report_path.read_text(encoding="utf-8")
    values: dict[str, str] = {}
    logs: dict[str, str] = {}

    for key in WEEKLY_FIELD_ORDER:
        match = re.search(rf"^- {re.escape(key)}: (.+)$", text, re.M)
        if not match:
            raise ValueError(f"{report_path} sem campo obrigatorio: {key}")
        values[key] = strip_ticks(match.group(1))

    for key in LOG_KEYS:
        match = re.search(rf"^- {re.escape(key)}: `(.+?)`$", text, re.M)
        if not match:
            raise ValueError(f"{report_path} sem log obrigatorio: {key}")
        logs[key] = match.group(1)

    return {
        "values": values,
        "logs": logs,
        "field_order": WEEKLY_FIELD_ORDER,
        "text": text,
    }


def parse_epic_statuses(epics_path: Path) -> dict[str, str]:
    statuses: dict[str, str] = {}
    pattern = re.compile(
        r"^\|\s*`(EPIC-F8-\d{2})`\s*\|.*\|\s*([a-z]+)\s*\|\s*\[.+\]\(.+\)\s*\|$",
        re.M,
    )
    text = epics_path.read_text(encoding="utf-8")
    for match in pattern.finditer(text):
        statuses[match.group(1)] = match.group(2)
    if not statuses:
        raise ValueError(f"{epics_path} sem tabela de status de epics da F8.")
    return statuses


def collect_evidence_refs(week_id: str, weekly_report_path: Path) -> list[str]:
    refs = [
        f"artifacts/phase-f8/contract-review/{week_id}.md",
        str(weekly_report_path.as_posix()),
        "artifacts/phase-f8/epic-f8-03-issue-01-weekly-decision-criteria.md",
        "artifacts/phase-f8/epic-f8-03-issue-02-residual-risk-rollback.md",
        "artifacts/phase-f8/epic-f8-03-issue-03-executive-summary-audit.md",
        "artifacts/phase-f8/epic-f8-03-governanca-evolucao-release.md",
    ]
    return [ref for ref in refs if Path(ref).exists()]


def parse_validation_summary(summary_path: Path) -> dict[str, object]:
    text = summary_path.read_text(encoding="utf-8")
    values: dict[str, str] = {}
    gate_statuses: dict[str, str] = {}
    epic_statuses: dict[str, str] = {}
    evidence_refs: list[str] = []

    for key in SUMMARY_FIELD_ORDER:
        match = re.search(rf"^- {re.escape(key)}: (.+)$", text, re.M)
        if not match:
            raise ValueError(f"{summary_path} sem campo obrigatorio: {key}")
        values[key] = strip_ticks(match.group(1))

    for key in SUMMARY_GATE_KEYS:
        match = re.search(rf"^- {re.escape(key)}: `(.+?)`$", text, re.M)
        if not match:
            raise ValueError(f"{summary_path} sem gate obrigatorio: {key}")
        gate_statuses[key] = match.group(1)

    epic_section = re.search(r"## Epic Status(.*?)(?:\n## |\Z)", text, re.S)
    if not epic_section:
        raise ValueError(f"{summary_path} sem secao Epic Status.")
    for match in re.finditer(r"^- (EPIC-F8-\d{2}): `([^`]+)`$", epic_section.group(1), re.M):
        epic_statuses[match.group(1)] = match.group(2)
    if not epic_statuses:
        raise ValueError(f"{summary_path} sem status de epics.")

    evidence_section = re.search(r"## Evidence Refs(.*?)(?:\n## |\Z)", text, re.S)
    if not evidence_section:
        raise ValueError(f"{summary_path} sem secao Evidence Refs.")
    for match in re.finditer(r"^- `(.+?)`$", evidence_section.group(1), re.M):
        evidence_refs.append(match.group(1))
    if not evidence_refs:
        raise ValueError(f"{summary_path} sem referencias de evidencia.")

    return {
        "values": values,
        "gate_statuses": gate_statuses,
        "epic_statuses": epic_statuses,
        "evidence_refs": evidence_refs,
        "field_order": SUMMARY_FIELD_ORDER,
        "text": text,
    }


def render_weekly_report(args: argparse.Namespace) -> None:
    report_path = Path(args.report_path)
    report_path.parent.mkdir(parents=True, exist_ok=True)

    lines = [
        f"# F8 Weekly Governance {args.week_id}",
        "",
        f"- week_id: `{args.week_id}`",
        f"- executed_at: `{args.executed_at}`",
        f"- source_of_truth: `{args.source_of_truth}`",
        f"- prior_phase_decision: `{args.prior_phase_decision}`",
        f"- phase_transition_status: `{args.phase_transition_status}`",
        f"- blocking_reason: {args.blocking_reason}",
        f"- eval_gates_status: `{args.eval_gates_status}`",
        f"- ci_quality_status: `{args.ci_quality_status}`",
        f"- ci_security_status: `{args.ci_security_status}`",
        f"- contract_review_status: `{args.contract_review_status}`",
        f"- critical_drifts_open: `{args.critical_drifts_open}`",
        f"- decision: `{args.decision}`",
        f"- release_review_status: `{args.release_review_status}`",
        f"- release_justification: {args.release_justification}",
        f"- residual_risk_summary: {args.residual_risk_summary}",
        f"- rollback_plan: {args.rollback_plan}",
        f"- summary_artifact: `{args.summary_artifact}`",
        f"- risk_notes: {args.risk_notes}",
        f"- next_actions: {args.next_actions}",
        "",
        "## Logs",
        "",
        f"- eval-gates: `{args.eval_log_path}`",
        f"- ci-quality: `{args.quality_log_path}`",
        f"- ci-security: `{args.security_log_path}`",
    ]
    report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def render_validation_summary(args: argparse.Namespace) -> None:
    summary_path = Path(args.summary_path)
    summary_path.parent.mkdir(parents=True, exist_ok=True)

    weekly_payload = parse_weekly_report(Path(args.weekly_report_path))
    values = weekly_payload["values"]
    epic_statuses = parse_epic_statuses(Path(args.epics_path))
    evidence_refs = collect_evidence_refs(values["week_id"], Path(args.weekly_report_path))

    lines = [
        f"# F8 Validation Summary {values['week_id']}",
        "",
        f"- week_id: `{values['week_id']}`",
        f"- weekly_report: `{args.weekly_report_path}`",
        f"- decision: `{values['decision']}`",
        f"- release_review_status: `{values['release_review_status']}`",
        f"- release_justification: {values['release_justification']}",
        f"- phase_transition_status: `{values['phase_transition_status']}`",
        f"- blocking_reason: {values['blocking_reason']}",
        f"- residual_risk_summary: {values['residual_risk_summary']}",
        f"- rollback_plan: {values['rollback_plan']}",
        f"- next_actions: {values['next_actions']}",
        f"- contract_review_status: `{values['contract_review_status']}`",
        f"- critical_drifts_open: `{values['critical_drifts_open']}`",
        "",
        "## Gate Status",
        "",
        f"- eval_gates_status: `{values['eval_gates_status']}`",
        f"- ci_quality_status: `{values['ci_quality_status']}`",
        f"- ci_security_status: `{values['ci_security_status']}`",
        "",
        "## Epic Status",
        "",
    ]
    for epic_id, status in epic_statuses.items():
        lines.append(f"- {epic_id}: `{status}`")

    lines.extend(["", "## Evidence Refs", ""])
    for ref in evidence_refs:
        lines.append(f"- `{ref}`")

    summary_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    read_prior_parser = subparsers.add_parser("read-prior-phase-status")
    read_prior_parser.add_argument("--summary-path", required=True)
    read_prior_parser.add_argument("--format", choices=["env", "json"], default="env")

    parse_weekly_parser = subparsers.add_parser("parse-weekly-report")
    parse_weekly_parser.add_argument("--report-path", required=True)

    read_epics_parser = subparsers.add_parser("read-epic-statuses")
    read_epics_parser.add_argument("--epics-path", required=True)

    parse_summary_parser = subparsers.add_parser("parse-validation-summary")
    parse_summary_parser.add_argument("--summary-path", required=True)

    render_parser = subparsers.add_parser("render-weekly-report")
    render_parser.add_argument("--report-path", required=True)
    render_parser.add_argument("--week-id", required=True)
    render_parser.add_argument("--executed-at", required=True)
    render_parser.add_argument("--source-of-truth", required=True)
    render_parser.add_argument("--prior-phase-decision", required=True)
    render_parser.add_argument("--phase-transition-status", required=True)
    render_parser.add_argument("--blocking-reason", required=True)
    render_parser.add_argument("--eval-gates-status", required=True)
    render_parser.add_argument("--ci-quality-status", required=True)
    render_parser.add_argument("--ci-security-status", required=True)
    render_parser.add_argument("--contract-review-status", required=True)
    render_parser.add_argument("--critical-drifts-open", required=True)
    render_parser.add_argument("--decision", required=True)
    render_parser.add_argument("--release-review-status", required=True)
    render_parser.add_argument("--release-justification", required=True)
    render_parser.add_argument("--residual-risk-summary", required=True)
    render_parser.add_argument("--rollback-plan", required=True)
    render_parser.add_argument("--summary-artifact", required=True)
    render_parser.add_argument("--risk-notes", required=True)
    render_parser.add_argument("--next-actions", required=True)
    render_parser.add_argument("--eval-log-path", required=True)
    render_parser.add_argument("--quality-log-path", required=True)
    render_parser.add_argument("--security-log-path", required=True)

    render_summary_parser = subparsers.add_parser("render-validation-summary")
    render_summary_parser.add_argument("--summary-path", required=True)
    render_summary_parser.add_argument("--weekly-report-path", required=True)
    render_summary_parser.add_argument("--epics-path", required=True)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if args.command == "read-prior-phase-status":
        status = read_prior_phase_status(Path(args.summary_path))
        emit_prior_phase_status(status, args.format)
        return 0

    if args.command == "parse-weekly-report":
        payload = parse_weekly_report(Path(args.report_path))
        print(json.dumps(payload, ensure_ascii=True))
        return 0

    if args.command == "read-epic-statuses":
        payload = parse_epic_statuses(Path(args.epics_path))
        print(json.dumps(payload, ensure_ascii=True))
        return 0

    if args.command == "parse-validation-summary":
        payload = parse_validation_summary(Path(args.summary_path))
        print(json.dumps(payload, ensure_ascii=True))
        return 0

    if args.command == "render-weekly-report":
        render_weekly_report(args)
        return 0

    if args.command == "render-validation-summary":
        render_validation_summary(args)
        return 0

    parser.error(f"comando nao suportado: {args.command}")
    return 2


if __name__ == "__main__":
    sys.exit(main())
