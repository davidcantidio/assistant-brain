# Phase 1 Shell Freeze Policy

## Scope
- applies to critical CI and governance checks during Phase 1 reconstruction.

## Rule
- new critical validation logic MUST be implemented in `platform/policy-engine/` modules.
- shell scripts under `scripts/ci/` MUST remain thin wrappers (max 60 lines) that delegate to typed modules.

## Exceptions
- exceptions are allowed only when registered in a tracked allowlist with explicit evidence reference.

## Enforcement
- enforced by governance rules:
  - `GOV-WRAPPER-LIMITS-001`
  - `GOV-WEEKLY-F8-001`
  - `TRADING-EVAL-CONTRACT-001`
