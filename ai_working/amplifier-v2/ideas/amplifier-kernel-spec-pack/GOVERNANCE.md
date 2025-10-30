# GOVERNANCE.md (kernel-scope)

## Versioning
- Kernel ABI and schemas follow **SemVer**. Patch = fixes; Minor = additive; Major = rare, coordinated.

## Compatibility Rules
- Additive fields only; never change meaning.
- Deprecations: mark in docs; keep emitting old fields until the next major.

## Change Process
- Small core owner set. Proposals require: Motivation, Minimal Surface, Alternatives, Migration Notes (for adapters), Test Plan.
