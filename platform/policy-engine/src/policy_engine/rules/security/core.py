from __future__ import annotations

import json
import re
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Callable

from policy_engine.domain.contract_models import ContractManifest, RuleContract
from policy_engine.domain.policy_rule import PolicyContext, PolicyRule, RuleEvaluation

REQUIRED_FILES: tuple[str, ...] = (
    "SEC/allowlists/DOMAINS.yaml",
    "SEC/allowlists/TOOLS.yaml",
    "SEC/allowlists/ACTIONS.yaml",
    "SEC/allowlists/OPERATORS.yaml",
    "SEC/allowlists/PROVIDERS.yaml",
    "SEC/allowlists/AGENT-IDENTITY-SURFACES.yaml",
    "SEC/allowlists/SECRET_SCAN_ALLOWLIST.yaml",
    "SEC/allowlists/CURL_PIPE_BASH_ALLOWLIST.yaml",
)

SECRET_SCAN_ALLOWLIST_PATH = "SEC/allowlists/SECRET_SCAN_ALLOWLIST.yaml"
CURL_PIPE_BASH_ALLOWLIST_PATH = "SEC/allowlists/CURL_PIPE_BASH_ALLOWLIST.yaml"

SECRET_PATTERNS: tuple[tuple[str, re.Pattern[str]], ...] = (
    ("SEC.SECRET.OPENAI", re.compile(r"sk-[A-Za-z0-9]{20,}")),
    ("SEC.SECRET.SLACK", re.compile(r"xox[baprs]-[A-Za-z0-9-]{10,}")),
    ("SEC.SECRET.AWS_ACCESS", re.compile(r"AKIA[0-9A-Z]{16}")),
    ("SEC.SECRET.GITHUB_PAT", re.compile(r"gh[pousr]_[A-Za-z0-9]{36,255}")),
    ("SEC.SECRET.GITHUB_FINE_GRAINED", re.compile(r"github_pat_[A-Za-z0-9_]{80,}")),
    ("SEC.SECRET.STRIPE", re.compile(r"sk_live_[A-Za-z0-9]{24,}")),
    ("SEC.SECRET.SENTRY", re.compile(r"sntrys_[A-Za-z0-9._-]{30,}")),
    ("SEC.SECRET.SLACK_APP", re.compile(r"xapp-[A-Za-z0-9-]{20,}")),
    (
        "SEC.SECRET.GENERIC_ASSIGNMENT",
        re.compile(r"(?i)(api[_-]?key|token|secret|password)\s*[:=]\s*['\"]?[A-Za-z0-9._-]{20,}['\"]?"),
    ),
)

CURL_PIPE_BASH_PATTERN = re.compile(r"curl\s+[^|\n]+\|\s*bash")

Checker = Callable[[PolicyContext, RuleContract], RuleEvaluation]


@dataclass(frozen=True)
class AllowlistEntry:
    path_regex: re.Pattern[str]
    line_regex: re.Pattern[str] | None
    evidence_ref: str


class ManifestRule:
    id: str
    domain: str
    severity: str
    category: str | None
    evidence_refs: tuple[str, ...]
    remediation_hint: str | None
    _contract: RuleContract
    _checker: Checker

    def __init__(self, contract: RuleContract, checker: Checker) -> None:
        self.id = contract.rule_id
        self.domain = contract.domain
        self.severity = contract.severity
        self.category = contract.category
        self.evidence_refs = contract.evidence_refs
        self.remediation_hint = contract.remediation_hint
        self._contract = contract
        self._checker = checker

    def evaluate(self, context: PolicyContext) -> RuleEvaluation:
        return self._checker(context, self._contract)


