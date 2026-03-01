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
ALLOWED_CARRY_RESOLUTION = {"closed", "risk_accepted", "open"}
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


def parse_week_id(week_id: str) -> tuple[int, int]:
    match = re.fullmatch(r"(\d{4})-W(0[1-9]|[1-4][0-9]|5[0-3])", week_id)
    if not match:
        raise ContractReviewError(f"WEEK_ID invalido para contract review: {week_id}")
    return int(match.group(1)), int(match.group(2))


def expected_previous_week_id(week_id: str) -> str:
    iso_year, iso_week = parse_week_id(week_id)
    current_monday = dt.date.fromisocalendar(iso_year, iso_week, 1)
    previous_monday = current_monday - dt.timedelta(days=7)
    previous_iso = previous_monday.isocalendar()
    return f"{previous_iso.year}-W{previous_iso.week:02d}"


def validate_contracts_reviewed(contracts: object) -> list[str]:
    items = expect_list(contracts, "Contracts Reviewed")
    seen_domains: set[str] = set()
    failed_domains: list[str] = []
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
        if status == "FAIL":
            failed_domains.append(domain)
        expect_string_list(contract.get("canonical_refs"), f"Contracts Reviewed[{index}].canonical_refs")
        expect_string_list(contract.get("gate_refs"), f"Contracts Reviewed[{index}].gate_refs")
        expect_string_list(contract.get("evidence_refs"), f"Contracts Reviewed[{index}].evidence_refs")
        expect_non_empty_string(contract.get("notes"), f"Contracts Reviewed[{index}].notes")

    missing = [domain for domain in REQUIRED_DOMAINS if domain not in seen_domains]
    if missing:
        raise ContractReviewError(
            "Contracts Reviewed sem dominios obrigatorios: " + ", ".join(missing)
        )
    return sorted(failed_domains)


def validate_drift_backlog(backlog: object) -> tuple[list[dict[str, object]], int]:
    items = expect_list(backlog, "Drift Backlog")
    seen_ids: set[str] = set()
    critical_open = 0
    validated: list[dict[str, object]] = []
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
        validated.append(
            {
                "drift_id": drift_id,
                "domain": drift["domain"],
                "severity": severity,
                "summary": drift["summary"],
                "status": status,
                "owner": drift["owner"],
                "due_date": due_date,
                "source_refs": drift["source_refs"],
                "evidence_ref": drift["evidence_ref"],
                "risk_exception_ref": risk_exception_ref,
            }
        )
        if severity == "critical" and status == "open":
            critical_open += 1
    return validated, critical_open


def validate_previous_week_closure(closure: object) -> dict[str, object]:
    payload = expect_dict(closure, "Previous Week Closure")
    status = expect_non_empty_string(payload.get("status"), "Previous Week Closure.status")
    if status not in ALLOWED_CLOSURE_STATUS:
        raise ContractReviewError(f"Previous Week Closure.status invalido: {status}")
    reviewed_drift_ids = expect_string_list(
        payload.get("reviewed_drift_ids"), "Previous Week Closure.reviewed_drift_ids"
    )
    closed_refs = expect_string_list(payload.get("closed_refs"), "Previous Week Closure.closed_refs")
    risk_accepted_refs = expect_string_list(
        payload.get("risk_accepted_refs"), "Previous Week Closure.risk_accepted_refs"
    )
    open_critical_refs = expect_string_list(
        payload.get("open_critical_refs"), "Previous Week Closure.open_critical_refs"
    )
    notes = expect_non_empty_string(payload.get("notes"), "Previous Week Closure.notes")
    carried = expect_list(payload.get("carried_over_drifts"), "Previous Week Closure.carried_over_drifts")
    validated_carried: list[dict[str, object]] = []
    seen_ids: set[str] = set()
    for index, item in enumerate(carried):
        entry = expect_dict(item, f"Previous Week Closure.carried_over_drifts[{index}]")
        drift_id = expect_non_empty_string(
            entry.get("drift_id"), f"Previous Week Closure.carried_over_drifts[{index}].drift_id"
        )
        if drift_id in seen_ids:
            raise ContractReviewError(f"Previous Week Closure com drift_id duplicado: {drift_id}")
        seen_ids.add(drift_id)
        resolution = expect_non_empty_string(
            entry.get("resolution"),
            f"Previous Week Closure.carried_over_drifts[{index}].resolution",
        )
        if resolution not in ALLOWED_CARRY_RESOLUTION:
            raise ContractReviewError(
                f"Previous Week Closure.carried_over_drifts[{index}].resolution invalida: {resolution}"
            )
        evidence_ref = expect_non_empty_string(
            entry.get("evidence_ref"),
            f"Previous Week Closure.carried_over_drifts[{index}].evidence_ref",
        )
        risk_exception_ref = expect_optional_string(
            entry.get("risk_exception_ref"),
            f"Previous Week Closure.carried_over_drifts[{index}].risk_exception_ref",
        )
        if resolution == "risk_accepted" and risk_exception_ref is None:
            raise ContractReviewError(
                "Previous Week Closure com resolution=risk_accepted exige risk_exception_ref."
            )
        validated_carried.append(
            {
                "drift_id": drift_id,
                "resolution": resolution,
                "evidence_ref": evidence_ref,
                "risk_exception_ref": risk_exception_ref,
            }
        )
    return {
        "status": status,
        "reviewed_drift_ids": reviewed_drift_ids,
        "closed_refs": closed_refs,
        "risk_accepted_refs": risk_accepted_refs,
        "open_critical_refs": open_critical_refs,
        "carried_over_drifts": validated_carried,
        "notes": notes,
    }


