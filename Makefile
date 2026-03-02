SHELL := /usr/bin/env bash

VENV_DOCLING := .venv-docling
DOCLING_PY := $(VENV_DOCLING)/bin/python
DOCLING_PIP := $(VENV_DOCLING)/bin/pip
PDF ?= felixcraft.pdf
MD ?= felixcraft.md

.PHONY: eval-models eval-integrations eval-runtime eval-rag eval-trading eval-trading-equities_br eval-trading-fii_br \
	eval-trading-fixed_income_br eval-trading-multiasset eval-idempotency eval-risk-gates eval-gates eval-runtime-control-plane ci-quality ci-security \
	phase-f2-gate phase-f8-contract-review phase-f8-weekly-governance phase-f8-multiasset-contracts \
	phase-f8-multiasset-enablement phase-f9-litellm-keygen phase-f10-runtime-convergence architecture-consistency-backlog-check pm-audit-paths-check repo-hygiene-check \
	policy-convergence-check governance-kpis-check docling-install pdf-to-md check-pdf-md-sync policy-lint policy-typecheck policy-test policy-test-unit \
	policy-test-integration policy-test-contract e2e-test chaos-test phase1-critical-suite

eval-models:
	@bash scripts/ci/eval_models.sh

eval-integrations:
	@bash scripts/ci/eval_integrations.sh

eval-runtime:
	@bash scripts/ci/eval_runtime_contracts.sh

eval-runtime-control-plane:
	@bash scripts/ci/eval_runtime_control_plane.sh

eval-rag:
	@bash scripts/ci/eval_rag.sh

eval-trading:
	@bash scripts/ci/eval_trading.sh

eval-trading-equities_br:
	@ASSET_CLASS=equities_br bash scripts/ci/eval_trading_asset_class.sh

eval-trading-fii_br:
	@ASSET_CLASS=fii_br bash scripts/ci/eval_trading_asset_class.sh

eval-trading-fixed_income_br:
	@ASSET_CLASS=fixed_income_br bash scripts/ci/eval_trading_asset_class.sh

eval-trading-multiasset:
	@$(MAKE) eval-trading-equities_br
	@$(MAKE) eval-trading-fii_br
	@$(MAKE) eval-trading-fixed_income_br

eval-idempotency:
	@bash scripts/ci/eval_idempotency_reconciliation.sh

eval-risk-gates:
	@bash scripts/ci/eval_risk_gates.sh

eval-gates:
	@bash scripts/ci/eval_gates.sh

ci-quality:
	@bash scripts/ci/check_quality.sh

ci-security:
	@bash scripts/ci/check_security.sh

phase-f2-gate:
	@bash scripts/ci/check_phase_f2_gate.sh

phase-f8-contract-review:
	@bash scripts/ci/check_phase_f8_contract_review.sh

phase-f8-weekly-governance:
	@bash scripts/ci/run_phase_f8_weekly_governance.sh

phase-f8-multiasset-contracts:
	@bash scripts/ci/check_phase_f8_multiasset_contracts.sh

phase-f8-multiasset-enablement:
	@bash scripts/ci/run_phase_f8_multiasset_enablement.sh

phase-f9-litellm-keygen:
	@bash scripts/ci/check_phase_f9_litellm_keygen.sh

phase-f10-runtime-convergence:
	@bash scripts/ci/check_phase_f10_runtime_convergence.sh

architecture-consistency-backlog-check:
	@bash scripts/ci/check_architecture_consistency_backlog.sh

pm-audit-paths-check:
	@bash scripts/ci/check_pm_audit_paths.sh

repo-hygiene-check:
	@bash scripts/ci/check_repo_hygiene.sh

policy-convergence-check:
	@bash scripts/ci/check_policy_convergence.sh

governance-kpis-check:
	@bash scripts/ci/check_governance_kpis.sh

docling-install:
	@if [[ ! -f requirements-docling.txt ]]; then \
		echo "ERRO: requirements-docling.txt nao encontrado na raiz."; \
		exit 2; \
	fi
	@python3 -m venv "$(VENV_DOCLING)"
	@"$(DOCLING_PY)" -m pip install -U pip wheel setuptools
	@"$(DOCLING_PIP)" install -r requirements-docling.txt

pdf-to-md:
	@if [[ ! -x "$(DOCLING_PY)" ]]; then \
		echo "ERRO: ambiente Docling nao encontrado em $(VENV_DOCLING). Rode: make docling-install"; \
		exit 2; \
	fi
	@"$(DOCLING_PY)" scripts/pdf_to_md_docling.py --input "$(PDF)" --output "$(MD)"

check-pdf-md-sync:
	@if [[ ! -f scripts/ci/check_pdf_md_sync.sh ]]; then \
		echo "ERRO: scripts/ci/check_pdf_md_sync.sh nao encontrado."; \
		echo "Crie o script para habilitar o check local de sincronizacao PDF->MD."; \
		exit 2; \
	fi
	@bash scripts/ci/check_pdf_md_sync.sh

policy-lint:
	@ruff check platform/policy-engine/src platform/policy-engine/tests
	@black --check platform/policy-engine/src platform/policy-engine/tests

policy-typecheck:
	@mypy --config-file platform/policy-engine/pyproject.toml platform/policy-engine/src

policy-test:
	@$(MAKE) policy-test-unit
	@$(MAKE) policy-test-integration
	@$(MAKE) policy-test-contract

policy-test-unit:
	@PYTHONPATH=platform/policy-engine/src:. python3 -m unittest discover -s platform/policy-engine/tests/unit -p 'test_*.py'

policy-test-integration:
	@PYTHONPATH=platform/policy-engine/src:. python3 -m unittest discover -s platform/policy-engine/tests -p 'test_*.py'

policy-test-contract:
	@PYTHONPATH=platform/policy-engine/src:. python3 -m unittest discover -s platform/policy-engine/tests/contract -p 'test_*.py'

e2e-test:
	@PYTHONPATH=apps/control-plane/src:apps/ops-api/src:platform/policy-engine/src:platform/event-ledger/src:. python3 -m unittest discover -s tests/e2e -p 'test_*.py'

chaos-test:
	@PYTHONPATH=apps/control-plane/src:apps/ops-api/src:platform/policy-engine/src:platform/event-ledger/src:. python3 -m unittest discover -s tests/chaos -p 'test_*.py'

phase1-critical-suite:
	@$(MAKE) policy-test
	@$(MAKE) e2e-test
	@$(MAKE) chaos-test
