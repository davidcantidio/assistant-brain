from __future__ import annotations

import json
import re
import sys
from datetime import date
from pathlib import Path


ROOT = Path(".")
SCHEMA_PATH = ROOT / "ARC/schemas/architecture_consistency_backlog.schema.json"
BACKLOG_JSON_PATH = ROOT / "PM/audit/ARCH-CONSISTENCY-BACKLOG-2026-03-01.json"
BACKLOG_MD_PATH = ROOT / "artifacts/architecture/2026-03-01-architectural-consistency-audit-backlog.md"

SOURCE_BASELINES = {
    "pr_main",
    "pr_working_tree",
    "implementation",
    "felixcraft",
    "felix_relevant",
    "supporting_context",
}
CONFLICT_TYPES = {
    "Estrutural",
    "Governanca",
    "Responsabilidade",
    "Fluxo operacional",
    "Seguranca",
    "CI/CD",
    "Autoridade decisoria",
    "Drift conceitual",
    "Drift tecnico",
    "Sobreposicao de arquitetura",
    "Incompatibilidade filosofica",
}
SEVERITIES = {"Baixa", "Media", "Alta", "Critica"}
DRIFT_CLASSES = {"Leve", "Moderado", "Alto", "Critico"}
IMPLEMENTATION_STATUS = {
    "implementado",
    "simulado_por_contrato",
    "declarado_sem_execucao",
}
PRIORITIES = {"P0", "P1", "P2"}
FAILURE_MODE_STATUS = {"ok", "encontrado", "parcialmente_contido", "risco_aberto"}
RISK_LEVELS = {"R0", "R1", "R2", "R3"}
DRIFT_BLOCKS = {
    "drift_do_estado_commitado",
    "drift_introduzido_pelo_working_tree",
    "felix_como_terceira_direcao",
}
REQUIRED_FAILURE_MODES = {
    "autoridade_dupla_entre_modelos",
    "implementacao_bypassando_prd",
    "prd_desatualizado",
    "felix_propondo_arquitetura_nao_formalizada",
    "ci_nao_refletindo_criterios_do_prd",
    "seguranca_nao_alinhada_com_principios_felix",
    "pipeline_multi_modelo_nao_documentado",
    "micro_issues_violando_atomicidade",
    "drift_entre_roadmap_e_codigo",
    "regras_de_branch_nao_documentadas",
    "dependencias_externas_nao_mapeadas",
    "decisoes_arquiteturais_hardcoded",
}


def fail(message: str) -> None:
    print(f"architecture-consistency-backlog: FAIL - {message}")
    sys.exit(1)


def load_json(path: Path) -> dict:
    if not path.exists():
        fail(f"arquivo obrigatorio ausente: {path}")
    try:
        with path.open("r", encoding="utf-8") as f:
            return json.load(f)
    except json.JSONDecodeError as exc:
        fail(f"json invalido em {path}: {exc}")


