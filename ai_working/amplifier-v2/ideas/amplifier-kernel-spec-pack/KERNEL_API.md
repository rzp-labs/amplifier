# KERNEL_API.md

## Syscall Surface (Python reference signatures)
```python
class Kernel:
    def session_create(self, plan: dict) -> str: ...
    def session_fork(self, parent_id: str) -> str: ...

    def mount(self, path: str, module_descriptor: dict) -> None: ...
    def unmount(self, path: str, name: str | None = None) -> None: ...

    def emit(self, event: str, data: dict | None = None, /, *,
             session_id: str | None = None,
             request_id: str | None = None,
             span_id: str | None = None) -> None: ...

    def register_hook(self, event: str, endpoint_ref: dict, priority: int = 0) -> None: ...

    def context_get(self) -> dict: ...
    def context_set_fragment(self, key: str, value: object) -> None: ...

    # Module invocation (mechanism only)
    def invoke_module(self, module_descriptor: dict, op: str, args: dict, *, session_id: str) -> dict: ...
```

### Concurrency & determinism
- **Thread-safety**: `session_create`, `mount/unmount`, `emit`, `register_hook`, and `invoke_module` are safe to call from multiple threads; implementations must internally synchronize.
- **Event ordering**: kernel preserves **happens-before** within a syscall; across threads there is no total order.
- **IDs**: kernel mints `session_id`, `request_id` (per syscall), and `span_id` (per module invocation). All emitted events include the applicable IDs.
- **Timeouts**: default 30s per `invoke_module`; on expiry return `error.code = "timeout"` and emit `module:invoke` with `status="error"`.
- **Payload limits**: implementations must accept ≥ 1MB per message; larger handling is module-defined.
- **Errors**: all syscalls fail with structured errors using Error Schema v1.
