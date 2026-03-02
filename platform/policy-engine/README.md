# Policy Engine

Python policy engine to progressively replace monolithic Bash checks in `scripts/ci`.

## Domains
- `security`
- `runtime`
- `governance`
- `trading`
- `all`

## Local run
```bash
PYTHONPATH=platform/policy-engine/src \
python3 platform/policy-engine/src/policy_engine/adapters/ci/run_policy_engine.py --domain all --root .
```

## Validate convergence
```bash
PYTHONPATH=platform/policy-engine/src \
python3 platform/policy-engine/src/policy_engine/adapters/ci/run_policy_engine.py validate --consistency --root .
```

## Tests
```bash
PYTHONPATH=platform/policy-engine/src python3 -m unittest discover -s platform/policy-engine/tests -p 'test_*.py'
```
