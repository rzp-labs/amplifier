# CONFORMANCE_CLI.md

## Purpose
A language-agnostic harness that validates module conformance to **Module Protocol v1** and adherence to schemas.

## Usage
```
amplifier-conformance --descriptor /path/to/module.json --transport http|stdio \
  --case minimal --timeout 30s
```

## Must-pass cases
1. **Health**: returns `{status:"ok"}` within 2s.
2. **Describe**: returns `name, version, kind, capabilities`.
3. **Invoke success**: `{ok:true, result}` for a supported op.
4. **Invoke error**: `{ok:false, error:{code,message}}` for unsupported op.

## Must-fail cases (negative)
1. **Malformed request**: missing `op` → `bad_request`.
2. **Timeout**: harness enforces 30s default → `timeout`.

## Output
- Machine-readable JSON summary with per-test pass/fail and event transcript paths.
