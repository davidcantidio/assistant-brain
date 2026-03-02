# Inventario de Caos - Baseline 2026-03-02

## Objetivo
Congelar o estado inicial de desorganizacao para orientar a limpeza incremental sem alterar runtime em producao.

## Fonte
- snapshot de `git status --short` em `2026-03-02`.
- classificacao adotada: `normativo`, `operacional`, `artifact estavel`, `artifact temporario`, `lixo`.

## Matriz de Classificacao
| Caminho | Status baseline | Classe | Tratamento |
|---|---|---|---|
| `.env_example` | M | operacional | manter versionado (template de ambiente) |
| `.gitignore` | M | operacional | reforcar politica de ruido/gerados |
| `ARC/ARC-CORE.md` | M | normativo | manter versionado |
| `ARC/ARC-MODEL-ROUTING.md` | M | normativo | manter versionado |
| `DEV/DEV-OPENCLAW-SETUP.md` | M | normativo | manter versionado e alinhado ao canonico |
| `Makefile` | M | operacional | manter versionado (targets/gates) |
| `PM/PHASES/F9-ONBOARDING-.../*.md` | M | normativo | manter versionado |
| `PRD/CHANGELOG.md` | M | normativo | manter versionado |
| `PRD/PRD-MASTER.md` | M | normativo | manter versionado |
| `PRD/ROADMAP.md` | M | normativo | manter versionado |
| `README.md` | M | operacional | manter versionado como doc auxiliar |
| `SEC/SEC-POLICY.md` | M | normativo | manter versionado |
| `SEC/allowlists/PROVIDERS.yaml` | M | normativo | manter versionado |
| `config.yaml` | M | operacional | manter versionado |
| `config/openclaw.env.example` | M | operacional | manter versionado |
| `deep-research-report-2.md` | D | artifact temporario | manter removido do git |
| `deep-research-report.md` | D | artifact temporario | manter removido do git |
| `felixcraft.pdf` | D | artifact temporario | manter removido do git (fonte conceitual segue em `.md`) |
| `scripts/ci/check_phase_f9_litellm_keygen.sh` | M | operacional | manter versionado |
| `scripts/ci/check_quality.sh` | M | operacional | manter versionado |
| `scripts/ci/eval_models.sh` | M | operacional | manter versionado |
| `scripts/ci/eval_runtime_contracts.sh` | M | operacional | manter versionado |
| `scripts/onboard_linux.sh` | M | operacional | manter versionado |
| `scripts/verify_linux.sh` | M | operacional | manter versionado |
| `PM/PHASES/F10-CONVERGENCIA-PRD-RUNTIME-SEM-REGRESSAO/` | ?? | normativo | manter versionado |
| `artifacts/phase-f10/*.md` | ?? | artifact estavel | manter versionado |
| `artifacts/phase-f10/runtime-*.json` | ?? | artifact temporario | mover classe para gerado/nao versionado |
| `artifacts/phase-f9/epic-f9-02-issue-03-doc-sync-onboarding-canais.md` | ?? | artifact estavel | manter versionado |
| `artifacts/phase-f9/epic-f9-02-telegram-slack-bootstrap.md` | ?? | artifact estavel | manter versionado |
| `scripts/check_telegram_conflict.sh` | ?? | operacional | manter versionado |
| `scripts/ci/check_phase_f10_runtime_convergence.sh` | ?? | operacional | manter versionado |
| `scripts/runtime/*` | ?? | operacional | manter versionado |
| `scripts/ci/__pycache__/phase_f8_contract_review.cpython-314.pyc` | tracked | lixo | remover do versionamento |
| `scripts/ci/__pycache__/phase_f8_release_governance.cpython-314.pyc` | tracked | lixo | remover do versionamento |

## Decisao de Politica
- artifacts versionados: somente baseline estavel.
- artifacts temporarios/gerados: `artifacts/generated/` + ignore.
- checks semanais: fallback automatico para ultimo baseline disponivel.
