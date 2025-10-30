# TESTING_AND_CONFORMANCE.md

## Golden Harness
- Language-agnostic tests validate:
  - `health`, `describe`, `invoke` semantics
  - adherence to Event, Error, Plan schemas
  - capability declaration vs. usage

## Reference Modules
- Minimal orchestrator, provider, and hook demonstrating both transports.

## Reproducibility
- Event logs (JSONL) are canonical; reruns must be comparable by IDs and event sequence.