def _load_allowlist(root: Path, rel_path: str) -> tuple[AllowlistEntry, ...]:
    path = root / rel_path
    if not path.exists():
        raise ValueError(f"missing allowlist: {rel_path}")

    try:
        payload_obj = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValueError(f"invalid allowlist JSON at {rel_path}: {exc}") from exc

    if not isinstance(payload_obj, dict):
        raise ValueError(f"allowlist must be a JSON object: {rel_path}")

    entries_obj = payload_obj.get("entries")
    if not isinstance(entries_obj, list):
        raise ValueError(f"allowlist entries must be a list: {rel_path}")

    entries: list[AllowlistEntry] = []
    for idx, entry in enumerate(entries_obj):
        context = f"{rel_path}:entries[{idx}]"
        if not isinstance(entry, dict):
            raise ValueError(f"{context} must be an object")

        path_regex_raw = entry.get("path_regex")
        evidence_ref_raw = entry.get("evidence_ref")
        line_regex_raw = entry.get("line_regex")

        if not isinstance(path_regex_raw, str) or not path_regex_raw.strip():
            raise ValueError(f"{context}.path_regex must be a non-empty string")
        if not isinstance(evidence_ref_raw, str) or not evidence_ref_raw.strip():
            raise ValueError(f"{context}.evidence_ref must be a non-empty string")
        if line_regex_raw is not None and (
            not isinstance(line_regex_raw, str) or not line_regex_raw.strip()
        ):
            raise ValueError(f"{context}.line_regex must be null or non-empty string")

        try:
            path_regex = re.compile(path_regex_raw)
        except re.error as exc:
            raise ValueError(f"{context}.path_regex invalid regex: {exc}") from exc

        line_regex: re.Pattern[str] | None = None
        if isinstance(line_regex_raw, str):
            try:
                line_regex = re.compile(line_regex_raw)
            except re.error as exc:
                raise ValueError(f"{context}.line_regex invalid regex: {exc}") from exc

        entries.append(
            AllowlistEntry(
                path_regex=path_regex,
                line_regex=line_regex,
                evidence_ref=evidence_ref_raw.strip(),
            )
        )

    return tuple(entries)


def _is_allowlisted(rel_path: str, line: str, entries: tuple[AllowlistEntry, ...]) -> bool:
    for entry in entries:
        if entry.path_regex.search(rel_path) is None:
            continue
        if entry.line_regex is None:
            return True
        if entry.line_regex.search(line) is not None:
            return True
    return False


def _is_placeholder_line(line: str) -> bool:
    lowered = line.lower()
    placeholder_markers = (
        "placeholder",
        "example",
        "required",
        "obrigatoria",
        "obrigatorio",
        "changeme",
        "replace_me",
        "<",
        ">",
        "your_",
        "dummy",
    )
    return any(marker in lowered for marker in placeholder_markers)


def _tracked_files(root: Path) -> tuple[Path, ...]:
    proc = subprocess.run(
        ["git", "ls-files", "-z"],
        cwd=root,
        text=False,
        capture_output=True,
        check=False,
    )
    if proc.returncode == 0:
        rel_paths = [item.decode("utf-8") for item in proc.stdout.split(b"\x00") if item]
        return tuple(root / rel for rel in rel_paths)

    files: list[Path] = []
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        if ".git" in path.parts:
            continue
        files.append(path)
    return tuple(files)


def check_required_files(context: PolicyContext, _: RuleContract) -> RuleEvaluation:
    missing = [rel for rel in REQUIRED_FILES if not (context.root / rel).exists()]
    if not missing:
        return RuleEvaluation(passed=True)
    return RuleEvaluation(
        passed=False,
        message=f"required security files missing: {', '.join(missing[:5])}",
        path=missing[0],
        evidence_ref=missing[0],
        error_code="SEC.REQUIRED_FILES.MISSING",
    )


def check_secret_scan(context: PolicyContext, _: RuleContract) -> RuleEvaluation:
    try:
        allowlist_entries = _load_allowlist(context.root, SECRET_SCAN_ALLOWLIST_PATH)
    except ValueError as exc:
        return RuleEvaluation(
            passed=False,
            message=str(exc),
            path=SECRET_SCAN_ALLOWLIST_PATH,
            evidence_ref=SECRET_SCAN_ALLOWLIST_PATH,
            error_code="SEC.SECRET_SCAN.ALLOWLIST_INVALID",
        )

    for path in _tracked_files(context.root):
        if not path.exists():
            continue
        if path.stat().st_size > 1_000_000:
            continue

        rel_path = path.relative_to(context.root).as_posix()
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue

        for line_no, line in enumerate(text.splitlines(), start=1):
            if _is_placeholder_line(line):
                continue
            if _is_allowlisted(rel_path, line, allowlist_entries):
                continue
            for error_code, pattern in SECRET_PATTERNS:
                if pattern.search(line) is None:
                    continue
                return RuleEvaluation(
                    passed=False,
                    message=f"potential secret detected at {rel_path}:{line_no}",
                    path=rel_path,
                    evidence_ref=SECRET_SCAN_ALLOWLIST_PATH,
                    error_code=error_code,
                )

    return RuleEvaluation(passed=True)


