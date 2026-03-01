SHELL := /usr/bin/env bash

VENV_DOCLING := .venv-docling
DOCLING_PY := $(VENV_DOCLING)/bin/python
DOCLING_PIP := $(VENV_DOCLING)/bin/pip
PDF ?= felixcraft.pdf
MD ?= felixcraft.md

.PHONY: eval-models eval-integrations eval-runtime eval-rag eval-trading eval-trading-equities_br eval-trading-fii_br \
	eval-trading-fixed_income_br eval-trading-multiasset eval-idempotency eval-risk-gates eval-gates ci-quality ci-security \
	phase-f2-gate phase-f8-contract-review phase-f8-weekly-governance phase-f8-multiasset-contracts \
	phase-f8-multiasset-enablement docling-install pdf-to-md check-pdf-md-sync

eval-models:
	@bash scripts/ci/eval_models.sh

eval-integrations:
	@bash scripts/ci/eval_integrations.sh

eval-runtime:
	@bash scripts/ci/eval_runtime_contracts.sh

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
