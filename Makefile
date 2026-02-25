SHELL := /usr/bin/env bash

VENV_DOCLING := .venv-docling
DOCLING_PY := $(VENV_DOCLING)/bin/python
DOCLING_PIP := $(VENV_DOCLING)/bin/pip
PDF ?= felixcraft.pdf
MD ?= felixcraft.md

.PHONY: eval-models eval-integrations eval-runtime eval-rag eval-trading eval-idempotency eval-gates ci-quality ci-security \
	phase-f2-gate docling-install pdf-to-md check-pdf-md-sync

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

eval-idempotency:
	@bash scripts/ci/eval_idempotency_reconciliation.sh

eval-gates:
	@bash scripts/ci/eval_gates.sh

ci-quality:
	@bash scripts/ci/check_quality.sh

ci-security:
	@bash scripts/ci/check_security.sh

phase-f2-gate:
	@bash scripts/ci/check_phase_f2_gate.sh

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
