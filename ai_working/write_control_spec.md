# Write Control and File Output Specification

**Date**: 2025-10-26
**Architect**: zen-architect
**Status**: Ready for implementation
**Updated**: 2025-10-26 (added file output)

## Problem Statement

The orchestrator triage workflow has two related concerns:

1. **Write control**: Automatic Linear updates without user consent
2. **Result persistence**: Expensive LLM analysis lost if terminal closes

Users need the ability to:

1. Run analysis without modifying Linear (read-only mode)
2. Preserve analysis results durably (don't lose expensive LLM calls)
3. Enable writes when ready (write mode)
4. Clearly understand which mode is active
5. Switch modes via configuration without code changes

## Solution Design

### Core Philosophy

**Mental model** (like git):
```
Analysis → File (always - durable storage, local commit)
File → Linear (if writes enabled - optional push to remote)
```

**Benefits**:
- ✅ Analysis never lost (file persists)
- ✅ Can review before posting to Linear
- ✅ Single source of truth (file is the record)
- ✅ Progressive enhancement (file first, Linear optional)
- ✅ No re-work (never re-run expensive analysis)

### Configuration Approach

**Environment Variable**: `LINEAR_ENABLE_WRITES=true|false`
- **Default**: `false` (read-only mode - safe default)
- **Location**: Environment variable (can be set in `.envrc`, `.zshrc`, or inline)
- **Values**: `true`, `1`, `yes` enable writes; anything else is read-only

### File Output

**Always saves analysis to file** (both modes):

**Location**: `./triage_results/` in current directory
- Simple, discoverable
- Auto-created if doesn't exist
- Easy to .gitignore if desired

**Naming**: `{ticket_id}.md` (overwrites previous)
- Simple mental model: one file per ticket, always latest
- No timestamp clutter
- Want history? Use git to track changes

**Content**: Formatted AI comment + metadata
- Same markdown that would be posted to Linear
- Human-readable, ready to copy-paste if needed
- Includes timestamp and write mode for reference

### Architecture

**Four-module approach**:

1. **Config Module** (`src/orchestrator/config.py`) - NEW
   - Centralized configuration management
   - Reads and interprets `LINEAR_ENABLE_WRITES` env var
   - Provides type-safe config accessors

2. **File Writer** (`src/orchestrator/file_writer.py`) - NEW
   - Saves analysis results to `./triage_results/{ticket_id}.md`
   - Creates directory if needed
   - Handles file write errors gracefully

3. **Linear Client** (`src/orchestrator/linear_client.py`) - MODIFIED
   - `update_issue()` checks config before writing
   - Returns `None` if writes disabled
   - Logs operation in both modes

4. **Triage Workflow** (`src/orchestrator/triage.py`) - MODIFIED
   - Shows mode at start
   - Saves analysis to file (always)
   - Updates Linear if writes enabled
   - Clear messaging about what happened

## Module Specifications

### 1. Config Module (NEW)

**File**: `src/orchestrator/config.py`

**Purpose**: Centralized configuration management for orchestrator

**Contract**:
```python
def get_linear_writes_enabled() -> bool:
    """Check if Linear write operations are enabled.

    Reads LINEAR_ENABLE_WRITES environment variable.
    Values 'true', '1', 'yes' (case-insensitive) enable writes.
    All other values (including unset) disable writes.

    Returns:
        bool: True if writes enabled, False otherwise (default)
    """

def get_write_mode_display() -> str:
    """Get human-readable write mode for display.

    Returns:
        str: "READ-ONLY" or "WRITE"
    """
```

**Implementation**:
```python
import os

def get_linear_writes_enabled() -> bool:
    """Check if Linear write operations are enabled."""
    value = os.getenv("LINEAR_ENABLE_WRITES", "false").lower()
    return value in ("true", "1", "yes")

def get_write_mode_display() -> str:
    """Get human-readable write mode for display."""
    return "WRITE" if get_linear_writes_enabled() else "READ-ONLY"
```

### 2. File Writer Module (NEW)

**File**: `src/orchestrator/file_writer.py`

**Purpose**: Save triage analysis results to markdown files

**Contract**:
```python
from pathlib import Path
from datetime import datetime

def save_analysis(
    ticket_id: str,
    comment: str,
    writes_enabled: bool,
    output_dir: Path = Path("./triage_results")
) -> Path:
    """Save triage analysis to markdown file.

    Args:
        ticket_id: Linear ticket ID (e.g., "SP-1242")
        comment: Formatted AI analysis comment (markdown)
        writes_enabled: Whether Linear writes are enabled
        output_dir: Directory to save results (default: ./triage_results)

    Returns:
        Path: Path to saved file

    Raises:
        OSError: If directory can't be created or file can't be written
    """
```

**Implementation**:
```python
from pathlib import Path
from datetime import datetime, timezone
import logging

logger = logging.getLogger(__name__)

def save_analysis(
    ticket_id: str,
    comment: str,
    writes_enabled: bool,
    output_dir: Path = Path("./triage_results")
) -> Path:
    """Save triage analysis to markdown file."""
    # Create directory if needed
    output_dir.mkdir(parents=True, exist_ok=True)

    # Generate file path
    file_path = output_dir / f"{ticket_id}.md"

    # Add metadata footer
    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    mode = "enabled" if writes_enabled else "disabled"

    content = f"""{comment}

---
_Analysis generated: {timestamp}_
_Linear writes: {mode}_
"""

    # Write file
    file_path.write_text(content, encoding="utf-8")
    logger.info(f"Saved analysis to {file_path}")

    return file_path
```

### 3. Linear Client Changes

**File**: `src/orchestrator/linear_client.py`

**Function Modified**: `update_issue()`

**Changes**:
```python
from orchestrator.config import get_linear_writes_enabled

def update_issue(issue_id: str, priority: int, comment: str) -> None:
    """Update issue priority and add comment.

    If LINEAR_ENABLE_WRITES is disabled, logs what would have been
    written but does not make API calls.

    Args:
        issue_id: Linear issue ID
        priority: Priority level (0=none, 1=urgent, 2=high, 3=medium, 4=low)
        comment: Markdown comment to add

    Raises:
        RuntimeError: If update fails (only when writes enabled)
    """
    if not get_linear_writes_enabled():
        logger.info(
            f"[READ-ONLY] Skipping Linear update for {issue_id} "
            f"(priority={priority}, comment={len(comment)} chars)"
        )
        return

    # Existing implementation continues here...
    logger.info(f"Updating issue {issue_id} priority to {priority}")
    # ... GraphQL mutations ...
```

### 4. Triage Workflow Changes

**File**: `src/orchestrator/triage.py`

**Function Modified**: `execute_triage()`

**Changes**:

**Import additions**:
```python
from orchestrator.config import get_linear_writes_enabled, get_write_mode_display
from orchestrator.file_writer import save_analysis
```

**At start of analysis** (after fetching ticket, line ~65):
```python
# Show write mode
mode_display = get_write_mode_display()
writes_enabled = get_linear_writes_enabled()
action_future = "WILL" if writes_enabled else "will NOT"
logger.info(f"Mode: {mode_display} - Comments {action_future} be added to Linear")
logger.info(f"Beginning analysis for Linear issue {ticket_id}...")
```

**After formatting comment, before update_issue** (line ~87):
```python
# Save analysis to file (always)
file_path = save_analysis(
    ticket_id=ticket_id,
    comment=comment,
    writes_enabled=writes_enabled
)
logger.info(f"✓ Saved to: {file_path}")
```

**At end of analysis** (after update_issue call, line ~93):
```python
# Confirm what happened with Linear
if writes_enabled:
    logger.info(f"✓ Posted comment to Linear issue {ticket_id}")
else:
    logger.info(f"ℹ Linear writes disabled (LINEAR_ENABLE_WRITES=false)")
```

## Output Examples

### Read-Only Mode (Default)

```
Mode: READ-ONLY - Comments will NOT be added to Linear
Beginning analysis for Linear issue SP-1242...

Fetching ticket SP-1242...
✓ Ticket fetched: https://linear.app/issue/SP-1242

Analyzing validity...
✓ Validity analysis complete
  - Valid: True
  - Actionable: False
  - Missing context: [...]

Assessing severity...
✓ Severity assessment complete
  - Priority: P2
  - Complexity: medium
  - Required expertise: [...]

Saved analysis to ./triage_results/SP-1242.md
✓ Saved to: ./triage_results/SP-1242.md

✓ Triage complete for SP-1242 (28.9s total)
ℹ Linear writes disabled (LINEAR_ENABLE_WRITES=false)
```

### Write-Enabled Mode

```
Mode: WRITE - Comments WILL be added to Linear
Beginning analysis for Linear issue SP-1242...

Fetching ticket SP-1242...
✓ Ticket fetched: https://linear.app/issue/SP-1242

Analyzing validity...
✓ Validity analysis complete
  - Valid: True
  - Actionable: False
  - Missing context: [...]

Assessing severity...
✓ Severity assessment complete
  - Priority: P2
  - Complexity: medium
  - Required expertise: [...]

Saved analysis to ./triage_results/SP-1242.md
✓ Saved to: ./triage_results/SP-1242.md

Updating issue SP-1242 priority to 3
Adding comment to issue SP-1242
Successfully updated issue SP-1242

✓ Triage complete for SP-1242 (28.9s total)
✓ Posted comment to Linear issue SP-1242
```

## Testing Strategy

### Test Fixtures

**File**: `tests/conftest.py` (add to existing fixtures)

```python
import pytest
import os

@pytest.fixture
def enable_linear_writes():
    """Temporarily enable Linear writes for testing."""
    old_value = os.getenv("LINEAR_ENABLE_WRITES")
    os.environ["LINEAR_ENABLE_WRITES"] = "true"
    yield
    if old_value is None:
        os.environ.pop("LINEAR_ENABLE_WRITES", None)
    else:
        os.environ["LINEAR_ENABLE_WRITES"] = old_value

@pytest.fixture
def disable_linear_writes():
    """Ensure Linear writes are disabled for testing."""
    old_value = os.getenv("LINEAR_ENABLE_WRITES")
    os.environ["LINEAR_ENABLE_WRITES"] = "false"
    yield
    if old_value is None:
        os.environ.pop("LINEAR_ENABLE_WRITES", None)
    else:
        os.environ["LINEAR_ENABLE_WRITES"] = old_value
```

### New Tests

**File**: `tests/test_config.py` (NEW)

```python
"""Tests for configuration module."""

import os
import pytest

from orchestrator.config import get_linear_writes_enabled, get_write_mode_display


class TestLinearWritesConfig:
    """Test LINEAR_ENABLE_WRITES configuration."""

    def test_writes_disabled_by_default(self):
        """Writes should be disabled when env var not set."""
        if "LINEAR_ENABLE_WRITES" in os.environ:
            del os.environ["LINEAR_ENABLE_WRITES"]
        assert get_linear_writes_enabled() is False
        assert get_write_mode_display() == "READ-ONLY"

    def test_writes_enabled_with_true(self):
        """Writes enabled when LINEAR_ENABLE_WRITES=true."""
        os.environ["LINEAR_ENABLE_WRITES"] = "true"
        assert get_linear_writes_enabled() is True
        assert get_write_mode_display() == "WRITE"

    def test_writes_enabled_with_1(self):
        """Writes enabled when LINEAR_ENABLE_WRITES=1."""
        os.environ["LINEAR_ENABLE_WRITES"] = "1"
        assert get_linear_writes_enabled() is True

    def test_writes_enabled_with_yes(self):
        """Writes enabled when LINEAR_ENABLE_WRITES=yes."""
        os.environ["LINEAR_ENABLE_WRITES"] = "yes"
        assert get_linear_writes_enabled() is True

    def test_writes_disabled_with_false(self):
        """Writes disabled when LINEAR_ENABLE_WRITES=false."""
        os.environ["LINEAR_ENABLE_WRITES"] = "false"
        assert get_linear_writes_enabled() is False

    def test_writes_disabled_with_invalid_value(self):
        """Writes disabled with invalid env var value."""
        os.environ["LINEAR_ENABLE_WRITES"] = "maybe"
        assert get_linear_writes_enabled() is False

    def test_case_insensitive(self):
        """Env var check is case-insensitive."""
        os.environ["LINEAR_ENABLE_WRITES"] = "TRUE"
        assert get_linear_writes_enabled() is True
```

**File**: `tests/test_file_writer.py` (NEW)

```python
"""Tests for file writer module."""

from pathlib import Path
import pytest
from orchestrator.file_writer import save_analysis


class TestSaveAnalysis:
    """Test save_analysis() function."""

    def test_creates_directory(self, tmp_path):
        """Creates output directory if it doesn't exist."""
        output_dir = tmp_path / "results"
        assert not output_dir.exists()

        save_analysis(
            ticket_id="SP-123",
            comment="Test analysis",
            writes_enabled=False,
            output_dir=output_dir
        )

        assert output_dir.exists()
        assert output_dir.is_dir()

    def test_saves_file_with_correct_name(self, tmp_path):
        """Saves file with ticket ID as name."""
        file_path = save_analysis(
            ticket_id="SP-456",
            comment="Test",
            writes_enabled=False,
            output_dir=tmp_path
        )

        assert file_path.name == "SP-456.md"
        assert file_path.exists()

    def test_includes_comment_in_file(self, tmp_path):
        """File contains the analysis comment."""
        comment = "## Test Analysis\nThis is a test."
        file_path = save_analysis(
            ticket_id="SP-789",
            comment=comment,
            writes_enabled=False,
            output_dir=tmp_path
        )

        content = file_path.read_text()
        assert "## Test Analysis" in content
        assert "This is a test." in content

    def test_includes_metadata_footer(self, tmp_path):
        """File includes metadata footer with timestamp and mode."""
        file_path = save_analysis(
            ticket_id="SP-999",
            comment="Test",
            writes_enabled=True,
            output_dir=tmp_path
        )

        content = file_path.read_text()
        assert "---" in content
        assert "_Analysis generated:" in content
        assert "UTC_" in content
        assert "_Linear writes: enabled_" in content

    def test_overwrites_existing_file(self, tmp_path):
        """Overwrites existing file for same ticket ID."""
        # First save
        save_analysis(
            ticket_id="SP-111",
            comment="First version",
            writes_enabled=False,
            output_dir=tmp_path
        )

        # Second save
        file_path = save_analysis(
            ticket_id="SP-111",
            comment="Second version",
            writes_enabled=False,
            output_dir=tmp_path
        )

        content = file_path.read_text()
        assert "Second version" in content
        assert "First version" not in content
```

### Modified Tests

**File**: `tests/test_linear_client.py`

Add tests for write control behavior:

```python
def test_update_issue_respects_write_control(disable_linear_writes):
    """update_issue skips API call when writes disabled."""
    # Mock would fail if called, proving it's not called
    with patch("orchestrator.linear_client._make_graphql_request") as mock_request:
        update_issue("SP-123", priority=2, comment="test")
        mock_request.assert_not_called()

def test_update_issue_makes_call_when_enabled(enable_linear_writes):
    """update_issue calls API when writes enabled."""
    with patch("orchestrator.linear_client._make_graphql_request") as mock_request:
        mock_request.return_value = {
            "issueUpdate": {"success": True},
            "commentCreate": {"success": True}
        }
        update_issue("SP-123", priority=2, comment="test")
        assert mock_request.call_count == 2  # priority + comment
```

**File**: `tests/test_triage.py`

Existing tests should continue to work with mocks. The `update_issue` mock prevents actual writes regardless of config.

## Documentation Updates

### README.md

Add section after "Quick Start":

```markdown
## Write Control

By default, orchestrator runs in **read-only mode** - it analyzes tickets but does NOT update Linear.

### Read-Only Mode (Default)

```bash
uv run orchestrator triage SP-1242
# Analyzes ticket, shows results, does not write to Linear
```

### Write-Enabled Mode

To enable Linear updates:

```bash
# One-time
LINEAR_ENABLE_WRITES=true uv run orchestrator triage SP-1242

# Permanent (add to ~/.zshrc or ~/.bashrc)
export LINEAR_ENABLE_WRITES=true
```

Or use direnv with `.envrc`:
```bash
export LINEAR_ENABLE_WRITES=true
```

The tool clearly indicates which mode is active at the start and end of each triage.
```

### docs/setup.md

Add after Linear API Configuration section:

```markdown
### Write Control Configuration

Control whether orchestrator can update Linear tickets:

**Read-only mode (default)**:
```bash
# Don't set LINEAR_ENABLE_WRITES, or set to false
export LINEAR_ENABLE_WRITES=false
```

**Write-enabled mode**:
```bash
export LINEAR_ENABLE_WRITES=true
```

The mode is shown clearly in the output:
- Start: "Mode: READ-ONLY - Comments will NOT be added to Linear"
- End: "Mode: READ-ONLY - Comments were NOT added to Linear issue SP-1242"
```

## Files Changed

### New Files (4)
- `src/orchestrator/config.py` (~20 lines) - Configuration management
- `src/orchestrator/file_writer.py` (~30 lines) - File output for analysis results
- `tests/test_config.py` (~60 lines) - Config tests
- `tests/test_file_writer.py` (~70 lines) - File writer tests

### Modified Files (4)
- `src/orchestrator/linear_client.py` (add config check in update_issue)
- `src/orchestrator/triage.py` (add mode display + file saving)
- `tests/test_linear_client.py` (add write control tests)
- `tests/conftest.py` (add fixtures)

### Documentation Files (2)
- `README.md` (add Write Control + File Output section)
- `docs/setup.md` (add Write Control Configuration)

### Additional Files
- `.gitignore` (add `triage_results/` - optional, user choice)

## Success Criteria

- ✅ Default to read-only (safe for new users)
- ✅ Single environment variable to enable writes
- ✅ Analysis always saved to file (never lost)
- ✅ Clear mode indication at start and end
- ✅ No code changes needed to switch modes
- ✅ Tests pass in both modes
- ✅ Analysis runs identically in both modes
- ✅ File output works in both modes
- ✅ Only Linear writes are controlled by config
- ✅ User messaging is confident and clear

## Philosophy Alignment

✅ **Ruthless simplicity**: File always saved, Linear optional
✅ **Safe defaults**: Read-only prevents accidental writes
✅ **Single source of truth**: File is the durable record
✅ **Progressive enhancement**: File first (local commit), Linear second (remote push)
✅ **Clear feedback**: User always knows what's happening
✅ **No waste**: Analysis never lost, never re-run unnecessarily
✅ **Testable**: Both modes can be tested
✅ **User control**: Tool doesn't act without permission

## Implementation Notes

- File output happens in both modes (analysis is always durable)
- Config check happens in `update_issue()` - single control point for Linear writes
- Triage workflow shows mode and file path
- File saved to `./triage_results/{ticket_id}.md` - simple, predictable
- No timestamp in filename - use git for history
- Logging in both modes provides full visibility
- Tests use fixtures to control mode explicitly
- Tests use `tmp_path` for file operations
- No architectural changes - additive only

---

**Effort Estimate**: 2 hours
**Risk Level**: Low (additive change, no architecture impact)
**Testing**: Comprehensive (new tests + existing tests still pass)
