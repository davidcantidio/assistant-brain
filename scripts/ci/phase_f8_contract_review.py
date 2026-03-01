#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_REVIEW_DIR = ROOT / "artifacts/phase-f8/contract-review"
REQUIRED_SECTIONS = (
    "Metadata",
    "Contracts Reviewed",
    "Drift Backlog",
    "Previous Week Closure",
)
REQUIRED_DOMAINS = ("runtime", "integrations", "trading", "security")
ALLOWED_DOMAIN_STATUS = {"PASS", "FAIL"}
ALLOWED_DRIFT_SEVERITY = {"critical", "high", "medium", "low"}
ALLOWED_DRIFT_STATUS = {"open", "closed", "risk_accepted"}
ALLOWED_CLOSURE_STATUS = {"PASS", "FAIL"}
SOURCE_OF_TRUTH = "PRD/PRD-MASTER.md"


class ContractReviewError(RuntimeError):
    pass


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    read_parser = subparsers.add_parser("read")
    read_parser.add_argument("--week-id", required=True)
    read_parser.add_argument("--review-dir", default=str(DEFAULT_REVIEW_DIR))

    check_parser = subparsers.add_parser("check")
    check_parser.add_argument("--week-id", required=True)
    check_parser.add_argument("--review-dir", default=str(DEFAULT_REVIEW_DIR))

    return parser.parse_args()


def normalize_review_dir(value: str) -> Path:
    path = Path(value)
    if not path.is_absolute():
        path = ROOT / path
    return path


def display_path(path: Path) -> str:
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


def review_path(review_dir: Path, week_id: str) -> Path:
    return review_dir / f"{week_id}.md"


def load_review_text(path: Path) -> str:
    if not path.exists():
        raise ContractReviewError(f"{display_path(path)} ausente para a semana solicitada.")
    return path.read_text(encoding="utf-8")


def extract_sections(text: str, path: Path) -> dict[str, str]:
    headings = list(re.finditer(r"^## (.+)$", text, re.M))
    if not headings:
        raise ContractReviewError(f"{display_path(path)} sem secoes obrigatorias.")

    sections: dict[str, str] = {}
    for index, match in enumerate(headings):
        name = match.group(1).strip()
        start = match.end()
        end = headings[index + 1].start() if index + 1 < len(headings) else len(text)
        sections[name] = text[start:end].strip()
    return sections


def strip_code_fence(raw: str) -> str:
    text = raw.strip()
    if not text.startswith("```"):
        return text
    lines = text.splitlines()
    if len(lines) < 3 or lines[-1].strip() != "```":
        raise ContractReviewError("bloco JSON com fence markdown invalida.")
    return "\n".join(lines[1:-1]).strip()


def load_json_section(sections: dict[str, str], name: str, path: Path) -> object:
    if name not in sections:
        raise ContractReviewError(f"{display_path(path)} sem secao obrigatoria: {name}")
    raw = strip_code_fence(sections[name])
    try:
        return json.loads(raw)
    except json.JSONDecodeError as exc:
        raise ContractReviewError(
            f"{display_path(path)} com JSON invalido na secao {name}: {exc.msg}"
        ) from exc


def expect_dict(value: object, label: str) -> dict[str, object]:
    if not isinstance(value, dict):
        raise ContractReviewError(f"{label} deve ser um objeto JSON.")
    return value


def expect_list(value: object, label: str) -> list[object]:
    if not isinstance(value, list):
        raise ContractReviewError(f"{label} deve ser uma lista JSON.")
    return value