def check_policy_markers(context: PolicyContext, _: RuleContract) -> RuleEvaluation:
    rel_path = "SEC/SEC-POLICY.md"
    path = context.root / rel_path
    if not path.exists():
        return RuleEvaluation(
            passed=False,
            message=f"missing file: {rel_path}",
            path=rel_path,
            evidence_ref=rel_path,
            error_code="SEC.POLICY_MARKERS.MISSING_FILE",
        )

    text = path.read_text(encoding="utf-8", errors="ignore")
    required_markers = (
        "## Classificacao de Sensibilidade",
        "`public`:",
        "`internal`:",
        "`sensitive`:",
    )
    for marker in required_markers:
        if marker not in text:
            return RuleEvaluation(
                passed=False,
                message=f"missing security policy marker: {marker}",
                path=rel_path,
                evidence_ref=rel_path,
                error_code="SEC.POLICY_MARKERS.MISSING_MARKER",
            )

    return RuleEvaluation(passed=True)


def check_operators_tokens(context: PolicyContext, _: RuleContract) -> RuleEvaluation:
    rel_path = "SEC/allowlists/OPERATORS.yaml"
    path = context.root / rel_path
    if not path.exists():
        return RuleEvaluation(
            passed=False,
            message=f"missing file: {rel_path}",
            path=rel_path,
            evidence_ref=rel_path,
            error_code="SEC.OPERATORS.MISSING_FILE",
        )

    data = path.read_text(encoding="utf-8", errors="ignore")
    required_tokens = (
        "telegram_user_id",
        "trading_live_requires_backup_operator",
        "backup_operator_strategy",
        "backup_operator_operator_id",
    )
    for token in required_tokens:
        if re.search(token, data) is None:
            return RuleEvaluation(
                passed=False,
                message=f"missing operators allowlist token: {token}",
                path=rel_path,
                evidence_ref=rel_path,
                error_code="SEC.OPERATORS.MISSING_TOKEN",
            )

    return RuleEvaluation(passed=True)


def check_forbid_curl_pipe_bash(context: PolicyContext, _: RuleContract) -> RuleEvaluation:
    rel_path = "scripts/onboard_linux.sh"
    path = context.root / rel_path
    if not path.exists():
        return RuleEvaluation(
            passed=False,
            message=f"missing file: {rel_path}",
            path=rel_path,
            evidence_ref=rel_path,
            error_code="SEC.CURL_PIPE_BASH.MISSING_FILE",
        )

    try:
        allowlist_entries = _load_allowlist(context.root, CURL_PIPE_BASH_ALLOWLIST_PATH)
    except ValueError as exc:
        return RuleEvaluation(
            passed=False,
            message=str(exc),
            path=CURL_PIPE_BASH_ALLOWLIST_PATH,
            evidence_ref=CURL_PIPE_BASH_ALLOWLIST_PATH,
            error_code="SEC.CURL_PIPE_BASH.ALLOWLIST_INVALID",
        )

    for line_no, line in enumerate(path.read_text(encoding="utf-8", errors="ignore").splitlines(), start=1):
        if CURL_PIPE_BASH_PATTERN.search(line) is None:
            continue
        if _is_allowlisted(rel_path, line, allowlist_entries):
            continue
        return RuleEvaluation(
            passed=False,
            message=f"forbidden curl|bash pattern found at {rel_path}:{line_no}",
            path=rel_path,
            evidence_ref=CURL_PIPE_BASH_ALLOWLIST_PATH,
            error_code="SEC.CURL_PIPE_BASH.FORBIDDEN_PATTERN",
        )

    return RuleEvaluation(passed=True)


def build_security_rules(manifest: ContractManifest) -> tuple[PolicyRule, ...]:
    if manifest.domain != "security":
        raise ValueError("security manifest expected")

    implementation_map: dict[str, Checker] = {
        "required_files": check_required_files,
        "secret_scan": check_secret_scan,
        "policy_markers": check_policy_markers,
        "operators_tokens": check_operators_tokens,
        "forbid_curl_pipe_bash": check_forbid_curl_pipe_bash,
    }

    out: list[PolicyRule] = []
    for contract in manifest.rules:
        if not contract.enabled:
            continue

        checker = implementation_map.get(contract.implementation)
        if checker is None:
            raise ValueError(
                f"security contract '{contract.rule_id}' references unknown implementation '{contract.implementation}'"
            )
        out.append(ManifestRule(contract, checker))

    return tuple(out)
