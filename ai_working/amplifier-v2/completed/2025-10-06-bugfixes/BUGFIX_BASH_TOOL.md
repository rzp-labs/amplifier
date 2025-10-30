# Bash Tool Fix - Command Rejection Issue

## Problem

Bash commands were consistently rejected in interactive chat mode with the error:
```
{'message': 'Command rejected by user'}
```

Even simple, safe commands like `echo` and `pwd` were being rejected.

## Root Causes

### Issue 1: Missing auto_approve Configuration

The bash tool (`amplifier-mod-tool-bash`) has an approval mechanism in `_get_user_approval()` that:
1. Checks for `auto_approve` flag in config
2. Checks for `development_mode` flag in config
3. Returns `False` by default if neither is set

The `test-full-features.toml` config had:
```toml
[tools.bash]
require_approval = true
# But no auto_approve or development_mode!
```

This caused all commands to be rejected by default.

### Issue 2: CLI Not Passing Tool Configurations

The CLI's `transform_toml_to_session_config()` function was transforming tool names:
```python
session_config["tools"] = [{"module": f"tool-{tool}"} for tool in tools]
```

But it wasn't including the tool-specific configurations from `[tools.bash]`, `[tools.web]`, etc.

So even with `auto_approve = true` in the config, it wasn't being passed to the tool!

## Solution

### Fix 1: Add auto_approve to Config

Added `auto_approve = true` to the bash tool configuration:

```toml
[tools.bash]
require_approval = true
auto_approve = true  # Auto-approve for testing/development
```

### Fix 2: Update CLI Config Transformation

Updated `amplifier-cli/amplifier_cli/main.py` to include tool-specific configs:

```python
# Transform tools list
if "tools" in toml_config["modules"]:
    tools = toml_config["modules"]["tools"]
    if isinstance(tools, list):
        tool_configs = []
        for tool in tools:
            tool_module = {"module": f"tool-{tool}"}
            # Check for tool-specific config in [tools.X] sections
            if "tools" in toml_config and tool in toml_config["tools"]:
                tool_module["config"] = toml_config["tools"][tool]
            tool_configs.append(tool_module)
        session_config["tools"] = tool_configs
```

## Verification

### Programmatic Test

Created `/tmp/test_bash_tool.py` to test bash tool directly:
- ✅ All 4 test commands passed (echo, pwd, ls, date)
- ✅ Commands auto-approved with `auto_approve = true`

### Interactive Test

Tested in interactive CLI mode:
- ✅ `echo "Testing bash tool"` - succeeded
- ✅ `pwd` - succeeded
- ✅ Commands logged correctly with hooks
- ✅ No rejection errors

## Files Modified

1. `test-full-features.toml` - Added `auto_approve = true` to bash config
2. `amplifier-cli/amplifier_cli/main.py` - Updated config transformation to include tool configs

## Prevention

- Document that tool-specific configs in `[tools.X]` sections must be passed through by CLI
- Consider adding validation to warn if tool configs are defined but not being used
- Add integration tests that verify tool configs are passed correctly
