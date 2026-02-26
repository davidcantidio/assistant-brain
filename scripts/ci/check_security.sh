#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

search_re() {
  local pattern="$1"
  shift
  if command -v rg >/dev/null 2>&1; then
    rg -n -- "$pattern" "$@" >/dev/null
  else
    grep -nE -- "$pattern" "$@" >/dev/null
  fi
}

required_files=(
  "SEC/allowlists/DOMAINS.yaml"
  "SEC/allowlists/TOOLS.yaml"
  "SEC/allowlists/ACTIONS.yaml"
  "SEC/allowlists/OPERATORS.yaml"
  "SEC/allowlists/PROVIDERS.yaml"
  "SEC/allowlists/AGENT-IDENTITY-SURFACES.yaml"
)
for f in "${required_files[@]}"; do
  [[ -f "$f" ]] || { echo "Arquivo obrigatorio ausente: $f"; exit 1; }
done

# basic leak signatures in tracked files
if git grep -nE \
  -e 'sk-[A-Za-z0-9]{20,}' \
  -e 'xox[baprs]-[A-Za-z0-9-]{10,}' \
  -e 'AKIA[0-9A-Z]{16}' \
  -- . > /tmp/security_hits.txt; then
  echo "Possivel segredo detectado em arquivos versionados:"
  cat /tmp/security_hits.txt
  exit 1
else
  status=$?
  if [ "$status" -ne 1 ]; then
    echo "Falha ao executar scan de segredos (git grep exit=$status)"
    exit "$status"
  fi
fi

search_re "telegram_user_id" SEC/allowlists/OPERATORS.yaml
search_re "trading_live_requires_backup_operator" SEC/allowlists/OPERATORS.yaml
search_re "backup_operator_strategy" SEC/allowlists/OPERATORS.yaml
search_re "backup_operator_operator_id" SEC/allowlists/OPERATORS.yaml

search_re "## Classificacao de Sensibilidade" SEC/SEC-POLICY.md
search_re '`public`:' SEC/SEC-POLICY.md
search_re '`internal`:' SEC/SEC-POLICY.md
search_re '`sensitive`:' SEC/SEC-POLICY.md
search_re "prompt_hash.*prompt_summary" SEC/SEC-POLICY.md
search_re "prompt bruto MUST ser bloqueado por default" SEC/SEC-POLICY.md
search_re '`sensitive` MUST aplicar provider allowlist restrita' PRD/PRD-MASTER.md
search_re 'classificacao `public/internal/sensitive`' PRD/PRD-MASTER.md
search_re "backup_operator" PRD/PRD-MASTER.md
search_re "AGENT-IDENTITY-SURFACES\\.yaml" PRD/PRD-MASTER.md SEC/SEC-POLICY.md
search_re "agent_account_id.*personal_account_id|personal_account_id.*agent_account_id" PRD/PRD-MASTER.md SEC/SEC-POLICY.md
search_re "least privilege" PRD/PRD-MASTER.md SEC/SEC-POLICY.md
search_re "financial_side_effect_requires_explicit_human_approval: true" PRD/PRD-MASTER.md
search_re "email_command_channel_trusted: false" PRD/PRD-MASTER.md

search_re "email.*canal nao confiavel para comando|nunca canal confiavel de comando" PM/DECISION-PROTOCOL.md SEC/SEC-POLICY.md PRD/PRD-MASTER.md
search_re "UNTRUSTED_COMMAND_SOURCE" PM/DECISION-PROTOCOL.md
search_re "MUST exigir challenge valido de uso unico" PM/DECISION-PROTOCOL.md
search_re "comandos criticos MUST incluir challenge valido" SEC/SEC-POLICY.md
search_re "HMAC.*anti-replay.*challenge|challenge.*HMAC.*anti-replay" PM/DECISION-PROTOCOL.md ARC/ARC-DEGRADED-MODE.md SEC/SEC-POLICY.md
search_re "RESTORE_TELEGRAM_CHANNEL" PM/DECISION-PROTOCOL.md ARC/ARC-DEGRADED-MODE.md INCIDENTS/DEGRADED-MODE-PROCEDURE.md
search_re 'action: "restore_telegram_channel"' SEC/allowlists/ACTIONS.yaml
search_re "approval queue para acao sensivel" PM/TRACEABILITY/FELIX-ALIGNMENT-MATRIX.md
search_re "trust ladder|concessao gradual de permissoes" PM/TRACEABILITY/FELIX-ALIGNMENT-MATRIX.md
search_re "email nao confiavel para comando" EVALS/SYSTEM-HEALTH-THRESHOLDS.md
search_re "lifecycle de challenge HITL completo" EVALS/SYSTEM-HEALTH-THRESHOLDS.md
search_re "aprovacao humana explicita em side effect financeiro" EVALS/SYSTEM-HEALTH-THRESHOLDS.md

