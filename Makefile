SHELL := /usr/bin/env bash

.PHONY: eval-models eval-rag eval-trading eval-gates ci-quality ci-security

eval-models:
	@bash scripts/ci/eval_models.sh

eval-rag:
	@bash scripts/ci/eval_rag.sh

eval-trading:
	@bash scripts/ci/eval_trading.sh

eval-gates:
	@bash scripts/ci/eval_gates.sh

ci-quality:
	@bash scripts/ci/check_quality.sh

ci-security:
	@bash scripts/ci/check_security.sh
