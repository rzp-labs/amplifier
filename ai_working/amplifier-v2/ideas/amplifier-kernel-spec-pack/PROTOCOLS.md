# PROTOCOLS.md (defining spec)

## 1) Module Descriptor (v1)
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "Module Descriptor v1",
  "type": "object",
  "required": ["name", "kind", "transport", "capabilities"],
  "properties": {
    "name": {"type": "string"},
    "kind": {"type": "string", "enum": ["provider", "tool", "agent", "hook", "orchestrator", "context"]},
    "transport": {
      "type": "object",
      "required": ["type"],
      "properties": {
        "type": {"type": "string", "enum": ["stdio", "http"]},
        "command": {"type": "array", "items": {"type": "string"}},
        "url": {"type": "string"}
      }
    },
    "capabilities": {"type": "array", "items": {"type": "string"}},
    "version": {"type": "string"}
  }
}
```

## 2) Module Protocol (v1)
**Required operations** (all transports share the same semantics):
- `health` → `{ "status": "ok" }`
- `describe` → `{ name, version, kind, capabilities, inputs, outputs }`
- `invoke` → input: `{ op: string, args: object, session_id?: string }`
  - success: `{ ok: true, result: any }`
  - failure: `{ ok: false, error: { code: string, message: string, details?: object } }`

**Hook-specific**:
- `on_event` (invoked via `invoke` with `op = "on_event"`) → ack fast; work may be async.

**Transports**:
- **STDIO JSON**: newline-delimited JSON over stdin/stdout.
- **HTTP JSON**: `POST /health`, `POST /describe`, `POST /invoke`.
- Heavier transports (gRPC, MCP) are specified in companion packages.

## 3) Event Schema (v1)
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "Amplifier Event v1",
  "type": "object",
  "required": ["id", "ts", "event", "component"],
  "properties": {
    "id": {"type": "string"},
    "ts": {"type": "number"},
    "event": {"type": "string"},
    "component": {"type": "string"},
    "module": {"type": ["string", "null"]},
    "status": {"type": ["string", "null"]},
    "duration_ms": {"type": ["integer", "null"]},
    "data": {"type": ["object", "null"]},
    "error": {"type": ["object", "null"]},
    "session_id": {"type": ["string", "null"]},
    "request_id": {"type": ["string", "null"]},
    "span_id": {"type": ["string", "null"]}
  }
}
```

**Event Taxonomy** (names are stable):
- `session:start|fork|end`
- `mount:add|remove`
- `hook:register`
- `context:get|set|pre_compact|post_compact`
- `module:invoke` (with `status: ok|error`)
- `policy:decision` (capability approvals/denials)
- `artifact:write|read` (if surfaced via modules)

## 4) Error Schema (v1)
```json
{
  "code": "string",
  "message": "human-readable",
  "details": { "optional": "object" }
}
```
**Reserved codes**: `timeout`, `oom`, `unreachable`, `bad_request`, `forbidden`, `internal`, `unsupported_op`.

## 5) Plan Schema (v1)
```json
{ "goal": "string", "inputs": { "type": "object" } }
```