def validate_previous_week_relationship(
    *,
    review_dir: Path,
    week_id: str,
    previous_week_id: str,
    current_backlog: list[dict[str, object]],
    closure: dict[str, object],
    path: Path,
) -> None:
    expected_previous = expected_previous_week_id(week_id)
    previous_path = review_path(review_dir, expected_previous)
    if not previous_path.exists():
        if previous_week_id != "none":
            raise ContractReviewError(
                f"{display_path(path)} deve usar previous_week_id=none quando a semana anterior nao existir."
            )
        if any(
            closure[key]
            for key in (
                "reviewed_drift_ids",
                "closed_refs",
                "risk_accepted_refs",
                "open_critical_refs",
                "carried_over_drifts",
            )
        ):
            raise ContractReviewError(
                f"{display_path(path)} nao pode registrar carry-over quando nao existe semana anterior."
            )
        if closure["status"] != "PASS":
            raise ContractReviewError(
                f"{display_path(path)} deve manter Previous Week Closure.status=PASS no primeiro ciclo."
            )
        return

    if previous_week_id != expected_previous:
        raise ContractReviewError(
            f"{display_path(path)} com previous_week_id invalido: esperado {expected_previous}."
        )

    previous_review = validate_review(review_dir, expected_previous)
    previous_open_critical = {
        drift["drift_id"]: drift
        for drift in previous_review["drift_backlog"]
        if drift["severity"] == "critical" and drift["status"] == "open"
    }
    carry_entries = {
        entry["drift_id"]: entry for entry in closure["carried_over_drifts"]
    }
    previous_ids = set(previous_open_critical)
    carry_ids = set(carry_entries)
    if previous_ids != carry_ids:
        raise ContractReviewError(
            f"{display_path(path)} deve classificar todos os drifts criticos herdados da semana {expected_previous}."
        )
    if set(closure["reviewed_drift_ids"]) != previous_ids:
        raise ContractReviewError(
            f"{display_path(path)} com reviewed_drift_ids divergente dos drifts criticos herdados."
        )

    current_open_critical_ids = {
        drift["drift_id"]
        for drift in current_backlog
        if drift["severity"] == "critical" and drift["status"] == "open"
    }
    expected_closed_refs: set[str] = set()
    expected_risk_refs: set[str] = set()
    expected_open_ids: set[str] = set()

    for drift_id, entry in carry_entries.items():
        resolution = entry["resolution"]
        if resolution == "closed":
            expected_closed_refs.add(entry["evidence_ref"])
            if drift_id in current_open_critical_ids:
                raise ContractReviewError(
                    f"{display_path(path)} nao pode manter {drift_id} aberto ao marcar resolution=closed."
                )
        elif resolution == "risk_accepted":
            risk_exception_ref = entry["risk_exception_ref"]
            if risk_exception_ref is None:
                raise ContractReviewError(
                    f"{display_path(path)} exige risk_exception_ref para {drift_id}."
                )
            expected_risk_refs.add(risk_exception_ref)
            if drift_id in current_open_critical_ids:
                raise ContractReviewError(
                    f"{display_path(path)} nao pode manter {drift_id} aberto ao marcar resolution=risk_accepted."
                )
        else:
            expected_open_ids.add(drift_id)
            if drift_id not in current_open_critical_ids:
                raise ContractReviewError(
                    f"{display_path(path)} deve manter {drift_id} no backlog atual ao marcar resolution=open."
                )

    if set(closure["closed_refs"]) != expected_closed_refs:
        raise ContractReviewError(
            f"{display_path(path)} com closed_refs divergente dos drifts herdados fechados."
        )
    if set(closure["risk_accepted_refs"]) != expected_risk_refs:
        raise ContractReviewError(
            f"{display_path(path)} com risk_accepted_refs divergente dos drifts herdados aceitos por risco."
        )
    if set(closure["open_critical_refs"]) != expected_open_ids:
        raise ContractReviewError(
            f"{display_path(path)} com open_critical_refs divergente dos drifts herdados ainda abertos."
        )

    expected_status = "FAIL" if expected_open_ids else "PASS"
    if closure["status"] != expected_status:
        raise ContractReviewError(
            f"{display_path(path)} com Previous Week Closure.status divergente do carry-over atual."
        )


