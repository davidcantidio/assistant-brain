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

search_re_each_file() {
  local pattern="$1"
  shift
  local f
  for f in "$@"; do
    if ! search_re "$pattern" "$f"; then
      echo "Padrao obrigatorio ausente em $f: $pattern"
      exit 1
    fi
  done
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
search_re_each_file "Telegram.*primario|primario.*Telegram" PM/DECISION-PROTOCOL.md SEC/SEC-POLICY.md PRD/PRD-MASTER.md
search_re_each_file "Slack.*fallback|fallback.*Slack" PM/DECISION-PROTOCOL.md SEC/SEC-POLICY.md PRD/PRD-MASTER.md
search_re_each_file "email.*canal nao confiavel para comando|email.*nunca.*canal (de comando )?confiavel|nunca.*canal (de comando )?confiavel.*email" PM/DECISION-PROTOCOL.md SEC/SEC-POLICY.md PRD/PRD-MASTER.md
search_re "channel_id.*slack_channel_ids|slack_channel_ids.*channel_id" PM/DECISION-PROTOCOL.md SEC/SEC-POLICY.md
search_re "slack_user_ids.*slack_channel_ids.*nao vazios|slack_channel_ids.*slack_user_ids.*nao vazios" PM/DECISION-PROTOCOL.md SEC/SEC-POLICY.md PRD/PRD-MASTER.md
search_re "UNTRUSTED_COMMAND_SOURCE" PM/DECISION-PROTOCOL.md
search_re "MUST exigir challenge valido de uso unico" PM/DECISION-PROTOCOL.md
search_re "comandos criticos MUST incluir challenge valido" SEC/SEC-POLICY.md
search_re "ttl_padrao = 5 minutos" PM/DECISION-PROTOCOL.md SEC/SEC-SECRETS.md
search_re "maximo 3 tentativas por challenge" SEC/SEC-SECRETS.md
search_re 'sucesso, expiracao TTL, 3 falhas, rotacao de chave ou revogacao manual => `INVALIDATED`' PM/DECISION-PROTOCOL.md
search_re 'registrar `challenge_id`, status final, tentativas e motivo de invalidacao' PM/DECISION-PROTOCOL.md
search_re 'cada comando HITL \(Telegram ou Slack\) MUST gerar `command_id` unico' PM/DECISION-PROTOCOL.md
search_re 'reenvio do mesmo comando MUST ser no-op \(sem transicao adicional de estado\)' PM/DECISION-PROTOCOL.md
search_re 'comando com `command_id` repetido MUST ser auditado como replay' PM/DECISION-PROTOCOL.md
search_re "qualquer falha de autenticacao MUST" PM/DECISION-PROTOCOL.md
search_re "bloquear comando" PM/DECISION-PROTOCOL.md
search_re 'abrir `SECURITY_VIOLATION_REVIEW`' PM/DECISION-PROTOCOL.md SEC/SEC-POLICY.md
search_re "registrar hash do payload do update" PM/DECISION-PROTOCOL.md
search_re "HMAC.*anti-replay.*challenge|challenge.*HMAC.*anti-replay" PM/DECISION-PROTOCOL.md ARC/ARC-DEGRADED-MODE.md SEC/SEC-POLICY.md
search_re_each_file "Telegram.*> 2 heartbeats|> 2 heartbeats.*Telegram" PM/DECISION-PROTOCOL.md ARC/ARC-DEGRADED-MODE.md INCIDENTS/DEGRADED-MODE-PROCEDURE.md
search_re_each_file "fallback Slack" PM/DECISION-PROTOCOL.md ARC/ARC-DEGRADED-MODE.md INCIDENTS/DEGRADED-MODE-PROCEDURE.md
search_re_each_file "HMAC.*anti-replay.*challenge|challenge.*HMAC.*anti-replay" PM/DECISION-PROTOCOL.md ARC/ARC-DEGRADED-MODE.md INCIDENTS/DEGRADED-MODE-PROCEDURE.md
search_re "RESTORE_TELEGRAM_CHANNEL" PM/DECISION-PROTOCOL.md ARC/ARC-DEGRADED-MODE.md INCIDENTS/DEGRADED-MODE-PROCEDURE.md
search_re 'action: "restore_telegram_channel"' SEC/allowlists/ACTIONS.yaml
search_re "approval queue para acao sensivel" PM/TRACEABILITY/FELIX-ALIGNMENT-MATRIX.md
search_re "trust ladder|concessao gradual de permissoes" PM/TRACEABILITY/FELIX-ALIGNMENT-MATRIX.md
search_re "email nao confiavel para comando" EVALS/SYSTEM-HEALTH-THRESHOLDS.md
search_re "lifecycle de challenge HITL completo" EVALS/SYSTEM-HEALTH-THRESHOLDS.md
search_re "aprovacao humana explicita em side effect financeiro" EVALS/SYSTEM-HEALTH-THRESHOLDS.md

python3 - <<'PY'
from datetime import datetime, timedelta, timezone
import json
import sys
from pathlib import Path


def fail(msg: str) -> None:
    print(msg)
    sys.exit(1)


schema = json.loads(Path("ARC/schemas/decision.schema.json").read_text(encoding="utf-8"))
required = set(schema.get("required", []))
missing_required = sorted({"challenge_id", "challenge_status", "challenge_expires_at"} - required)
if missing_required:
    fail(f"decision.schema.json sem campos obrigatorios de challenge: {missing_required}")

challenge_status = (
    schema.get("properties", {})
    .get("challenge_status", {})
    .get("enum", [])
)
expected_status = {"NOT_REQUIRED", "PENDING", "VALIDATED", "EXPIRED", "INVALIDATED"}
if set(challenge_status) != expected_status:
    fail("decision.schema.json com enum invalido para challenge_status.")

challenge_expires_meta = schema.get("properties", {}).get("challenge_expires_at", {})
expires_type = challenge_expires_meta.get("type")
if sorted(expires_type) != ["null", "string"]:
    fail("decision.schema.json com tipo invalido para challenge_expires_at (esperado string|null).")
if challenge_expires_meta.get("format") != "date-time":
    fail("decision.schema.json com formato invalido para challenge_expires_at (esperado date-time).")


def parse_iso8601(value: str) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def evaluate_challenge(
    *,
    challenge_status: str,
    challenge_expires_at: str,
    attempt_count: int,
    command_id: str,
    last_validated_command_id: str | None,
    invalidation_reason: str | None = None,
    now: datetime,
) -> tuple[str, str | None]:
    if challenge_status != "PENDING":
        return "BLOCK", "challenge_not_pending"

    if invalidation_reason in {"key_rotated", "manual_revoked"}:
        return "BLOCK", invalidation_reason

    expires_at = parse_iso8601(challenge_expires_at)
    if now > expires_at:
        return "BLOCK", "ttl_expired"

    if attempt_count >= 3:
        return "BLOCK", "max_attempts_reached"

    if last_validated_command_id == command_id:
        return "BLOCK", "single_use_replay"

    return "ALLOW", None


issued_at = datetime(2026, 2, 27, 12, 0, 0, tzinfo=timezone.utc)
expires_at = issued_at + timedelta(minutes=5)

decision_allow = evaluate_challenge(
    challenge_status="PENDING",
    challenge_expires_at=expires_at.isoformat().replace("+00:00", "Z"),
    attempt_count=0,
    command_id="CMD-001",
    last_validated_command_id=None,
    now=issued_at + timedelta(minutes=3),
)
if decision_allow != ("ALLOW", None):
    fail("challenge.lifecycle.valid deveria permitir challenge valido dentro do TTL.")

decision_expired = evaluate_challenge(
    challenge_status="PENDING",
    challenge_expires_at=expires_at.isoformat().replace("+00:00", "Z"),
    attempt_count=0,
    command_id="CMD-002",
    last_validated_command_id=None,
    now=issued_at + timedelta(minutes=6),
)
if decision_expired != ("BLOCK", "ttl_expired"):
    fail("challenge.lifecycle.expired deveria bloquear challenge expirado.")

decision_three_fails = evaluate_challenge(
    challenge_status="PENDING",
    challenge_expires_at=expires_at.isoformat().replace("+00:00", "Z"),
    attempt_count=3,
    command_id="CMD-003",
    last_validated_command_id=None,
    now=issued_at + timedelta(minutes=2),
)
if decision_three_fails != ("BLOCK", "max_attempts_reached"):
    fail("challenge.lifecycle.max_attempts deveria invalidar apos 3 falhas.")

decision_key_rotated = evaluate_challenge(
    challenge_status="PENDING",
    challenge_expires_at=expires_at.isoformat().replace("+00:00", "Z"),
    attempt_count=0,
    command_id="CMD-004",
    last_validated_command_id=None,
    invalidation_reason="key_rotated",
    now=issued_at + timedelta(minutes=1),
)
if decision_key_rotated != ("BLOCK", "key_rotated"):
    fail("challenge.lifecycle.key_rotated deveria bloquear por rotacao de chave.")

decision_manual_revoked = evaluate_challenge(
    challenge_status="PENDING",
    challenge_expires_at=expires_at.isoformat().replace("+00:00", "Z"),
    attempt_count=0,
    command_id="CMD-005",
    last_validated_command_id=None,
    invalidation_reason="manual_revoked",
    now=issued_at + timedelta(minutes=1),
)
if decision_manual_revoked != ("BLOCK", "manual_revoked"):
    fail("challenge.lifecycle.manual_revoked deveria bloquear por revogacao manual.")

decision_single_use = evaluate_challenge(
    challenge_status="PENDING",
    challenge_expires_at=expires_at.isoformat().replace("+00:00", "Z"),
    attempt_count=0,
    command_id="CMD-006",
    last_validated_command_id="CMD-006",
    now=issued_at + timedelta(minutes=1),
)
if decision_single_use != ("BLOCK", "single_use_replay"):
    fail("challenge.lifecycle.single_use deveria bloquear replay do mesmo command_id.")
PY

python3 - <<'PY'
import json
import sys
from pathlib import Path


def fail(msg: str) -> None:
    print(msg)
    sys.exit(1)


schema = json.loads(Path("ARC/schemas/decision.schema.json").read_text(encoding="utf-8"))
required = set(schema.get("required", []))
if "last_command_id" not in required:
    fail("decision.schema.json sem required obrigatorio: last_command_id.")

last_command_meta = schema.get("properties", {}).get("last_command_id", {})
if sorted(last_command_meta.get("type", [])) != ["null", "string"]:
    fail("decision.schema.json com tipo invalido para last_command_id (esperado string|null).")


def apply_hitl_command(state: dict, command_id: str) -> str:
    if command_id in state["seen_command_ids"]:
        state["audit_events"].append({"command_id": command_id, "event": "NO_OP_DUPLICATE_AUDITED"})
        return "NO_OP_DUPLICATE_AUDITED"
    state["seen_command_ids"].add(command_id)
    state["transition_count"] += 1
    return "APPLIED"


state = {"seen_command_ids": set(), "transition_count": 0, "audit_events": []}
first_apply = apply_hitl_command(state, "CMD-1001")
if first_apply != "APPLIED":
    fail("command_id.first_apply deveria retornar APPLIED.")
if state["transition_count"] != 1:
    fail("command_id.first_apply deveria gerar exatamente 1 transicao.")

duplicate_apply = apply_hitl_command(state, "CMD-1001")
if duplicate_apply != "NO_OP_DUPLICATE_AUDITED":
    fail("command_id.duplicate_apply deveria retornar NO_OP_DUPLICATE_AUDITED.")
if state["transition_count"] != 1:
    fail("command_id.duplicate_apply nao pode gerar nova transicao.")
if state["audit_events"] != [{"command_id": "CMD-1001", "event": "NO_OP_DUPLICATE_AUDITED"}]:
    fail("command_id.duplicate_apply deveria registrar evento explicito de replay auditado.")
PY

python3 - <<'PY'
import hashlib
import json
import sys
from pathlib import Path


def fail(msg: str) -> None:
    print(msg)
    sys.exit(1)


schema = json.loads(Path("ARC/schemas/decision.schema.json").read_text(encoding="utf-8"))
required = set(schema.get("required", []))
required_auth_fields = {
    "approver_operator_id",
    "approver_channel",
    "approver_telegram_user_id",
    "approver_telegram_chat_id",
    "approver_slack_user_id",
    "approver_slack_channel_id",
    "auth_method",
}
missing = sorted(required_auth_fields - required)
if missing:
    fail(f"decision.schema.json sem campos obrigatorios de auth/canal: {missing}")


def process_hitl_command(payload: dict) -> tuple[str, dict]:
    if payload.get("auth_valid") is True and payload.get("channel_valid") is True:
        return "ALLOW", {"incident_ref": None, "payload_hash": None}
    payload_hash = hashlib.sha256(
        json.dumps(payload, sort_keys=True, separators=(",", ":")).encode("utf-8")
    ).hexdigest()
    return (
        "BLOCK",
        {
            "incident_ref": "SECURITY_VIOLATION_REVIEW",
            "payload_hash": payload_hash,
            "reason": "invalid_auth_or_channel",
        },
    )


allow_status, allow_evidence = process_hitl_command(
    {"auth_valid": True, "channel_valid": True, "command_id": "CMD-2001"}
)
if allow_status != "ALLOW":
    fail("auth_channel.valid deveria permitir comando com auth/canal validos.")
if allow_evidence.get("incident_ref") is not None:
    fail("auth_channel.valid nao deve abrir incidente.")

invalid_auth_payload = {"auth_valid": False, "channel_valid": True, "command_id": "CMD-2002"}
block_status, block_evidence = process_hitl_command(invalid_auth_payload)
if block_status != "BLOCK":
    fail("auth_channel.invalid_auth deveria bloquear comando invalido.")
if block_evidence.get("incident_ref") != "SECURITY_VIOLATION_REVIEW":
    fail("auth_channel.invalid_auth deveria abrir SECURITY_VIOLATION_REVIEW.")
expected_hash = hashlib.sha256(
    json.dumps(invalid_auth_payload, sort_keys=True, separators=(",", ":")).encode("utf-8")
).hexdigest()
if block_evidence.get("payload_hash") != expected_hash:
    fail("auth_channel.invalid_auth deveria registrar hash do payload.")

invalid_channel_payload = {"auth_valid": True, "channel_valid": False, "command_id": "CMD-2003"}
block_channel_status, block_channel_evidence = process_hitl_command(invalid_channel_payload)
if block_channel_status != "BLOCK":
    fail("auth_channel.invalid_channel deveria bloquear comando invalido.")
if block_channel_evidence.get("incident_ref") != "SECURITY_VIOLATION_REVIEW":
    fail("auth_channel.invalid_channel deveria abrir SECURITY_VIOLATION_REVIEW.")
if not block_channel_evidence.get("payload_hash"):
    fail("auth_channel.invalid_channel deveria registrar hash de payload.")
PY

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
import sys
from pathlib import Path

files = [
    "PM/DECISION-PROTOCOL.md",
    "SEC/SEC-POLICY.md",
    "PRD/PRD-MASTER.md",
]
ambiguous_lines = []

for path in files:
    lines = Path(path).read_text(encoding="utf-8").splitlines()
    for lineno, raw in enumerate(lines, start=1):
        line = raw.strip()
        low = line.lower()
        if "email" not in low:
            continue
        if "canal confiavel" not in low and "comando confiavel" not in low:
            continue
        if "confirma" in low and "canal confiavel" in low:
            continue
        if any(token in low for token in ("nao", "nunca", "false", "untrusted")):
            continue
        ambiguous_lines.append(f"{path}:{lineno}:{line}")

if ambiguous_lines:
    print("Linguagem ambigua detectada para confianca de email:")
    for item in ambiguous_lines:
        print(item)
    sys.exit(1)
PY

python3 - <<'PY'
from collections import Counter
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
            "display_name": None,
            "enabled": None,
            "telegram_user_id": None,
            "telegram_chat_ids": [],
            "slack_user_ids": [],
            "slack_channel_ids": [],
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
    if stripped.startswith("slack_user_ids:"):
        section = "slack_user_ids"
        continue
    if stripped.startswith("slack_channel_ids:"):
        section = "slack_channel_ids"
        continue

    if stripped.startswith("- "):
        item = stripped[2:].strip().strip('"')
        if section == "permissions":
            current["permissions"].append(item)
        elif section == "telegram_chat_ids":
            current["telegram_chat_ids"].append(item)
        elif section == "slack_user_ids":
            current["slack_user_ids"].append(item)
        elif section == "slack_channel_ids":
            current["slack_channel_ids"].append(item)
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
    elif key == "display_name":
        current["display_name"] = value
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

operator_ids = []
for op in operators:
    op_id = (op.get("operator_id") or "").strip()
    if not op_id:
        fail("OPERATORS.yaml com operador sem operator_id.")
    operator_ids.append(op_id)

duplicate_operator_ids = sorted([op_id for op_id, count in Counter(operator_ids).items() if count > 1])
if duplicate_operator_ids:
    fail(f"OPERATORS.yaml com operator_id duplicado: {', '.join(duplicate_operator_ids)}")

enabled_ops = [op for op in operators if op.get("enabled") is True]
if not enabled_ops:
    fail("OPERATORS.yaml sem operador habilitado (enabled: true).")

required_permissions = {"approve", "reject", "kill"}
enabled_user_ids = set()
enabled_chat_id_owner = {}
slack_user_id_owner = {}
slack_channel_id_owner = {}
for op in enabled_ops:
    op_id = op.get("operator_id") or "<sem_operator_id>"
    display_name = (op.get("display_name") or "").strip()
    if not display_name:
        fail(f"Operador habilitado sem display_name: {op_id}")
    user_id = op.get("telegram_user_id")
    if not user_id:
        fail(f"Operador habilitado sem telegram_user_id: {op_id}")
    if not re.fullmatch(r"\d+", user_id):
        fail(f"telegram_user_id invalido para operador {op_id}: {user_id}")
    if user_id in enabled_user_ids:
        fail(f"telegram_user_id duplicado entre operadores habilitados: {user_id}")
    enabled_user_ids.add(user_id)
    chat_ids = op.get("telegram_chat_ids") or []
    if not chat_ids:
        fail(f"Operador habilitado sem telegram_chat_ids: {op_id}")
    if len(chat_ids) != len(set(chat_ids)):
        fail(f"Operador habilitado com telegram_chat_ids duplicado: {op_id}")
    for chat_id in chat_ids:
        if not re.fullmatch(r"\d+", str(chat_id)):
            fail(f"telegram_chat_id invalido para operador {op_id}: {chat_id}")
        owner = enabled_chat_id_owner.get(str(chat_id))
        if owner and owner != op_id:
            fail(
                "telegram_chat_id compartilhado entre operadores habilitados: "
                f"{chat_id} ({owner}, {op_id})"
            )
        enabled_chat_id_owner[str(chat_id)] = op_id
    if str(user_id) not in {str(chat_id) for chat_id in chat_ids}:
        fail(f"Operador habilitado sem vinculo user/chat para identidade Telegram: {op_id}")
    if op.get("slack_ready") is None:
        fail(f"Operador habilitado sem campo slack_ready: {op_id}")
    slack_ready = op.get("slack_ready") is True
    slack_user_ids = [str(item).strip() for item in (op.get("slack_user_ids") or [])]
    slack_channel_ids = [str(item).strip() for item in (op.get("slack_channel_ids") or [])]
    if slack_ready:
        if not slack_user_ids:
            fail(f"Operador habilitado com slack_ready=true sem slack_user_ids: {op_id}")
        if not slack_channel_ids:
            fail(f"Operador habilitado com slack_ready=true sem slack_channel_ids: {op_id}")
        if any(not item for item in slack_user_ids):
            fail(f"Operador habilitado com slack_user_ids vazio: {op_id}")
        if any(not item for item in slack_channel_ids):
            fail(f"Operador habilitado com slack_channel_ids vazio: {op_id}")
        if len(slack_user_ids) != len(set(slack_user_ids)):
            fail(f"Operador habilitado com slack_user_ids duplicado: {op_id}")
        if len(slack_channel_ids) != len(set(slack_channel_ids)):
            fail(f"Operador habilitado com slack_channel_ids duplicado: {op_id}")
        for slack_user_id in slack_user_ids:
            owner = slack_user_id_owner.get(slack_user_id)
            if owner and owner != op_id:
                fail(
                    "slack_user_id compartilhado entre operadores habilitados: "
                    f"{slack_user_id} ({owner}, {op_id})"
                )
            slack_user_id_owner[slack_user_id] = op_id
        for slack_channel_id in slack_channel_ids:
            owner = slack_channel_id_owner.get(slack_channel_id)
            if owner and owner != op_id:
                fail(
                    "slack_channel_id compartilhado entre operadores habilitados: "
                    f"{slack_channel_id} ({owner}, {op_id})"
                )
            slack_channel_id_owner[slack_channel_id] = op_id
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
