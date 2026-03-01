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
    "risk_notes",
    "next_actions",
]

LOG_KEYS = ["eval-gates", "ci-quality", "ci-security"]


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


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    read_prior_parser = subparsers.add_parser("read-prior-phase-status")
    read_prior_parser.add_argument("--summary-path", required=True)
    read_prior_parser.add_argument("--format", choices=["env", "json"], default="env")

    parse_weekly_parser = subparsers.add_parser("parse-weekly-report")
    parse_weekly_parser.add_argument("--report-path", required=True)

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
    render_parser.add_argument("--risk-notes", required=True)
    render_parser.add_argument("--next-actions", required=True)
    render_parser.add_argument("--eval-log-path", required=True)
    render_parser.add_argument("--quality-log-path", required=True)
    render_parser.add_argument("--security-log-path", required=True)

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

    if args.command == "render-weekly-report":
        render_weekly_report(args)
        return 0

    parser.error(f"comando nao suportado: {args.command}")
    return 2


if __name__ == "__main__":
    sys.exit(main())
