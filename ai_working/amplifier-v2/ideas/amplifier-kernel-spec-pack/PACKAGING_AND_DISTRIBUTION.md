# PACKAGING_AND_DISTRIBUTION.md

## Core
- `amplifier-core` (Python library) with minimal dependencies, shipping:
  - syscall surface, event bus, capability gate, transport clients (stdio/http), schemas, IDs & error taxonomy, conformance harness.

## Out-of-Tree Packages (Reference Only)
- `amplifier-cli`, `amplifier-service`, `amplifier-observers-*`, `amplifier-transport-*`, `amplifier-orchestrators-*`, `amplifier-sdk-{lang}`.

## Examples
- End-to-end demos live in `/examples` and are not part of the kernel surface.