def validate_review(review_dir: Path, week_id: str) -> dict[str, object]:
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
    legacy_review_validity = metadata.get("contract_review_status")
    review_validity_raw = metadata.get("review_validity_status")
    if review_validity_raw is None:
        if legacy_review_validity is None:
            raise ContractReviewError(
                f"{display_path(path)} sem review_validity_status nem contract_review_status legado."
            )
        review_validity_status = expect_non_empty_string(
            legacy_review_validity,
            "Metadata.contract_review_status",
        )
    else:
        review_validity_status = expect_non_empty_string(
            review_validity_raw,
            "Metadata.review_validity_status",
        )
    if review_validity_status != "PASS":
        raise ContractReviewError(
            f"{display_path(path)} deve publicar review_validity_status=PASS quando valido."
        )

    failed_domains = validate_contracts_reviewed(load_json_section(sections, "Contracts Reviewed", path))
    expected_operational_conformance = "PASS" if not failed_domains else "FAIL"
    operational_conformance_raw = metadata.get("operational_conformance_status")
    if operational_conformance_raw is None:
        operational_conformance_status = expected_operational_conformance
    else:
        operational_conformance_status = expect_non_empty_string(
            operational_conformance_raw,
            "Metadata.operational_conformance_status",
        )
    if operational_conformance_status != expected_operational_conformance:
        raise ContractReviewError(
            f"{display_path(path)} com operational_conformance_status divergente de Contracts Reviewed."
        )

    failed_domains_raw = metadata.get("failed_domains")
    if failed_domains_raw is None:
        metadata_failed_domains = failed_domains
    else:
        metadata_failed_domains = expect_string_list(
            failed_domains_raw,
            "Metadata.failed_domains",
        )
        invalid_domains = sorted(set(metadata_failed_domains) - set(REQUIRED_DOMAINS))
        if invalid_domains:
            raise ContractReviewError(
                f"{display_path(path)} com failed_domains invalidos: {', '.join(invalid_domains)}"
            )
        if sorted(metadata_failed_domains) != failed_domains:
            raise ContractReviewError(
                f"{display_path(path)} com failed_domains divergente de Contracts Reviewed."
            )

    drift_backlog, critical_open = validate_drift_backlog(load_json_section(sections, "Drift Backlog", path))
    previous_week_closure = validate_previous_week_closure(
        load_json_section(sections, "Previous Week Closure", path)
    )

    raw_critical_count = metadata.get("critical_drifts_open")
    if not isinstance(raw_critical_count, int) or raw_critical_count < 0:
        raise ContractReviewError(
            f"{display_path(path)} com Metadata.critical_drifts_open invalido."
        )
    if raw_critical_count != critical_open:
        raise ContractReviewError(
            f"{display_path(path)} com critical_drifts_open divergente do backlog."
        )
    validate_previous_week_relationship(
        review_dir=review_dir,
        week_id=week_id,
        previous_week_id=previous_week_id,
        current_backlog=drift_backlog,
        closure=previous_week_closure,
        path=path,
    )

    return {
        "path": path,
        "review_validity_status": review_validity_status,
        "operational_conformance_status": operational_conformance_status,
        "failed_domains": metadata_failed_domains,
        "critical_open": critical_open,
        "drift_backlog": drift_backlog,
        "previous_week_closure": previous_week_closure,
    }