def ensure_non_empty_str(value, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        fail(f"{label} deve ser string nao vazia")
    return value.strip()


def ensure_set_members(values, allowed: set[str], label: str) -> None:
    if not isinstance(values, list) or not values:
        fail(f"{label} deve ser lista nao vazia")
    for idx, val in enumerate(values):
        if val not in allowed:
            fail(f"{label}[{idx}] invalido: {val}")


def parse_ref_to_path(ref: str) -> Path:
    clean = ref.split("#", 1)[0].strip()
    if not clean:
        fail("evidence ref vazio")
    if clean.startswith(("http://", "https://", "mailto:")):
        return ROOT / "__external__"
    direct = ROOT / clean
    if direct.exists():
        return direct
    if ":" in clean:
        candidate = clean.split(":", 1)[0]
        with_line = ROOT / candidate
        if with_line.exists():
            return with_line
    fail(f"evidence ref aponta para caminho inexistente: {ref}")
    return ROOT / "__unreachable__"


def ensure_refs(refs, label: str) -> None:
    if not isinstance(refs, list) or not refs:
        fail(f"{label} deve ser lista nao vazia")
    for idx, ref in enumerate(refs):
        ensure_non_empty_str(ref, f"{label}[{idx}]")
        parse_ref_to_path(ref)


if not SCHEMA_PATH.exists():
    fail(f"schema obrigatorio ausente: {SCHEMA_PATH}")
if not BACKLOG_MD_PATH.exists():
    fail(f"backlog markdown ausente: {BACKLOG_MD_PATH}")

payload = load_json(BACKLOG_JSON_PATH)

required_root = {
    "schema_version",
    "doc_id",
    "generated_at",
    "baseline",
    "source_audit",
    "conflict_matrix_rows",
    "drift_rows",
    "failure_mode_checks",
    "remediation_issues",
}
missing_root = sorted(required_root - set(payload.keys()))
if missing_root:
    fail(f"campos obrigatorios ausentes no root: {missing_root}")

if payload["schema_version"] != "1.0":
    fail("schema_version deve ser 1.0")
if payload["baseline"] != "head_main_vs_working_tree":
    fail("baseline deve ser head_main_vs_working_tree")
ensure_non_empty_str(payload["doc_id"], "doc_id")
ensure_non_empty_str(payload["generated_at"], "generated_at")
ensure_non_empty_str(payload["source_audit"], "source_audit")
parse_ref_to_path(payload["source_audit"])

conflicts = payload["conflict_matrix_rows"]
drifts = payload["drift_rows"]
failure_modes = payload["failure_mode_checks"]
issues = payload["remediation_issues"]

if not isinstance(conflicts, list) or not conflicts:
    fail("conflict_matrix_rows deve ser lista nao vazia")
if not isinstance(drifts, list) or not drifts:
    fail("drift_rows deve ser lista nao vazia")
if not isinstance(failure_modes, list) or not failure_modes:
    fail("failure_mode_checks deve ser lista nao vazia")
if not isinstance(issues, list) or not issues:
    fail("remediation_issues deve ser lista nao vazia")

issue_index: dict[str, dict] = {}
for issue in issues:
    issue_id = ensure_non_empty_str(issue.get("issue_id"), "remediation_issue.issue_id")
    if issue_id in issue_index:
        fail(f"issue_id duplicado em remediation_issues: {issue_id}")
    if not re.fullmatch(r"ISSUE-F8-[0-9]{2}-[0-9]{2}", issue_id):
        fail(f"issue_id invalido: {issue_id}")
    if issue.get("priority") not in PRIORITIES:
        fail(f"{issue_id} com prioridade invalida: {issue.get('priority')}")
    ensure_non_empty_str(issue.get("title"), f"{issue_id}.title")
    ensure_non_empty_str(issue.get("owner"), f"{issue_id}.owner")
    ensure_non_empty_str(issue.get("status"), f"{issue_id}.status")
    due_date_raw = ensure_non_empty_str(issue.get("due_date"), f"{issue_id}.due_date")
    try:
        date.fromisoformat(due_date_raw)
    except ValueError:
        fail(f"{issue_id}.due_date invalida: {due_date_raw}")
    ensure_set_members(issue.get("source_baselines"), SOURCE_BASELINES, f"{issue_id}.source_baselines")
    if not isinstance(issue.get("linked_conflicts"), list) or not issue["linked_conflicts"]:
        fail(f"{issue_id}.linked_conflicts deve ser lista nao vazia")
    if not isinstance(issue.get("linked_drifts"), list) or not issue["linked_drifts"]:
        fail(f"{issue_id}.linked_drifts deve ser lista nao vazia")
    if not isinstance(issue.get("linked_failure_modes"), list) or not issue["linked_failure_modes"]:
        fail(f"{issue_id}.linked_failure_modes deve ser lista nao vazia")

    micro_issues = issue.get("micro_issues")
    if not isinstance(micro_issues, list) or not micro_issues:
        fail(f"{issue_id}.micro_issues deve ser lista nao vazia")

    seen_microtasks = set()
    for micro in micro_issues:
        micro_id = ensure_non_empty_str(micro.get("microtask_id"), f"{issue_id}.microtask_id")
        if micro_id in seen_microtasks:
            fail(f"{issue_id} possui microtask_id duplicado: {micro_id}")
        seen_microtasks.add(micro_id)
        if not re.fullmatch(r"MT-F8-[0-9]{2}-[0-9]{2}-[0-9]{2}", micro_id):
            fail(f"microtask_id invalido: {micro_id}")
        ensure_non_empty_str(micro.get("title"), f"{micro_id}.title")
        ensure_non_empty_str(micro.get("owner"), f"{micro_id}.owner")
        ensure_non_empty_str(micro.get("estimate"), f"{micro_id}.estimate")
        if micro.get("risk_level") not in RISK_LEVELS:
            fail(f"{micro_id}.risk_level invalido: {micro.get('risk_level')}")
        if micro.get("implementation_status") not in IMPLEMENTATION_STATUS:
            fail(
                f"{micro_id}.implementation_status invalido: {micro.get('implementation_status')}"
            )
        ensure_non_empty_str(micro.get("rollback_hint"), f"{micro_id}.rollback_hint")
        ensure_refs(micro.get("scope_files"), f"{micro_id}.scope_files")
        checks = micro.get("acceptance_checks")
        if not isinstance(checks, list) or not checks:
            fail(f"{micro_id}.acceptance_checks deve ser lista nao vazia")
        for idx, check in enumerate(checks):
            ensure_non_empty_str(check, f"{micro_id}.acceptance_checks[{idx}]")
        ensure_refs(micro.get("evidence_targets"), f"{micro_id}.evidence_targets")
        depends_on = micro.get("depends_on")
        if not isinstance(depends_on, list):
            fail(f"{micro_id}.depends_on deve ser lista")
        for dep in depends_on:
            ensure_non_empty_str(dep, f"{micro_id}.depends_on")
    issue_index[issue_id] = issue

seen_conflicts = set()
for row in conflicts:
    conflict_id = ensure_non_empty_str(row.get("conflict_id"), "conflict_id")
    if conflict_id in seen_conflicts:
        fail(f"conflict_id duplicado: {conflict_id}")
    seen_conflicts.add(conflict_id)
    if row.get("tipo_de_conflito") not in CONFLICT_TYPES:
        fail(f"{conflict_id} com tipo_de_conflito invalido: {row.get('tipo_de_conflito')}")
    if row.get("severidade") not in SEVERITIES:
        fail(f"{conflict_id} com severidade invalida: {row.get('severidade')}")
    ensure_non_empty_str(row.get("origem"), f"{conflict_id}.origem")
    ensure_non_empty_str(row.get("elemento"), f"{conflict_id}.elemento")
    ensure_non_empty_str(row.get("descricao"), f"{conflict_id}.descricao")
    ensure_non_empty_str(row.get("risco_sistemico"), f"{conflict_id}.risco_sistemico")
    ensure_non_empty_str(row.get("recomendacao"), f"{conflict_id}.recomendacao")
    ensure_set_members(row.get("source_baselines"), SOURCE_BASELINES, f"{conflict_id}.source_baselines")
    if not isinstance(row.get("opcoes_de_resolucao"), list) or not row["opcoes_de_resolucao"]:
        fail(f"{conflict_id}.opcoes_de_resolucao deve ser lista nao vazia")
    for idx, option in enumerate(row["opcoes_de_resolucao"]):
        ensure_non_empty_str(option, f"{conflict_id}.opcoes_de_resolucao[{idx}]")
    ensure_refs(row.get("evidence_refs"), f"{conflict_id}.evidence_refs")
    linked_issue = ensure_non_empty_str(row.get("linked_issue_id"), f"{conflict_id}.linked_issue_id")
    if linked_issue not in issue_index:
        fail(f"{conflict_id} aponta para issue inexistente: {linked_issue}")
    if row["severidade"] in {"Critica", "Alta"} and not issue_index[linked_issue]["micro_issues"]:
        fail(f"{conflict_id} de severidade alta/critica sem micro-issues vinculadas")

seen_drifts = set()
for row in drifts:
    drift_id = ensure_non_empty_str(row.get("drift_id"), "drift_id")
    if drift_id in seen_drifts:
        fail(f"drift_id duplicado: {drift_id}")
    seen_drifts.add(drift_id)
    if row.get("bloco") not in DRIFT_BLOCKS:
        fail(f"{drift_id} com bloco invalido: {row.get('bloco')}")
    if row.get("classe") not in DRIFT_CLASSES:
        fail(f"{drift_id} com classe invalida: {row.get('classe')}")
    ensure_set_members(row.get("source_baselines"), SOURCE_BASELINES, f"{drift_id}.source_baselines")
    ensure_non_empty_str(row.get("topico"), f"{drift_id}.topico")
    ensure_non_empty_str(row.get("prd_main"), f"{drift_id}.prd_main")
    ensure_non_empty_str(row.get("prd_working_tree"), f"{drift_id}.prd_working_tree")
    ensure_non_empty_str(row.get("implementacao"), f"{drift_id}.implementacao")
    ensure_non_empty_str(row.get("felix"), f"{drift_id}.felix")
    ensure_non_empty_str(row.get("justificativa"), f"{drift_id}.justificativa")
    ensure_refs(row.get("evidence_refs"), f"{drift_id}.evidence_refs")
    linked_issue = ensure_non_empty_str(row.get("linked_issue_id"), f"{drift_id}.linked_issue_id")
    if linked_issue not in issue_index:
        fail(f"{drift_id} aponta para issue inexistente: {linked_issue}")

seen_failure_ids = set()
seen_failure_modes = set()
for row in failure_modes:
    mode_id = ensure_non_empty_str(row.get("failure_mode_id"), "failure_mode_id")
    if mode_id in seen_failure_ids:
        fail(f"failure_mode_id duplicado: {mode_id}")
    seen_failure_ids.add(mode_id)
    mode_name = ensure_non_empty_str(row.get("failure_mode"), f"{mode_id}.failure_mode")
    if mode_name in seen_failure_modes:
        fail(f"failure_mode duplicado: {mode_name}")
    seen_failure_modes.add(mode_name)
    if row.get("status") not in FAILURE_MODE_STATUS:
        fail(f"{mode_id} com status invalido: {row.get('status')}")
    ensure_set_members(row.get("source_baselines"), SOURCE_BASELINES, f"{mode_id}.source_baselines")
    ensure_refs(row.get("evidencia"), f"{mode_id}.evidencia")
    ensure_non_empty_str(row.get("impacto"), f"{mode_id}.impacto")
    ensure_non_empty_str(row.get("observacao"), f"{mode_id}.observacao")
    linked_issue = ensure_non_empty_str(row.get("linked_issue_id"), f"{mode_id}.linked_issue_id")
    if linked_issue not in issue_index:
        fail(f"{mode_id} aponta para issue inexistente: {linked_issue}")

missing_failure_modes = sorted(REQUIRED_FAILURE_MODES - seen_failure_modes)
if missing_failure_modes:
    fail(f"failure modes obrigatorios ausentes: {missing_failure_modes}")
unexpected_failure_modes = sorted(seen_failure_modes - REQUIRED_FAILURE_MODES)
if unexpected_failure_modes:
    fail(f"failure modes fora da lista fechada: {unexpected_failure_modes}")

conflict_ids = {row["conflict_id"] for row in conflicts}
drift_ids = {row["drift_id"] for row in drifts}
failure_mode_ids = {row["failure_mode_id"] for row in failure_modes}

for issue_id, issue in issue_index.items():
    for conflict_id in issue["linked_conflicts"]:
        if conflict_id not in conflict_ids:
            fail(f"{issue_id} referencia linked_conflict inexistente: {conflict_id}")
    for drift_id in issue["linked_drifts"]:
        if drift_id not in drift_ids:
            fail(f"{issue_id} referencia linked_drift inexistente: {drift_id}")
    for mode_id in issue["linked_failure_modes"]:
        if mode_id not in failure_mode_ids:
            fail(f"{issue_id} referencia linked_failure_mode inexistente: {mode_id}")

backlog_md_text = BACKLOG_MD_PATH.read_text(encoding="utf-8")
for issue_id in issue_index:
    if issue_id not in backlog_md_text:
        fail(f"{issue_id} nao encontrado no backlog markdown")

print("architecture-consistency-backlog: PASS")