python3 - <<'PY'
import re
import sys
from pathlib import Path


def fail(msg: str) -> None:
    print(msg)
    sys.exit(1)


text = Path("SEC/allowlists/ACTIONS.yaml").read_text(encoding="utf-8")
if not re.search(
    r'- action:\s*"restore_telegram_channel"\s*\n\s*policy:\s*"decision_and_hitl_required"',
    text,
):
    fail(
        "ACTIONS.yaml sem politica obrigatoria para restore_telegram_channel "
        "(esperado decision_and_hitl_required)."
    )
PY

python3 - <<'PY'
import re
import sys
from pathlib import Path

text = Path("SEC/allowlists/PROVIDERS.yaml").read_text(encoding="utf-8")


def fail(msg: str) -> None:
    print(msg)
    sys.exit(1)


lines = text.splitlines()
profiles = {}
in_profiles = False
current = None
in_allowed = False

for raw in lines:
    if not raw.strip() or raw.strip().startswith("#"):
        continue

    indent = len(raw) - len(raw.lstrip(" "))
    stripped = raw.strip()

    if stripped == "profiles:" and indent == 0:
        in_profiles = True
        current = None
        in_allowed = False
        continue

    if in_profiles and indent == 0 and stripped.endswith(":") and stripped != "profiles:":
        in_profiles = False
        current = None
        in_allowed = False

    if not in_profiles:
        continue

    if indent == 2 and stripped.endswith(":"):
        current = stripped[:-1]
        profiles[current] = {
            "require_zdr": None,
            "no_fallback_default": None,
            "pin_provider_default": None,
            "allowed_providers": [],
        }
        in_allowed = False
        continue

    if current is None:
        continue

    if indent == 4 and stripped == "allowed_providers:":
        in_allowed = True
        continue

    if in_allowed and indent >= 6 and stripped.startswith("- "):
        profiles[current]["allowed_providers"].append(stripped[2:].strip().strip('"'))
        continue

    in_allowed = False
    if indent == 4 and ":" in stripped:
        key, value = stripped.split(":", 1)
        key = key.strip()
        value = value.strip().strip('"')
        if key in {"require_zdr", "no_fallback_default", "pin_provider_default"}:
            if value not in {"true", "false"}:
                fail(f"PROVIDERS.yaml invalido: {current}.{key} nao booleano.")
            profiles[current][key] = value == "true"


for profile in ("public", "internal", "sensitive"):
    if profile not in profiles:
        fail(f"PROVIDERS.yaml sem profile obrigatorio: {profile}")
    if not profiles[profile]["allowed_providers"]:
        fail(f"PROVIDERS.yaml sem allowed_providers para profile: {profile}")

expected_flags = {
    "public": {"require_zdr": False, "no_fallback_default": False, "pin_provider_default": False},
    "internal": {"require_zdr": False, "no_fallback_default": False, "pin_provider_default": False},
    "sensitive": {"require_zdr": True, "no_fallback_default": True, "pin_provider_default": True},
}

for profile, flags in expected_flags.items():
    for key, expected_value in flags.items():
        got = profiles[profile][key]
        if got is None:
            fail(f"PROVIDERS.yaml sem campo obrigatorio {profile}.{key}")
        if got != expected_value:
            fail(
                f"PROVIDERS.yaml com valor invalido em {profile}.{key} "
                f"(esperado: {str(expected_value).lower()})."
            )
PY

python3 - <<'PY'
import re
import sys
from pathlib import Path

path = Path("SEC/allowlists/OPERATORS.yaml")
text = path.read_text(encoding="utf-8")
lines = text.splitlines()


def fail(msg: str) -> None:
    print(msg)
    sys.exit(1)