def build_sample_review(
    path: Path,
    *,
    week_id: str,
    source_of_truth: str = SOURCE_OF_TRUTH,
    critical_drifts_open: int = 0,
    drift_backlog: list[dict[str, object]] | None = None,
    previous_week_id: str = "none",
    previous_week_closure: dict[str, object] | None = None,
) -> None:
    if drift_backlog is None:
        drift_backlog = []
    if previous_week_closure is None:
        previous_week_closure = {
            "status": "PASS",
            "reviewed_drift_ids": [],
            "closed_refs": [],
            "risk_accepted_refs": [],
            "open_critical_refs": [],
            "carried_over_drifts": [],
            "notes": "first review cycle",
        }
    review = f"""# F8 Contract Review {week_id}

## Metadata
```json
{{
  "week_id": "{week_id}",
  "reviewed_at": "2026-03-01T00:00:00-0300",
  "source_of_truth": "{source_of_truth}",
  "previous_week_id": "{previous_week_id}",
  "review_validity_status": "PASS",
  "operational_conformance_status": "PASS",
  "failed_domains": [],
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
{json.dumps(previous_week_closure, ensure_ascii=True, indent=2)}
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
        valid_review = validate_review(review_dir, week_id)
        if valid_review["critical_open"] != 0:
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
            pass
        else:
            raise ContractReviewError("mock com source_of_truth invalida deveria falhar.")

        previous_open_path = review_path(review_dir, "2026-W40")
        build_sample_review(
            previous_open_path,
            week_id="2026-W40",
            critical_drifts_open=1,
            drift_backlog=[
                {
                    "drift_id": "DRIFT-F8-2026-W40-01",
                    "domain": "trading",
                    "severity": "critical",
                    "summary": "carry-over base",
                    "status": "open",
                    "owner": "Sr. Geldmacher",
                    "due_date": "2026-03-29",
                    "source_refs": ["PRD/PRD-MASTER.md"],
                    "evidence_ref": "artifacts/mock.md",
                    "risk_exception_ref": None,
                }
            ],
        )

        closed_current_path = review_path(review_dir, "2026-W41")
        build_sample_review(
            closed_current_path,
            week_id="2026-W41",
            previous_week_id="2026-W40",
            previous_week_closure={
                "status": "PASS",
                "reviewed_drift_ids": ["DRIFT-F8-2026-W40-01"],
                "closed_refs": ["artifacts/mock-close.md"],
                "risk_accepted_refs": [],
                "open_critical_refs": [],
                "carried_over_drifts": [
                    {
                        "drift_id": "DRIFT-F8-2026-W40-01",
                        "resolution": "closed",
                        "evidence_ref": "artifacts/mock-close.md",
                        "risk_exception_ref": None,
                    }
                ],
                "notes": "closed prior critical drift",
            },
        )
        validate_review(review_dir, "2026-W41")

        previous_risk_path = review_path(review_dir, "2026-W43")
        build_sample_review(
            previous_risk_path,
            week_id="2026-W43",
            critical_drifts_open=1,
            drift_backlog=[
                {
                    "drift_id": "DRIFT-F8-2026-W43-01",
                    "domain": "security",
                    "severity": "critical",
                    "summary": "risk acceptance base",
                    "status": "open",
                    "owner": "Bas Rutten",
                    "due_date": "2026-04-12",
                    "source_refs": ["PRD/PRD-MASTER.md"],
                    "evidence_ref": "artifacts/mock.md",
                    "risk_exception_ref": None,
                }
            ],
        )

        risk_current_path = review_path(review_dir, "2026-W44")
        build_sample_review(
            risk_current_path,
            week_id="2026-W44",
            previous_week_id="2026-W43",
            previous_week_closure={
                "status": "PASS",
                "reviewed_drift_ids": ["DRIFT-F8-2026-W43-01"],
                "closed_refs": [],
                "risk_accepted_refs": ["decision://RISK-001"],
                "open_critical_refs": [],
                "carried_over_drifts": [
                    {
                        "drift_id": "DRIFT-F8-2026-W43-01",
                        "resolution": "risk_accepted",
                        "evidence_ref": "artifacts/mock-risk.md",
                        "risk_exception_ref": "decision://RISK-001",
                    }
                ],
                "notes": "accepted by risk exception",
            },
        )
        validate_review(review_dir, "2026-W44")

        previous_open_again_path = review_path(review_dir, "2026-W46")
        build_sample_review(
            previous_open_again_path,
            week_id="2026-W46",
            critical_drifts_open=1,
            drift_backlog=[
                {
                    "drift_id": "DRIFT-F8-2026-W46-01",
                    "domain": "trading",
                    "severity": "critical",
                    "summary": "open carry-over base",
                    "status": "open",
                    "owner": "Sr. Geldmacher",
                    "due_date": "2026-04-26",
                    "source_refs": ["PRD/PRD-MASTER.md"],
                    "evidence_ref": "artifacts/mock.md",
                    "risk_exception_ref": None,
                }
            ],
        )

        open_current_path = review_path(review_dir, "2026-W47")
        build_sample_review(
            open_current_path,
            week_id="2026-W47",
            previous_week_id="2026-W46",
            critical_drifts_open=1,
            drift_backlog=[
                {
                    "drift_id": "DRIFT-F8-2026-W46-01",
                    "domain": "trading",
                    "severity": "critical",
                    "summary": "open carry-over base",
                    "status": "open",
                    "owner": "Sr. Geldmacher",
                    "due_date": "2026-05-03",
                    "source_refs": ["PRD/PRD-MASTER.md"],
                    "evidence_ref": "artifacts/mock-open.md",
                    "risk_exception_ref": None,
                }
            ],
            previous_week_closure={
                "status": "FAIL",
                "reviewed_drift_ids": ["DRIFT-F8-2026-W46-01"],
                "closed_refs": [],
                "risk_accepted_refs": [],
                "open_critical_refs": ["DRIFT-F8-2026-W46-01"],
                "carried_over_drifts": [
                    {
                        "drift_id": "DRIFT-F8-2026-W46-01",
                        "resolution": "open",
                        "evidence_ref": "artifacts/mock-open.md",
                        "risk_exception_ref": None,
                    }
                ],
                "notes": "carry-over remains open",
            },
        )
        open_review = validate_review(review_dir, "2026-W47")
        if open_review["critical_open"] != 1:
            raise ContractReviewError("mock open carry-over deveria manter critical_open=1.")

        previous_omission_path = review_path(review_dir, "2026-W49")
        build_sample_review(
            previous_omission_path,
            week_id="2026-W49",
            critical_drifts_open=1,
            drift_backlog=[
                {
                    "drift_id": "DRIFT-F8-2026-W49-01",
                    "domain": "trading",
                    "severity": "critical",
                    "summary": "omission base",
                    "status": "open",
                    "owner": "Sr. Geldmacher",
                    "due_date": "2026-05-10",
                    "source_refs": ["PRD/PRD-MASTER.md"],
                    "evidence_ref": "artifacts/mock.md",
                    "risk_exception_ref": None,
                }
            ],
        )

        omission_current_path = review_path(review_dir, "2026-W50")
        build_sample_review(
            omission_current_path,
            week_id="2026-W50",
            previous_week_id="2026-W49",
            previous_week_closure={
                "status": "PASS",
                "reviewed_drift_ids": [],
                "closed_refs": [],
                "risk_accepted_refs": [],
                "open_critical_refs": [],
                "carried_over_drifts": [],
                "notes": "omitted carry-over",
            },
        )
        try:
            validate_review(review_dir, "2026-W50")
        except ContractReviewError:
            return
        raise ContractReviewError("mock sem classificacao do carry-over deveria falhar.")


def command_read(week_id: str, review_dir: Path) -> int:
    review = validate_review(review_dir, week_id)
    failed_domains = ",".join(review["failed_domains"]) if review["failed_domains"] else "none"
    print(f"REVIEW_VALIDITY_STATUS={json.dumps(review['review_validity_status'], ensure_ascii=True)}")
    print(
        "OPERATIONAL_CONFORMANCE_STATUS="
        + json.dumps(review["operational_conformance_status"], ensure_ascii=True)
    )
    print(f"FAILED_DOMAINS={json.dumps(failed_domains, ensure_ascii=True)}")
    print(f"CRITICAL_DRIFTS_OPEN={review['critical_open']}")
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
