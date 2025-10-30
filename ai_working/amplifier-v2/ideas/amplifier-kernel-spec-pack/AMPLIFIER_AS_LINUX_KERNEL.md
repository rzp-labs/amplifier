# AMPLIFIER_AS_LINUX_KERNEL.md (greenfield)

## Premise

Amplifier is a **small, stable kernel** that provides mechanism only: session lifecycle, module mounting, event emission, capability enforcement, and transport clients for module invocation. **Policy, UX, and products live outside the kernel** as modules and adapters.

## Goals

- **Polyglot & cross-OS**: any module can be implemented in any language and run as a process, container, or remote service.
- **Stable contracts**: additive evolution of a minimal syscall surface and wire-level protocols.
- **Deterministic behavior**: explicit outcomes, text-first errors, reproducible runs via canonical event logs.
- **Observability by design**: events are the source of truth; observers are replaceable.
- **Security by default**: deny-by-default capabilities; isolation and resource limits per module call.

## Non-Goals

- No UI/CLI/web UX in kernel.
- No provider selection, routing, or agent policy.
- No persistence, authn/z, rate limiting, retries, or caching in kernel.
- No automatic module discovery; descriptors are explicit.

## Kernel Responsibilities

1. **Syscall Surface (ABI)**

   - `session.create(plan)` → `session_id`
   - `session.fork(parent_id)` → `session_id`
   - `mount(path, module_descriptor)` / `unmount(path, name?)`
   - `emit(event, data)` (fire-and-forget)
   - `register_hook(event, endpoint_ref, priority)`
   - `context.get()` / `context.set_fragment(key, value)`

2. **Event Bus**

   - Emits canonical events (see Event Taxonomy) to subscribers and a JSONL sink.
   - Non-blocking fan-out; observer failures never break the run.

3. **Capability Gate**

   - Enforces deny-by-default capability checks on module invocations based on declared needs in module descriptors and an approval decision supplied by policy hooks.

4. **Transport Clients**

   - Built-in clients for **STDIO JSON** and **HTTP JSON** to invoke modules uniformly.
   - Additional transports (gRPC, MCP) are optional packages.

5. **Resource Guards**

   - Enforces per-invoke timeouts and soft resource budgets (CPU/memory) when supported by the host.

6. **IDs and Error Taxonomy**

   - Mints `session_id`, `request_id`, `span_id` and standardizes error shapes.

## Mounting Model

- Logical paths: `/mnt/providers`, `/mnt/tools`, `/mnt/agents`, `/mnt/hooks`, `/mnt/orchestrators`, `/mnt/context`.
- Multiple modules may mount at the same path; orchestrators decide which to use.

## Data Contracts (summary; see PROTOCOLS.md)

- **Module Descriptor**: name, kind, transport, capabilities, version.
- **Module Protocol**: `health`, `describe`, `invoke` triad; hooks additionally `on_event`.
- **Event Schema v1**: stable envelope for all lifecycle and audit events.
- **Error Schema v1**: canonical `code`, `message`, `details`.
- **Plan Schema v1**: minimal `goal`, `inputs`.

## Security Model

- Kernel is a library with **no ambient I/O** duties beyond event writing.
- Capability enforcement at the boundary; approvals are user-space policy via hooks.
- Prefer process/container isolation for modules; minimal privileges.

## Versioning & Evolution

- Semantic versioning for the syscall/driver surface and schemas.
- Additive changes favored; deprecations are scheduled and explicit.
