# KERNEL_PHILOSOPHY.md (greenfield)

## First Principles

- **Mechanism in the kernel, policy at the edges.**
- **Text-first, inspectable, curlable.** Wire formats are JSON; logs are JSONL.
- **Small center, rich periphery.** The kernel is boring and slow to change; modules and adapters move fast.
- **Everything is an event.** If it didn’t emit, it didn’t happen.
- **Freedom with accountability.** Any language and runtime, provided contracts are honored.

## Design Tenets

1. **Stability Over Features**: core focuses on composability and determinism rather than feature breadth.
2. **Additive Evolution**: never repurpose fields or change meanings; add new ones.
3. **Fault Containment**: module failures don’t cascade; core continues emitting.
4. **Capability Minimalism**: least privilege requested, least privilege granted.
5. **No Defaults**: kernel requires explicit descriptors and explicit mounts.
6. **Testability First**: conformance harness is part of the release; examples are runnable end-to-end.

## Heuristics

- If removing a piece still leaves a kernel that can **mount modules and dispatch events**, the piece is candidates for inclusion. Otherwise, it belongs in user space.
- Extract interfaces only after there are ≥2 credible implementations.

## What the Kernel Owns

- ABI (syscalls)
- Wire-level schemas and IDs
- Event taxonomy and emission mechanics
- Capability enforcement
- Transport clients (lightweight)

## What the Kernel Rejects

- UX (CLI/web), persistence, authn/z, routing, ranking, planning, redaction/export, caching, retries, rate limiting, autoscaling, storage abstractions.