def require_bool_key(key: str, expected: bool | None = None) -> None:
    m = re.search(rf"^\s*{re.escape(key)}\s*:\s*(true|false)\s*$", text, re.MULTILINE)
    if not m:
        fail(f"OPERATORS.yaml sem chave booleana obrigatoria: {key}")
    if expected is not None:
        value = m.group(1) == "true"
        if value != expected:
            fail(f"OPERATORS.yaml com valor invalido em {key} (esperado: {str(expected).lower()}).")


def require_string_key(key: str) -> str:
    m = re.search(rf'^\s*{re.escape(key)}\s*:\s*"([^"]+)"\s*$', text, re.MULTILINE)
    if not m:
        fail(f"OPERATORS.yaml sem chave string obrigatoria: {key}")
    value = m.group(1).strip()
    if not value:
        fail(f"OPERATORS.yaml com valor vazio em: {key}")
    return value


require_bool_key("trading_live_requires_backup_operator", expected=True)
require_bool_key("slack_fallback_requires_non_empty_user_and_channel_ids", expected=True)
require_bool_key("live_ready", expected=False)
backup_operator_strategy = require_string_key("backup_operator_strategy")
backup_operator_operator_id = require_string_key("backup_operator_operator_id")

if backup_operator_strategy not in {"breakglass_designated", "active_backup"}:
    fail(
        "OPERATORS.yaml com backup_operator_strategy invalida "
        "(valores aceitos: breakglass_designated, active_backup)."
    )

mode_m = re.search(r'^\s*mode\s*:\s*"?(single_primary|multi_operator)"?\s*$', text, re.MULTILINE)
if not mode_m:
    fail("OPERATORS.yaml sem modo valido (single_primary|multi_operator).")
mode = mode_m.group(1)

operators = []
current = None
section = None

for raw in lines:
    stripped = raw.strip()
    if not stripped or stripped.startswith("#"):
        continue

    if stripped.startswith("- operator_id:"):
        if current:
            operators.append(current)
        current = {
            "operator_id": stripped.split(":", 1)[1].strip().strip('"'),
            "enabled": None,
            "telegram_user_id": None,
            "telegram_chat_ids": [],
            "permissions": [],
            "slack_ready": None,
        }
        section = None
        continue

    if current is None:
        continue

    if stripped.startswith("permissions:"):
        section = "permissions"
        continue
    if stripped.startswith("telegram_chat_ids:"):
        section = "telegram_chat_ids"
        continue

    if stripped.startswith("- "):
        item = stripped[2:].strip().strip('"')
        if section == "permissions":
            current["permissions"].append(item)
        elif section == "telegram_chat_ids":
            current["telegram_chat_ids"].append(item)
        continue

    section = None
    if ":" not in stripped:
        continue
    key, value = stripped.split(":", 1)
    key = key.strip()
    value = value.strip().strip('"')

    if key == "enabled":
        if value not in ("true", "false"):
            fail(f"OPERATORS.yaml invalido: enabled nao booleano para operador {current['operator_id']}.")
        current["enabled"] = value == "true"
    elif key == "telegram_user_id":
        current["telegram_user_id"] = value
    elif key == "slack_ready":
        if value not in ("true", "false"):
            fail(f"OPERATORS.yaml invalido: slack_ready nao booleano para operador {current['operator_id']}.")
        current["slack_ready"] = value == "true"

if current:
    operators.append(current)

if not operators:
    fail("OPERATORS.yaml sem bloco de operators.")

enabled_ops = [op for op in operators if op.get("enabled") is True]
if not enabled_ops:
    fail("OPERATORS.yaml sem operador habilitado (enabled: true).")

required_permissions = {"approve", "reject", "kill"}
for op in enabled_ops:
    op_id = op.get("operator_id") or "<sem_operator_id>"
    user_id = op.get("telegram_user_id")
    if not user_id:
        fail(f"Operador habilitado sem telegram_user_id: {op_id}")
    if not re.fullmatch(r"\d+", user_id):
        fail(f"telegram_user_id invalido para operador {op_id}: {user_id}")
    if not op.get("telegram_chat_ids"):
        fail(f"Operador habilitado sem telegram_chat_ids: {op_id}")
    if op.get("slack_ready") is None:
        fail(f"Operador habilitado sem campo slack_ready: {op_id}")
    permissions = set(op.get("permissions", []))
    missing = sorted(required_permissions - permissions)
    if missing:
        fail(f"Operador habilitado sem permissoes HITL obrigatorias ({', '.join(missing)}): {op_id}")