def expect_non_empty_string(value: object, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ContractReviewError(f"{label} deve ser string nao vazia.")
    return value.strip()


def expect_string_list(value: object, label: str) -> list[str]:
    items = expect_list(value, label)
    normalized: list[str] = []
    for index, item in enumerate(items):
        normalized.append(expect_non_empty_string(item, f"{label}[{index}]"))
    return normalized


def validate_timestamp(value: str, label: str) -> None:
    patterns = ("%Y-%m-%dT%H:%M:%S%z", "%Y-%m-%dT%H:%M:%S.%f%z")
    for pattern in patterns:
        try:
            dt.datetime.strptime(value, pattern)
            return
        except ValueError:
            continue
    raise ContractReviewError(f"{label} com timestamp invalido: {value}")


def validate_date(value: str, label: str) -> None:
    try:
        dt.datetime.strptime(value, "%Y-%m-%d")
    except ValueError as exc:
        raise ContractReviewError(f"{label} com data invalida: {value}") from exc


def expect_optional_string(value: object, label: str) -> str | None:
    if value is None:
        return None
    return expect_non_empty_string(value, label)


def validate_contracts_reviewed(contracts: object) -> None:
    items = expect_list(contracts, "Contracts Reviewed")
    seen_domains: set[str] = set()
    for index, item in enumerate(items):
        contract = expect_dict(item, f"Contracts Reviewed[{index}]")
        domain = expect_non_empty_string(contract.get("domain"), f"Contracts Reviewed[{index}].domain")
        if domain in seen_domains:
            raise ContractReviewError(f"Contracts Reviewed com dominio duplicado: {domain}")
        seen_domains.add(domain)
        expect_non_empty_string(contract.get("owner"), f"Contracts Reviewed[{index}].owner")
        status = expect_non_empty_string(contract.get("status"), f"Contracts Reviewed[{index}].status")
        if status not in ALLOWED_DOMAIN_STATUS:
            raise ContractReviewError(
                f"Contracts Reviewed[{index}].status invalido: {status}"
            )
        expect_string_list(contract.get("canonical_refs"), f"Contracts Reviewed[{index}].canonical_refs")
        expect_string_list(contract.get("gate_refs"), f"Contracts Reviewed[{index}].gate_refs")
        expect_string_list(contract.get("evidence_refs"), f"Contracts Reviewed[{index}].evidence_refs")
        expect_non_empty_string(contract.get("notes"), f"Contracts Reviewed[{index}].notes")

    missing = [domain for domain in REQUIRED_DOMAINS if domain not in seen_domains]
    if missing:
        raise ContractReviewError(
            "Contracts Reviewed sem dominios obrigatorios: " + ", ".join(missing)
        )


def validate_drift_backlog(backlog: object) -> int:
    items = expect_list(backlog, "Drift Backlog")
    seen_ids: set[str] = set()
    critical_open = 0
    for index, item in enumerate(items):
        drift = expect_dict(item, f"Drift Backlog[{index}]")
        drift_id = expect_non_empty_string(drift.get("drift_id"), f"Drift Backlog[{index}].drift_id")
        if drift_id in seen_ids:
            raise ContractReviewError(f"Drift Backlog com drift_id duplicado: {drift_id}")
        seen_ids.add(drift_id)
        expect_non_empty_string(drift.get("domain"), f"Drift Backlog[{index}].domain")
        severity = expect_non_empty_string(drift.get("severity"), f"Drift Backlog[{index}].severity")
        if severity not in ALLOWED_DRIFT_SEVERITY:
            raise ContractReviewError(f"Drift Backlog[{index}].severity invalido: {severity}")
        expect_non_empty_string(drift.get("summary"), f"Drift Backlog[{index}].summary")
        status = expect_non_empty_string(drift.get("status"), f"Drift Backlog[{index}].status")
        if status not in ALLOWED_DRIFT_STATUS:
            raise ContractReviewError(f"Drift Backlog[{index}].status invalido: {status}")
        expect_non_empty_string(drift.get("owner"), f"Drift Backlog[{index}].owner")
        due_date = expect_non_empty_string(drift.get("due_date"), f"Drift Backlog[{index}].due_date")
        validate_date(due_date, f"Drift Backlog[{index}].due_date")
        expect_string_list(drift.get("source_refs"), f"Drift Backlog[{index}].source_refs")
        expect_non_empty_string(drift.get("evidence_ref"), f"Drift Backlog[{index}].evidence_ref")
        risk_exception_ref = expect_optional_string(
            drift.get("risk_exception_ref"), f"Drift Backlog[{index}].risk_exception_ref"
        )
        if status == "risk_accepted" and risk_exception_ref is None:
            raise ContractReviewError(
                f"Drift Backlog[{index}] com status=risk_accepted exige risk_exception_ref."
            )
        if severity == "critical" and status == "open":
            critical_open += 1
    return critical_open


def validate_previous_week_closure(closure: object) -> None:
    payload = expect_dict(closure, "Previous Week Closure")
    status = expect_non_empty_string(payload.get("status"), "Previous Week Closure.status")
    if status not in ALLOWED_CLOSURE_STATUS:
        raise ContractReviewError(f"Previous Week Closure.status invalido: {status}")
    expect_string_list(payload.get("reviewed_drift_ids"), "Previous Week Closure.reviewed_drift_ids")
    expect_string_list(payload.get("closed_refs"), "Previous Week Closure.closed_refs")
    expect_string_list(payload.get("risk_accepted_refs"), "Previous Week Closure.risk_accepted_refs")
    expect_string_list(payload.get("open_critical_refs"), "Previous Week Closure.open_critical_refs")
    expect_non_empty_string(payload.get("notes"), "Previous Week Closure.notes")


def validate_review(review_dir: Path, week_id: str) -> tuple[Path, int]:
    path = review_path(review_dir, week_id)
    text = load_review_text(path)
    title_match = re.search(r"^# F8 Contract Review (.+)$", text, re.M)
    if not title_match:
        raise ContractReviewError(f"{display_path(path)} sem titulo canonico do contract review.")
    title_week = title_match.group(1).strip()
    if title_week != week_id:
        raise ContractReviewError(
            f"{display_path(path)} com titulo divergente do WEEK_ID: {title_week}"
        )

    sections = extract_sections(text, path)
    for name in REQUIRED_SECTIONS:
        if name not in sections:
            raise ContractReviewError(f"{display_path(path)} sem secao obrigatoria: {name}")

    metadata = expect_dict(load_json_section(sections, "Metadata", path), "Metadata")
    metadata_week_id = expect_non_empty_string(metadata.get("week_id"), "Metadata.week_id")
    if metadata_week_id != week_id:
        raise ContractReviewError(
            f"{display_path(path)} com Metadata.week_id divergente: {metadata_week_id}"
        )
    validate_timestamp(
        expect_non_empty_string(metadata.get("reviewed_at"), "Metadata.reviewed_at"),
        "Metadata.reviewed_at",
    )
    source_of_truth = expect_non_empty_string(
        metadata.get("source_of_truth"), "Metadata.source_of_truth"
    )
    if source_of_truth != SOURCE_OF_TRUTH:
        raise ContractReviewError(
            f"{display_path(path)} com source_of_truth invalida: {source_of_truth}"
        )
    previous_week_id = expect_non_empty_string(
        metadata.get("previous_week_id"), "Metadata.previous_week_id"
    )
    metadata_status = expect_non_empty_string(
        metadata.get("contract_review_status"), "Metadata.contract_review_status"
    )
    if metadata_status != "PASS":
        raise ContractReviewError(
            f"{display_path(path)} deve publicar contract_review_status=PASS quando valido."
        )

    validate_contracts_reviewed(load_json_section(sections, "Contracts Reviewed", path))
    critical_open = validate_drift_backlog(load_json_section(sections, "Drift Backlog", path))
    validate_previous_week_closure(load_json_section(sections, "Previous Week Closure", path))

    raw_critical_count = metadata.get("critical_drifts_open")
    if not isinstance(raw_critical_count, int) or raw_critical_count < 0:
        raise ContractReviewError(
            f"{display_path(path)} com Metadata.critical_drifts_open invalido."
        )
    if raw_critical_count != critical_open:
        raise ContractReviewError(
            f"{display_path(path)} com critical_drifts_open divergente do backlog."
        )
    if previous_week_id == "none":
        closure = expect_dict(load_json_section(sections, "Previous Week Closure", path), "Previous Week Closure")
        if closure.get("status") != "PASS":
            raise ContractReviewError(
                f"{display_path(path)} deve manter Previous Week Closure.status=PASS no primeiro ciclo."
            )

    return path, critical_open


def build_sample_review(
    path: Path,
    *,
    week_id: str,
    source_of_truth: str = SOURCE_OF_TRUTH,
    critical_drifts_open: int = 0,
    drift_backlog: list[dict[str, object]] | None = None,
) -> None:
    if drift_backlog is None:
        drift_backlog = []
    review = f"""# F8 Contract Review {week_id}

## Metadata
```json
{{
  "week_id": "{week_id}",
  "reviewed_at": "2026-03-01T00:00:00-0300",
  "source_of_truth": "{source_of_truth}",
  "previous_week_id": "none",
  "contract_review_status": "PASS",
  "critical_drifts_open": {critical_drifts_open}
}}
```

## Contracts Reviewed
```json
[
  {{
    "domain": "runtime",
    "owner": "Ayrton Senna",
    "status": "PASS",
    "canonical_refs": ["PRD/PRD-MASTER.md", "ARC/ARC-CORE.md"],
    "gate_refs": ["make eval-runtime"],
    "evidence_refs": ["scripts/ci/eval_runtime_contracts.sh"],
    "notes": "runtime contract review sample"
  }},
  {{
    "domain": "integrations",
    "owner": "O Garcon",
    "status": "PASS",
    "canonical_refs": ["PRD/PRD-MASTER.md", "INTEGRATIONS/README.md"],
    "gate_refs": ["make eval-integrations"],
    "evidence_refs": ["scripts/ci/eval_integrations.sh"],
    "notes": "integrations contract review sample"
  }},
  {{
    "domain": "trading",
    "owner": "Sr. Geldmacher",
    "status": "PASS",
    "canonical_refs": ["PRD/PRD-MASTER.md", "VERTICALS/TRADING/TRADING-PRD.md"],
    "gate_refs": ["make eval-trading"],
    "evidence_refs": ["scripts/ci/eval_trading.sh"],
    "notes": "trading contract review sample"
  }},
  {{
    "domain": "security",
    "owner": "Bas Rutten",
    "status": "PASS",
    "canonical_refs": ["PRD/PRD-MASTER.md", "SEC/SEC-POLICY.md"],
    "gate_refs": ["make ci-security"],
    "evidence_refs": ["scripts/ci/check_security.sh"],
    "notes": "security contract review sample"
  }}
]
```

## Drift Backlog
```json
{json.dumps(drift_backlog, ensure_ascii=True, indent=2)}
```

## Previous Week Closure
```json
{{
  "status": "PASS",
  "reviewed_drift_ids": [],
  "closed_refs": [],
  "risk_accepted_refs": [],
  "open_critical_refs": [],
  "notes": "first review cycle"
}}
```
"""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(review, encoding="utf-8")


def run_self_checks() -> None:
    with tempfile.TemporaryDirectory(prefix="phase-f8-contract-review-") as tmpdir:
        review_dir = Path(tmpdir) / "contract-review"
        week_id = "2026-W09"

        try:
            validate_review(review_dir, week_id)
        except ContractReviewError:
            pass
        else:
            raise ContractReviewError("mock sem artifact deveria falhar.")

        valid_path = review_path(review_dir, week_id)
        build_sample_review(valid_path, week_id=week_id)
        _, critical_open = validate_review(review_dir, week_id)
        if critical_open != 0:
            raise ContractReviewError("mock valido deveria retornar critical_drifts_open=0.")

        owner_missing_path = review_path(review_dir, "2026-W11")
        build_sample_review(
            owner_missing_path,
            week_id="2026-W11",
            drift_backlog=[
                {
                    "drift_id": "DRIFT-F8-2026-W11-01",
                    "domain": "trading",
                    "severity": "high",
                    "summary": "owner ausente",
                    "status": "open",
                    "due_date": "2026-03-15",
                    "source_refs": ["PRD/PRD-MASTER.md"],
                    "evidence_ref": "artifacts/mock.md",
                    "risk_exception_ref": None,
                }
            ],
        )
        try:
            validate_review(review_dir, "2026-W11")
        except ContractReviewError:
            pass
        else:
            raise ContractReviewError("mock sem owner deveria falhar.")

        due_date_missing_path = review_path(review_dir, "2026-W12")
        build_sample_review(
            due_date_missing_path,
            week_id="2026-W12",
            drift_backlog=[
                {
                    "drift_id": "DRIFT-F8-2026-W12-01",
                    "domain": "trading",
                    "severity": "high",
                    "summary": "due_date ausente",
                    "status": "open",
                    "owner": "Sr. Geldmacher",
                    "source_refs": ["PRD/PRD-MASTER.md"],
                    "evidence_ref": "artifacts/mock.md",
                    "risk_exception_ref": None,
                }
            ],
        )
        try:
            validate_review(review_dir, "2026-W12")
        except ContractReviewError:
            pass
        else:
            raise ContractReviewError("mock sem due_date deveria falhar.")

        risk_ref_missing_path = review_path(review_dir, "2026-W13")
        build_sample_review(
            risk_ref_missing_path,
            week_id="2026-W13",
            drift_backlog=[
                {
                    "drift_id": "DRIFT-F8-2026-W13-01",
                    "domain": "security",
                    "severity": "high",
                    "summary": "risk acceptance sem referencia",
                    "status": "risk_accepted",
                    "owner": "Bas Rutten",
                    "due_date": "2026-03-22",
                    "source_refs": ["PRD/PRD-MASTER.md"],
                    "evidence_ref": "artifacts/mock.md",
                    "risk_exception_ref": None,
                }
            ],
        )
        try:
            validate_review(review_dir, "2026-W13")
        except ContractReviewError:
            pass
        else:
            raise ContractReviewError("mock risk_accepted sem risk_exception_ref deveria falhar.")

        invalid_path = review_path(review_dir, "2026-W10")
        build_sample_review(
            invalid_path,
            week_id="2026-W10",
            source_of_truth="PRD/ROADMAP.md",
        )
        try:
            validate_review(review_dir, "2026-W10")
        except ContractReviewError:
            return
        raise ContractReviewError("mock com source_of_truth invalida deveria falhar.")


def command_read(week_id: str, review_dir: Path) -> int:
    _, critical_open = validate_review(review_dir, week_id)
    print("CONTRACT_REVIEW_STATUS=PASS")
    print(f"CRITICAL_DRIFTS_OPEN={critical_open}")
    return 0


def command_check(week_id: str, review_dir: Path) -> int:
    validate_review(review_dir, week_id)
    run_self_checks()
    print("phase-f8-contract-review: PASS")
    return 0


def main() -> int:
    args = parse_args()
    review_dir = normalize_review_dir(args.review_dir)
    try:
        if args.command == "read":
            return command_read(args.week_id, review_dir)
        return command_check(args.week_id, review_dir)
    except ContractReviewError as exc:
        print(str(exc))
        return 1


if __name__ == "__main__":
    sys.exit(main())
