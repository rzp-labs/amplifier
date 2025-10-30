# Profile System Fixes

## Date: October 8, 2025

## Issues Found and Fixed

After running `amplifier-dev/scripts/install-dev.sh`, the profile system had several issues that prevented it from working correctly.

---

## Issue 1: Profiles Not Discoverable

### Symptom
```bash
$ amplifier profile apply dev
Error: Profile 'dev' not found

$ amplifier run --profile production "hi!"
Warning: Could not load profile 'production': Profile 'production' not found in search paths: []
```

### Root Cause
The ProfileLoader's `_get_default_search_paths()` only checked for:
- `/usr/share/amplifier/profiles` (doesn't exist in dev environment)
- `.amplifier/profiles` (project-level, doesn't exist yet)
- `~/.amplifier/profiles` (user-level, doesn't exist yet)

The bundled profiles shipped with the package at `/workspaces/amplifier/amplifier-dev/amplifier-cli/profiles/` were not being discovered.

### Fix
**File**: `amplifier-cli/amplifier_cli/profiles/loader.py`

Added bundled profiles directory to search paths:

```python
def _get_default_search_paths(self) -> list[Path]:
    """Get default profile search paths in precedence order (lowest to highest)."""
    paths = []

    # Bundled profiles shipped with the package (lowest precedence)
    bundled = Path(__file__).parent.parent.parent / "profiles"
    if bundled.exists():
        paths.append(bundled)

    # Official profiles (second lowest precedence)
    official = Path("/usr/share/amplifier/profiles")
    if official.exists():
        paths.append(official)

    # ... rest of paths
```

This ensures profiles bundled with the CLI package are always discoverable.

---

## Issue 2: Profile Validation Errors

### Symptom
```bash
$ amplifier profile show dev
Error: Invalid profile file .../dev.toml: 1 validation error for Profile
session.context
  Field required
```

### Root Cause
The `dev.toml` profile extends `base` but didn't include the required `context` field. Pydantic validation failed because it doesn't know about inheritance at validation time.

### Fix
**File**: `amplifier-cli/profiles/dev.toml`

Added required fields even though they're inherited:

```toml
[session]
orchestrator = "loop-streaming"
context = "context-simple"  # Added - required by schema even when extending
```

**Why this is correct**: Profile inheritance is resolved at runtime by the loader, not during schema validation. Each profile file must be independently valid.

---

## Issue 3: Profile Inheritance Not Working

### Symptom
```bash
$ amplifier run --profile production "test"
Error: No providers mounted
```

Even though `production` extends `base` which has `provider-anthropic`.

### Root Cause
The `deep_merge` function in `main.py` was replacing entire lists instead of merging them:

```python
# Broken behavior:
base_config = {providers: [provider-anthropic], tools: [filesystem, bash]}
child_config = {providers: [], tools: [web]}  # Empty providers list!

# deep_merge would do: result[key] = value
# Result: {providers: [], tools: [web]}  # Lost provider-anthropic!
```

### Fix
**File**: `amplifier-cli/amplifier_cli/main.py`

Updated `deep_merge` to intelligently merge module lists:

```python
def deep_merge(base: dict[str, Any], overlay: dict[str, Any]) -> dict[str, Any]:
    """Deep merge two config dicts (overlay takes precedence).

    Special handling for module lists (providers, tools, hooks, agents):
    - Merges lists by module ID instead of replacing
    - Overlay modules override base modules with same ID
    - New modules from overlay are appended
    """
    result = base.copy()

    # Module list keys that need special merging
    module_list_keys = {"providers", "tools", "hooks", "agents"}

    for key, value in overlay.items():
        if key in module_list_keys and key in result:
            # Special handling for module lists
            if isinstance(result[key], list) and isinstance(value, list):
                result[key] = _merge_module_lists(result[key], value)
            else:
                result[key] = value
        elif key in result and isinstance(result[key], dict) and isinstance(value, dict):
            result[key] = deep_merge(result[key], value)
        else:
            result[key] = value

    return result


def _merge_module_lists(
    base_modules: list[dict[str, Any]], overlay_modules: list[dict[str, Any]]
) -> list[dict[str, Any]]:
    """Merge two module lists by module ID.

    Modules with the same 'module' ID are replaced by the overlay version.
    New modules from overlay are appended.
    """
    # Create lookup dictionaries by module ID
    base_by_id = {m.get("module"): m for m in base_modules if isinstance(m, dict) and "module" in m}
    overlay_by_id = {
        m.get("module"): m for m in overlay_modules if isinstance(m, dict) and "module" in m
    }

    # Start with base modules, updating with overlay modules
    merged_by_id = base_by_id.copy()
    merged_by_id.update(overlay_by_id)

    # Preserve order: base modules first (potentially updated), then new overlay modules
    result = []
    seen_ids = set()

    # Add base modules (potentially overridden by overlay)
    for module in base_modules:
        if isinstance(module, dict) and "module" in module:
            module_id = module["module"]
            if module_id not in seen_ids:
                result.append(merged_by_id[module_id])
                seen_ids.add(module_id)

    # Add any new modules from overlay that weren't in base
    for module in overlay_modules:
        if isinstance(module, dict) and "module" in module:
            module_id = module["module"]
            if module_id not in seen_ids:
                result.append(module)
                seen_ids.add(module_id)

    return result
```

---

## Issue 4: Incorrect Module Names

### Symptom
```bash
$ amplifier run --profile production "test"
Failed to load module 'hook-logging': Module 'hook-logging' not found
```

### Root Cause
Profile used wrong module name. The correct name is `hooks-logging` (plural), not `hook-logging`.

### Fix
**Files**:
- `amplifier-cli/profiles/production.toml`
- `amplifier-cli/profiles/dev.toml`

Changed module names to match actual installed modules:

```toml
# production.toml
[[hooks]]
module = "hooks-logging"  # Was: hook-logging

# dev.toml
[[agents]]
module = "agent-architect"  # Was: agent-task (which doesn't exist)
```

---

## Verification Tests

All profile commands now work correctly:

```bash
# List profiles
$ amplifier profile list
Available Profiles:
  • base
  • dev
  • minimal
  • production

# Show profile details
$ amplifier profile show dev
Profile: dev
Version: 1.0.0
Description: Development configuration with full toolset
Extends: base
...

# Apply profile
$ amplifier profile apply dev
✓ Activated profile: dev

# Run with active profile
$ amplifier run "Say hi"
Hello! How are you today?

# Run with profile override
$ amplifier run --profile production "What's 2+2?"
🔍 [LOGGING MODULE] Mounting hooks-logging module...
...
2+2=4

# Reset active profile
$ amplifier profile reset
✓ Cleared active profile
```

---

## Summary of Changes

### Files Modified
1. **amplifier-cli/amplifier_cli/profiles/loader.py**
   - Added bundled profiles directory to search paths

2. **amplifier-cli/amplifier_cli/main.py**
   - Updated `deep_merge()` to handle module list merging
   - Added `_merge_module_lists()` helper function

3. **amplifier-cli/profiles/dev.toml**
   - Added required `context` field
   - Fixed agent module name (agent-architect)

4. **amplifier-cli/profiles/production.toml**
   - Fixed hook module name (hooks-logging)

### Key Insights

1. **Bundled profiles need explicit path resolution** - Can't rely on system-wide install paths during development

2. **Profile validation happens before inheritance resolution** - Each profile must be independently valid, even when extending another

3. **Module list merging is critical for inheritance** - Simple dict merge destroys parent configuration

4. **Module names must match entry points** - `agent-architect` not `agent-task`, `hooks-logging` not `hook-logging`

---

## Testing Checklist

- [x] `amplifier profile list` shows all bundled profiles
- [x] `amplifier profile show <name>` displays profile details
- [x] `amplifier profile apply <name>` activates profile
- [x] `amplifier profile reset` clears active profile
- [x] `amplifier run "prompt"` uses active profile
- [x] `amplifier run --profile <name> "prompt"` overrides active profile
- [x] Profile inheritance works (child inherits parent modules)
- [x] Base profile provides provider
- [x] Dev profile inherits base + adds tools/agents
- [x] Production profile inherits base + adds hooks

All tests pass! ✅

---

## Enhancement: Profile Visibility (October 8, 2025)

### Added Features

After the initial fixes, additional features were added to improve profile visibility:

1. **Active profile indicator in list**
   - `amplifier profile list` now marks the active profile with a star (★)
   - Active profile is highlighted in green with "(active)" label
   - Makes it immediately clear which profile is currently in use

2. **New `profile current` command**
   - `amplifier profile current` shows which profile is active
   - Provides helpful message when no profile is set
   - Quick way to check current configuration without listing all profiles

### Implementation

**File**: `amplifier-cli/amplifier_cli/main.py`

Added ProfileManager to profile_list command:

```python
@profile.command(name="list")
def profile_list():
    """List all available profiles."""
    loader = ProfileLoader()
    manager = ProfileManager()  # Added
    profiles = loader.list_profiles()
    active_profile = manager.get_active_profile()  # Added

    # ...

    for profile_name in profiles:
        # ... get source label ...

        # Mark active profile
        if profile_name == active_profile:
            console.print(f"  ★ [bold green]{profile_name}[/bold green] {source_label} [dim](active)[/dim]")
        else:
            console.print(f"  • {profile_name} {source_label}")
```

Added new profile current command:

```python
@profile.command(name="current")
def profile_current():
    """Show the currently active profile."""
    manager = ProfileManager()
    active_profile = manager.get_active_profile()

    if active_profile:
        console.print(f"[bold green]Active profile:[/bold green] {active_profile}")
    else:
        console.print("[yellow]No active profile set[/yellow]")
        console.print("Using default configuration")
        console.print("\nSet a profile with: [bold]amplifier profile apply <name>[/bold]")
```

### Updated Documentation

**File**: `amplifier-cli/profiles/README.md`

Added documentation for new features:

```markdown
### List Available Profiles
```bash
amplifier profile list
```

The active profile is marked with a star (★) and highlighted in green.

### Check Active Profile
```bash
# Show which profile is currently active
amplifier profile current
```
```

### Example Output

```bash
$ amplifier profile list
Available Profiles:

  • base 
  ★ dev  (active)
  • minimal 
  • production

$ amplifier profile current
Active profile: dev

$ amplifier profile reset
✓ Cleared active profile

$ amplifier profile current
No active profile set
Using default configuration

Set a profile with: amplifier profile apply <name>
```

### Benefits

1. **Immediate visibility** - No need to remember which profile you applied
2. **Clear feedback** - Visual indication of active configuration
3. **Better UX** - Reduces confusion about current state
4. **Quick check** - `profile current` provides fast status without full list

All tests pass! ✅
