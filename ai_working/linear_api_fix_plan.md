# Linear API Integration Fix Plan

**Date**: 2025-10-26
**Architect**: zen-architect
**Status**: Ready for implementation

## Problem Statement

Code expects `linear-cli` with JSON output:
```python
run_cli_command(["linear-cli", "issue", "get", ticket_id, "--json"])
```

Actual CLI available is `linear` with formatted output only:
```bash
linear issue view <id>  # No "get" command, no --json flag
```

## Solution: Direct GraphQL API

Replace CLI wrapper with direct Linear GraphQL API calls using `requests` library.

### Why This Approach

1. **Ruthless Simplicity**: Direct HTTP calls (~20 lines) vs complex CLI parsing
2. **Proven Pattern**: Official Linear GraphQL API (stable, documented)
3. **Minimal Dependencies**: Only adds `requests` library
4. **Zero Architecture Impact**: Clean module replacement

## Module Specification

### File: `orchestrator/src/orchestrator/linear_client.py`

**Purpose**: Fetch and update Linear issues via GraphQL API

**Contract**:
```python
def fetch_issue(issue_id: str) -> dict:
    """Fetch issue from Linear GraphQL API.

    Args:
        issue_id: Linear issue ID (e.g., "SP-1242")

    Returns:
        {
            "id": str,
            "title": str,
            "description": str,
            "priority": int,  # 0-4
            "state": {"name": str},
            "team": {"key": str},
            # ... other fields as needed
        }

    Raises:
        RuntimeError: If API request fails or issue not found
    """

def update_issue(issue_id: str, priority: int, comment: str) -> None:
    """Update issue priority and add comment.

    Args:
        issue_id: Linear issue ID
        priority: Priority level (0=none, 1=urgent, 2=high, 3=medium, 4=low)
        comment: Markdown comment to add

    Raises:
        RuntimeError: If update fails
    """
```

**Dependencies**:
- `requests` (HTTP client)
- `os` (for `LINEAR_API_KEY` env var)

**Implementation Details**:
- GraphQL endpoint: `https://api.linear.app/graphql`
- Auth header: `Authorization: <LINEAR_API_KEY>`
- Query for fetch: `query { issue(id: "...") { id title description priority state { name } team { key } } }`
- Mutations for update: `issueUpdate(...)` and `commentCreate(...)`
- Clear error messages for API failures

## Implementation Steps

### Step 1: Add Dependency
```bash
cd orchestrator
uv add requests
```

### Step 2: Create linear_client.py
Implement module per specification above with:
- `fetch_issue()` function with GraphQL query
- `update_issue()` function with GraphQL mutations
- Error handling for network/API failures
- Read `LINEAR_API_KEY` from environment

### Step 3: Update triage.py
**Replace lines 42-46** (fetch ticket):
```python
from orchestrator.linear_client import fetch_issue
ticket_data = fetch_issue(ticket_id)
ticket_json = json.dumps(ticket_data)
```

**Replace lines 69-81** (update ticket):
```python
from orchestrator.linear_client import update_issue
priority_level = severity_to_priority(severity.severity)
update_issue(ticket_id, priority_level, comment)
```

**Add helper function**:
```python
def severity_to_priority(severity: str) -> int:
    """Convert severity string to Linear priority level.

    Linear priorities: 0=none, 1=urgent, 2=high, 3=medium, 4=low
    """
    mapping = {
        "P0": 1,  # Urgent
        "P1": 2,  # High
        "P2": 3,  # Medium
        "P3": 4,  # Low
    }
    return mapping.get(severity, 0)
```

### Step 4: Update Documentation

**README.md line 22**:
```diff
-- [linear-cli](https://github.com/schpet/linear-cli) for Linear integration
+- Linear API key (get from https://linear.app/settings/api)
```

**docs/workflows.md lines 18, 83-86**:
```diff
-1. **Fetches ticket** from Linear using `linear-cli`
+1. **Fetches ticket** from Linear using GraphQL API
```

**docs/setup.md** - Add API key configuration section:
```markdown
### Linear API Configuration

1. Get your API key from https://linear.app/settings/api
2. Set environment variable:
   ```bash
   export LINEAR_API_KEY=lin_api_xxx...
   ```
3. Or add to `~/.zshrc` for persistence:
   ```bash
   echo 'export LINEAR_API_KEY=lin_api_xxx...' >> ~/.zshrc
   ```
```

### Step 5: Update Tests

**Create `tests/test_linear_client.py`**:
```python
import pytest
from unittest.mock import patch, MagicMock

def test_fetch_issue_success():
    """Test successful issue fetch"""
    # Mock requests.post to return issue data
    # Verify GraphQL query constructed correctly
    # Verify response parsed correctly

def test_fetch_issue_not_found():
    """Test 404 error handling"""
    # Mock API returning error
    # Verify RuntimeError raised with clear message

def test_update_issue_success():
    """Test successful issue update"""
    # Mock requests.post for both mutations
    # Verify priority update and comment creation

def test_update_issue_api_failure():
    """Test API failure handling"""
    # Mock network/API error
    # Verify RuntimeError raised
```

**Update `tests/test_triage.py`**:
```python
@patch("orchestrator.triage.fetch_issue")
@patch("orchestrator.triage.update_issue")
def test_execute_triage(mock_update, mock_fetch):
    # Update mocks to match new API
    mock_fetch.return_value = {...}
    mock_update.return_value = None
    # Rest of test unchanged
```

### Step 6: Manual Testing

```bash
# Set API key
export LINEAR_API_KEY=lin_api_xxx...

# Test with real ticket
cd orchestrator
uv run orchestrator triage SP-1242

# Verify:
# - Ticket fetched successfully
# - Analysis runs
# - Comment added to Linear
# - Priority updated
```

## Files Changed

### New Files (1)
- `src/orchestrator/linear_client.py` (~100 lines)

### Modified Files (5)
- `src/orchestrator/triage.py` (2 changes + helper function)
- `README.md` (update prerequisite)
- `docs/workflows.md` (update workflow description)
- `docs/setup.md` (add API key configuration)
- `pyproject.toml` (add `requests` dependency)

### Test Files (2)
- `tests/test_linear_client.py` (new, ~80 lines)
- `tests/test_triage.py` (update mocks)

## Verification Checklist

After implementation:

- [ ] `make check` passes (ruff, pyright)
- [ ] `make test` passes (all unit tests)
- [ ] Manual test with real ticket succeeds
- [ ] Documentation updated and accurate
- [ ] No CLI tool dependency references remain

## Rollback Plan

If implementation fails:
1. Revert to previous commit
2. Original CLI-based code still in git history
3. Can restore and investigate further

## Success Criteria

- ✅ Triage workflow completes end-to-end with real ticket
- ✅ All tests pass
- ✅ Documentation matches implementation
- ✅ No `linear` CLI dependency needed
- ✅ Error handling provides clear messages

---

**Effort Estimate**: 3 hours
**Risk Level**: Low (clean module replacement)
**Architecture Impact**: None (module swap only)
**Philosophy Alignment**: Perfect (ruthless simplicity)
