# SECURITY_MODEL.md

## Threat Model (high-level)
- Malicious or buggy modules, untrusted inputs, observer failures.

## Controls
- **Deny-by-default** capability enforcement in kernel.
- **Isolation**: process/container boundary for modules; no in-proc plugins.
- **Resource Guards**: per-invoke timeout; host-enforced CPU/memory where possible.
- **Redaction-before-write**: hooks responsible; kernel writes only redacted data to sinks.