if mode == "single_primary" and len(enabled_ops) != 1:
    fail("OPERATORS.yaml invalido: mode=single_primary exige exatamente 1 operador habilitado.")

ops_by_id = {op.get("operator_id"): op for op in operators if op.get("operator_id")}
backup_op = ops_by_id.get(backup_operator_operator_id)
if backup_op is None:
    fail(
        "OPERATORS.yaml invalido: backup_operator_operator_id nao encontrado em operators: "
        f"{backup_operator_operator_id}"
    )

backup_permissions = set(backup_op.get("permissions", []))
missing_backup_permissions = sorted(required_permissions - backup_permissions)
if missing_backup_permissions:
    fail(
        "OPERATORS.yaml invalido: backup operator sem permissoes obrigatorias "
        f"({', '.join(missing_backup_permissions)}): {backup_operator_operator_id}"
    )

if mode == "single_primary" and backup_op.get("enabled") is True:
    fail("OPERATORS.yaml invalido: backup operator deve ficar desabilitado em mode=single_primary.")
PY

python3 - <<'PY'
import re
import sys
from pathlib import Path

path = Path("SEC/allowlists/AGENT-IDENTITY-SURFACES.yaml")
text = path.read_text(encoding="utf-8")
lines = text.splitlines()


def fail(msg: str) -> None:
    print(msg)
    sys.exit(1)


if not re.search(r'^\s*segregation_required\s*:\s*true\s*$', text, re.MULTILINE):
    fail("AGENT-IDENTITY-SURFACES.yaml sem segregation_required=true.")
if not re.search(r'^\s*least_privilege_required\s*:\s*true\s*$', text, re.MULTILINE):
    fail("AGENT-IDENTITY-SURFACES.yaml sem least_privilege_required=true.")

surfaces = []
current = None
section = None

for raw in lines:
    stripped = raw.strip()
    if not stripped or stripped.startswith("#"):
        continue

    if stripped.startswith("- surface:"):
        if current:
            surfaces.append(current)
        current = {
            "surface": stripped.split(":", 1)[1].strip().strip('"'),
            "agent_account_id": None,
            "personal_account_id": None,
            "segregation_enforced": None,
            "minimum_scope": [],
        }
        section = None
        continue

    if current is None:
        continue

    if stripped.startswith("minimum_scope:"):
        section = "minimum_scope"
        continue

    if stripped.startswith("- "):
        if section == "minimum_scope":
            current["minimum_scope"].append(stripped[2:].strip().strip('"'))
        continue

    section = None
    if ":" not in stripped:
        continue
    key, value = stripped.split(":", 1)
    key = key.strip()
    value = value.strip().strip('"')

    if key in {"agent_account_id", "personal_account_id"}:
        current[key] = value
    elif key == "segregation_enforced":
        if value not in {"true", "false"}:
            fail(f"AGENT-IDENTITY-SURFACES.yaml com segregation_enforced invalido para superficie {current['surface']}.")
        current["segregation_enforced"] = value == "true"

if current:
    surfaces.append(current)

if not surfaces:
    fail("AGENT-IDENTITY-SURFACES.yaml sem bloco de surfaces.")

required_surfaces = {"social", "email", "pagamentos", "carteira"}
found_surfaces = {s["surface"] for s in surfaces}
missing_surfaces = sorted(required_surfaces - found_surfaces)
if missing_surfaces:
    fail(f"AGENT-IDENTITY-SURFACES.yaml sem superficies obrigatorias: {missing_surfaces}")

for entry in surfaces:
    surface = entry["surface"] or "<surface_vazia>"
    agent_account_id = entry.get("agent_account_id")
    personal_account_id = entry.get("personal_account_id")

    if not agent_account_id:
        fail(f"Superficie sem agent_account_id: {surface}")
    if not personal_account_id:
        fail(f"Superficie sem personal_account_id: {surface}")
    if agent_account_id == personal_account_id:
        fail(f"Superficie com agent_account_id igual a personal_account_id: {surface}")
    if entry.get("segregation_enforced") is not True:
        fail(f"Superficie sem segregation_enforced=true: {surface}")
    if not entry.get("minimum_scope"):
        fail(f"Superficie sem minimum_scope para least privilege: {surface}")
PY

echo "security-check: PASS"
