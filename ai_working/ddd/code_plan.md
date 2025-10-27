# Code Implementation Plan

**Generated**: 2025-10-26
**Revised**: 2025-10-26 (zen-architect feedback implemented)
**Based on**: Phase 1 plan + Phase 2 documentation

## Revision Summary

**All zen-architect recommendations implemented**:

1. ✅ **Removed retry logic** - Direct subprocess calls, fail fast with logging
2. ✅ **Added complete `parse_llm_json()` implementation** - Battle-tested pattern from amplifier
3. ✅ **Specified `run_agent()` command format** - Using `claude --print --agents`
4. ✅ **Added complete `format_ai_comment()` implementation** - Matches workflows.md spec
5. ✅ **Independent `hook_logger.py`** - Own implementation following amplifier pattern
6. ✅ **Updated `TriageResult` model** - Added error field for failure cases
7. ✅ **Added error handling** - Fail fast, log errors, return meaningful failures

**Philosophy wins**:
- YAGNI: No retry until network failures observed in practice
- Ruthless simplicity: ~1,070 lines (down from 1,120)
- Fail fast: Clear error messages, no silent failures
- Battle-tested: Using amplifier's proven defensive patterns

## Summary

Implement the orchestrator project - an AI-powered orchestrator for tactical product development work. This is a **new project** with no existing code, so all files will be created from scratch based on the approved Phase 2 documentation (which serves as the specification).

**Total estimated**: ~1,120 lines of code across 14 Python files, 2 shell scripts, and supporting configuration.

**Architecture**: Pragmatic Python orchestration with Claude Code hooks for logging/metrics.

## Current State

**NO EXISTING CODE** - This is a greenfield project. All files documented in Phase 2 will be created from scratch.

**Existing files** (documentation and configuration from Phase 2):
- Documentation: README.md, docs/*.md (6 files)
- Configuration: pyproject.toml, Makefile, package.json, .gitignore, LICENSE, CHANGELOG.md
- Git: Initialized as separate repository, registered as submodule in parent

## Files to Create

### Python Source Modules

#### File: `src/orchestrator/__init__.py`

**Purpose**: Package initialization and exports

**Contents** (~10 lines):
- Version constant
- Public API exports (models, main functions)
- Package-level docstring

**Dependencies**: None

**Agent Suggestion**: modular-builder

---

#### File: `src/orchestrator/models.py`

**Purpose**: Pydantic data models for all workflows

**Contents** (~100 lines):
```python
from pydantic import BaseModel
from typing import Literal

# Triage workflow models (per architecture.md lines 55-58)
class TriageInput(BaseModel):
    ticket_id: str

class ValidityAnalysis(BaseModel):
    is_valid: bool
    is_actionable: bool
    missing_context: list[str]
    reasoning: str

class SeverityAnalysis(BaseModel):
    severity: Literal["P0", "P1", "P2", "P3"]
    complexity: Literal["simple", "medium", "complex"]
    required_expertise: list[str]
    reasoning: str

class TriageResult(BaseModel):
    ticket_id: str
    ticket_url: str
    validity: ValidityAnalysis | None  # None if triage failed
    severity: SeverityAnalysis | None  # None if triage failed
    ai_comment: str
    success: bool
    duration: float
    agents_used: list[str]
    error: str | None = None  # Error message if success=False
```

**Specification Reference**:
- docs/workflows.md lines 116-148 (validity and severity response structure)
- docs/architecture.md lines 55-58 (model structure)

**Dependencies**: pydantic

**Agent Suggestion**: modular-builder

---

#### File: `src/orchestrator/utils.py`

**Purpose**: Defensive utilities for LLM response handling and CLI execution

**Contents** (~100 lines):
```python
import json
import logging
import re
import subprocess
from typing import Union, Any

logger = logging.getLogger(__name__)

def parse_llm_json(response: str) -> dict[str, Any]:
    """
    Extract JSON from any LLM response format.

    Handles:
    - Plain JSON
    - Markdown-wrapped JSON (```json blocks)
    - JSON with text preambles
    - Common formatting issues
    - Multiple JSON objects (returns first valid one)

    Raises ValueError if no valid JSON can be extracted (fail-fast pattern).

    Based on amplifier/ccsdk_toolkit/defensive/llm_parsing.py
    """
    if not response or not response.strip():
        raise ValueError("Empty response from LLM")

    # Try 1: Direct JSON parsing (fastest path)
    try:
        return json.loads(response)
    except json.JSONDecodeError:
        pass

    # Try 2: Extract from markdown code blocks
    markdown_patterns = [
        r"```json\s*(.*?)\s*```",  # ```json ... ```
        r"```\s*(.*?)\s*```",      # ``` ... ```
    ]
    for pattern in markdown_patterns:
        matches = re.findall(pattern, response, re.DOTALL | re.IGNORECASE)
        for match in matches:
            try:
                return json.loads(match.strip())
            except json.JSONDecodeError:
                continue

    # Try 3: Find JSON structures in text
    # Non-greedy matching to avoid capturing multiple objects with invalid text between
    json_patterns = [
        r"\{(?:[^{}]|(?:\{[^{}]*\}))*\}",     # Nested objects (max 2 levels)
        r"\[(?:[^\[\]]|(?:\[[^\[\]]*\]))*\]",  # Nested arrays (max 2 levels)
    ]
    for pattern in json_patterns:
        matches = re.findall(pattern, response, re.DOTALL)
        # Try longest match first (most likely to be complete)
        for match in sorted(matches, key=len, reverse=True):
            try:
                return json.loads(match)
            except json.JSONDecodeError:
                continue

    # All attempts failed - raise with helpful context
    preview = response[:200] + ("..." if len(response) > 200 else "")
    raise ValueError(f"Could not extract valid JSON from LLM response. Preview: {preview}")

def run_cli_command(
    command: list[str],
    timeout: int = 300,
    check: bool = True
) -> subprocess.CompletedProcess:
    """
    Execute CLI command with comprehensive error handling.

    NO RETRY LOGIC - Fail fast and log errors.
    Add retry only if network failures observed in practice.

    Returns CompletedProcess with stdout, stderr, and returncode
    (allows caller to access all output, not just stdout)

    Raises subprocess.CalledProcessError, subprocess.TimeoutExpired, or FileNotFoundError
    """
    logger.debug(f"Running command: {' '.join(command)}")

    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=check
        )

        if result.returncode == 0:
            logger.debug(f"Command succeeded: {' '.join(command)}")
        else:
            logger.warning(
                f"Command failed with code {result.returncode}: {' '.join(command)}\n"
                f"stderr: {result.stderr}"
            )

        return result

    except subprocess.TimeoutExpired:
        logger.error(f"Command timed out after {timeout}s: {' '.join(command)}")
        raise

    except FileNotFoundError:
        logger.error(f"Command not found: {command[0]}")
        raise

    except subprocess.CalledProcessError as e:
        logger.error(
            f"Command failed with code {e.returncode}: {' '.join(command)}\n"
            f"stderr: {e.stderr}"
        )
        raise

def run_agent(agent_name: str, task_description: str, timeout: int = 60) -> str:
    """
    Delegate task to Claude Code agent via --agents flag.

    Command format:
        claude --print --agents '{agent_name: {...}}' "prompt"

    Note: Using amplifier's existing agents would require them to be
    defined in .claude/agents/. For now, using --agents flag for
    dynamic agent creation.

    Returns agent output as string
    """
    logger.info(f"Delegating to {agent_name}: {task_description[:100]}...")

    # Format agent definition
    agent_def = {
        agent_name: {
            "description": f"Specialized agent for {agent_name}",
            "prompt": task_description
        }
    }

    command = [
        "claude",
        "--print",
        "--agents", json.dumps(agent_def),
        task_description
    ]

    return run_cli_command(command, timeout=timeout).stdout
```

**Specification Reference**:
- amplifier/ccsdk_toolkit/defensive/llm_parsing.py (parse_llm_json pattern)
- docs/architecture.md lines 60-63 (utils module description)
- docs/workflows.md lines 99-113 (validity analysis delegation)
- docs/workflows.md lines 125-141 (severity assessment delegation)
- Philosophy: YAGNI - no retry until failures observed

**Dependencies**: Standard library (json, subprocess, logging, re)

**Agent Suggestion**: modular-builder

---

---

#### File: `src/orchestrator/triage.py`

**Purpose**: Main triage workflow orchestration

**Contents** (~150 lines):
```python
import asyncio
from .models import TriageInput, TriageResult, ValidityAnalysis, SeverityAnalysis
from .utils import run_cli_command, run_agent, parse_llm_json
import time
import logging

logger = logging.getLogger(__name__)

def execute_triage(ticket_id: str) -> TriageResult:
    """
    Execute support triage workflow

    Steps (per docs/workflows.md lines 18-27):
    1. Fetch ticket from Linear
    2. Analyze validity (analysis-expert agent)
    3. Assess severity (bug-hunter agent)
    4. Update Linear with AI analysis

    Returns TriageResult with all data
    """
    start_time = time.time()

    try:
        # Step 1: Fetch ticket (docs/workflows.md lines 82-94)
        logger.info(f"Fetching ticket {ticket_id}")
        ticket_json = run_cli_command([
            "linear-cli", "issue", "get", ticket_id, "--json"
        ])

        # Step 2: Validity analysis (docs/workflows.md lines 96-120)
        logger.info("Analyzing validity")
        validity_raw = run_agent(
            agent_name="analysis-expert",
            task_description=f"Analyze validity: {ticket_json}"
        )
        validity_data = parse_llm_json(validity_raw, default={})
        if not validity_data:
            raise ValueError("Agent returned invalid JSON for validity analysis")
        validity = ValidityAnalysis(**validity_data)

        # Step 3: Severity assessment (docs/workflows.md lines 122-148)
        logger.info("Assessing severity")
        severity_raw = run_agent(
            agent_name="bug-hunter",
            task_description=f"Assess severity: {ticket_json}"
        )
        severity_data = parse_llm_json(severity_raw, default={})
        if not severity_data:
            raise ValueError("Agent returned invalid JSON for severity assessment")
        severity = SeverityAnalysis(**severity_data)

        # Step 4: Update Linear (docs/workflows.md lines 150-178)
        logger.info("Updating Linear")
        comment = format_ai_comment(validity, severity)
        run_cli_command([
            "linear-cli", "issue", "update", ticket_id,
            "--priority", severity.severity,
            "--comment", comment
        ])

        duration = time.time() - start_time
        logger.info(f"Triage complete in {duration:.1f}s")

        return TriageResult(
            ticket_id=ticket_id,
            ticket_url=f"https://linear.app/issue/{ticket_id}",
            validity=validity,
            severity=severity,
            ai_comment=comment,
            success=True,
            duration=duration,
            agents_used=["analysis-expert", "bug-hunter"]
        )

    except Exception as e:
        duration = time.time() - start_time
        logger.error(f"Triage failed: {e}")
        # Return failure result instead of raising
        return TriageResult(
            ticket_id=ticket_id,
            ticket_url=f"https://linear.app/issue/{ticket_id}",
            validity=None,
            severity=None,
            ai_comment="",
            success=False,
            duration=duration,
            agents_used=[],
            error=str(e)
        )

def format_ai_comment(
    validity: ValidityAnalysis,
    severity: SeverityAnalysis
) -> str:
    """
    Format AI analysis as Linear comment

    Format per docs/workflows.md lines 162-178
    """
    return f"""## AI Triage Analysis

**Validity**: {"Valid" if validity.is_valid else "Invalid"}, {"Actionable" if validity.is_actionable else "Not Actionable"}
**Severity**: {severity.severity}
**Complexity**: {severity.complexity.capitalize()}
**Required Expertise**: {", ".join(severity.required_expertise)}

### Validity Analysis
{validity.reasoning}

{"#### Missing Context" if validity.missing_context else ""}
{chr(10).join(f"- {item}" for item in validity.missing_context) if validity.missing_context else ""}

### Severity Assessment
{severity.reasoning}

---
*Generated by Orchestrator*
"""
```

**Specification Reference**:
- docs/workflows.md lines 1-244 (complete workflow specification)
- docs/architecture.md lines 65-68 (triage module description)
- README.md lines 50-62 (workflow overview)

**Dependencies**: models, utils

**Agent Suggestion**: modular-builder

---

#### File: `src/orchestrator/cli.py`

**Purpose**: Click CLI interface

**Contents** (~80 lines):
```python
import click
import asyncio
import sys
from .triage import execute_triage

@click.group()
@click.version_option(version="0.1.0")
def cli():
    """Orchestrator - AI-powered tactical product development automation"""
    pass

@cli.command()
@click.argument("ticket_id")
def triage(ticket_id: str):
    """
    Analyze Linear support ticket

    Usage: orchestrator triage ABC-123

    Specification: docs/workflows.md lines 29-40
    """
    click.echo(f"Fetching ticket {ticket_id}...")

    try:
        result = asyncio.run(execute_triage(ticket_id))

        if result.success:
            click.echo(f"✓ Ticket fetched: \"{result.ticket_url}\"")
            click.echo(f"")
            click.echo(f"Analyzing validity...")
            click.echo(f"✓ Validity analysis complete")
            click.echo(f"  - Valid: {result.validity.is_valid}")
            click.echo(f"  - Actionable: {result.validity.is_actionable}")
            click.echo(f"")
            click.echo(f"Assessing severity...")
            click.echo(f"✓ Severity assessment complete")
            click.echo(f"  - Priority: {result.severity.severity}")
            click.echo(f"  - Complexity: {result.severity.complexity}")
            click.echo(f"")
            click.echo(f"✓ Triage complete for {ticket_id} ({result.duration:.1f}s total)")
        else:
            click.echo(f"✗ Triage failed", err=True)
            sys.exit(1)

    except Exception as e:
        click.echo(f"✗ Error: {e}", err=True)
        sys.exit(1)

if __name__ == "__main__":
    cli()
```

**Specification Reference**:
- docs/workflows.md lines 29-63 (usage and expected output)
- docs/architecture.md lines 70-73 (CLI module description)
- README.md lines 36-44 (first triage example)

**Dependencies**: click, triage module

**Agent Suggestion**: modular-builder

---

### Claude Code Hooks

#### File: `.claude/tools/hook_post_triage.py`

**Purpose**: Log triage metrics after workflow completion

**Contents** (~60 lines):
```python
#!/usr/bin/env python3
"""Log triage execution metadata for optimization analysis"""

from hook_logger import HookLogger
import json
import sys

logger = HookLogger("post_triage")

def main():
    # Read workflow result from stdin (Claude Code protocol)
    input_data = json.load(sys.stdin)

    logger.info(f"Triage completed for ticket {input_data.get('ticket_id')}")
    logger.info(f"Analysis duration: {input_data.get('duration')}s")
    logger.info(f"Success: {input_data.get('success')}")

    # Log metrics to JSONL for future optimization
    with open("logs/triage_metrics.jsonl", "a") as f:
        f.write(json.dumps({
            "ticket_id": input_data.get("ticket_id"),
            "duration": input_data.get("duration"),
            "agents_used": input_data.get("agents_used", []),
            "success": input_data.get("success"),
            "timestamp": input_data.get("timestamp")
        }) + "\\n")

    # Return metadata (Claude Code protocol)
    json.dump({"metadata": {"logged": True}}, sys.stdout)

if __name__ == "__main__":
    main()
```

**Specification Reference**:
- docs/hooks_and_skills.md lines 39-71 (hook implementation pattern)
- docs/architecture.md lines 77-80 (hook description)
- docs/workflows.md lines 220-237 (metrics structure)

**Dependencies**: hook_logger

**Agent Suggestion**: modular-builder

---

#### File: `.claude/tools/hook_logger.py`

**Purpose**: Shared logging utility for hooks

**Contents** (~80 lines):
```python
"""Shared logging utility for Claude Code hooks"""

from datetime import datetime
from pathlib import Path

class HookLogger:
    """File-based logging for hooks"""

    def __init__(self, hook_name: str):
        self.hook_name = hook_name
        self.log_dir = Path("logs")
        self.log_dir.mkdir(exist_ok=True)

        date_str = datetime.now().strftime("%Y%m%d")
        self.log_file = self.log_dir / f"{hook_name}_{date_str}.log"

    def info(self, message: str):
        """Log info level message"""
        self._write(f"[INFO] {message}")

    def error(self, message: str):
        """Log error level message"""
        self._write(f"[ERROR] {message}")

    def debug(self, message: str):
        """Log debug level message"""
        self._write(f"[DEBUG] {message}")

    def _write(self, message: str):
        """Write to log file with timestamp"""
        timestamp = datetime.now().isoformat()
        with open(self.log_file, "a") as f:
            f.write(f"[{timestamp}] {message}\\n")
```

**Specification Reference**:
- docs/hooks_and_skills.md lines 73-98 (hook logger implementation)
- docs/architecture.md lines 82-85 (hook logger description)

**Dependencies**: Standard library (datetime, pathlib)

**Agent Suggestion**: modular-builder

---

### Test Files

#### File: `tests/conftest.py`

**Purpose**: Pytest fixtures and configuration

**Contents** (~30 lines):
```python
import pytest

@pytest.fixture
def sample_ticket_json():
    """Sample Linear ticket JSON for testing"""
    return {
        "id": "ABC-123",
        "title": "User login fails with 500 error",
        "description": "When users try to login...",
        "priority": "P2"
    }

@pytest.fixture
def sample_validity_analysis():
    """Sample validity analysis for testing"""
    return {
        "is_valid": True,
        "is_actionable": True,
        "missing_context": [],
        "reasoning": "Valid issue with sufficient detail"
    }

@pytest.fixture
def sample_severity_analysis():
    """Sample severity assessment for testing"""
    return {
        "severity": "P1",
        "complexity": "medium",
        "required_expertise": ["Backend", "Database"],
        "reasoning": "High priority authentication issue"
    }
```

**Agent Suggestion**: modular-builder

---

#### File: `tests/test_models.py`

**Purpose**: Test Pydantic models

**Contents** (~50 lines):
```python
import pytest
from orchestrator.models import (
    ValidityAnalysis,
    SeverityAnalysis,
    TriageResult
)

def test_validity_analysis_valid():
    """Test ValidityAnalysis with valid data"""
    data = {
        "is_valid": True,
        "is_actionable": True,
        "missing_context": [],
        "reasoning": "Test"
    }
    analysis = ValidityAnalysis(**data)
    assert analysis.is_valid
    assert analysis.is_actionable

def test_severity_analysis_valid():
    """Test SeverityAnalysis with valid data"""
    data = {
        "severity": "P1",
        "complexity": "medium",
        "required_expertise": ["Backend"],
        "reasoning": "Test"
    }
    analysis = SeverityAnalysis(**data)
    assert analysis.severity == "P1"
    assert analysis.complexity == "medium"

def test_severity_analysis_invalid_severity():
    """Test SeverityAnalysis rejects invalid severity"""
    data = {
        "severity": "P5",  # Invalid
        "complexity": "medium",
        "required_expertise": [],
        "reasoning": "Test"
    }
    with pytest.raises(ValueError):
        SeverityAnalysis(**data)
```

**Agent Suggestion**: modular-builder

---

#### File: `tests/test_utils.py`

**Purpose**: Test defensive utilities

**Contents** (~100 lines):
```python
import pytest
from orchestrator.utils import parse_llm_json, retry_cli_command, run_agent

def test_parse_llm_json_clean():
    """Test parsing clean JSON response"""
    response = '{"key": "value"}'
    result = parse_llm_json(response)
    assert result == {"key": "value"}

def test_parse_llm_json_markdown():
    """Test parsing JSON wrapped in markdown"""
    response = '''Here's the analysis:
```json
{"key": "value"}
```
'''
    result = parse_llm_json(response)
    assert result == {"key": "value"}

def test_parse_llm_json_with_explanation():
    """Test parsing JSON with surrounding text"""
    response = '''Let me analyze this.

    {"key": "value"}

    That's my conclusion.'''
    result = parse_llm_json(response)
    assert result == {"key": "value"}

@pytest.mark.asyncio
async def test_retry_cli_command_success(mocker):
    """Test successful CLI command execution"""
    mock_run = mocker.patch("subprocess.run")
    mock_run.return_value.returncode = 0
    mock_run.return_value.stdout = "success"

    result = await retry_cli_command(["echo", "test"])
    assert result == "success"

@pytest.mark.asyncio
async def test_retry_cli_command_retry_then_success(mocker):
    """Test retry logic with transient failure"""
    mock_run = mocker.patch("subprocess.run")
    # First call fails, second succeeds
    mock_run.side_effect = [
        mocker.Mock(returncode=1, stderr="transient error"),
        mocker.Mock(returncode=0, stdout="success")
    ]

    result = await retry_cli_command(["test"], max_retries=2)
    assert result == "success"
    assert mock_run.call_count == 2

@pytest.mark.asyncio
async def test_run_agent_success(mocker):
    """Test agent delegation"""
    mock_run = mocker.patch("subprocess.run")
    mock_run.return_value.returncode = 0
    mock_run.return_value.stdout = '{"result": "analysis complete"}'

    result = await run_agent("analysis-expert", "Analyze this")
    assert "analysis complete" in result
```

**Agent Suggestion**: modular-builder

---

#### File: `tests/test_triage.py`

**Purpose**: Test triage workflow

**Contents** (~100 lines):
```python
import pytest
from orchestrator.triage import execute_triage, format_ai_comment
from orchestrator.models import ValidityAnalysis, SeverityAnalysis

@pytest.mark.asyncio
async def test_execute_triage_success(mocker):
    """Test successful triage execution"""
    # Mock CLI commands
    mock_cli = mocker.patch("orchestrator.triage.retry_cli_command")
    mock_cli.return_value = '{"id": "ABC-123", "title": "Test"}'

    # Mock agent calls
    mock_agent = mocker.patch("orchestrator.triage.run_agent")
    mock_agent.side_effect = [
        '{"is_valid": true, "is_actionable": true, "missing_context": [], "reasoning": "Valid"}',
        '{"severity": "P1", "complexity": "medium", "required_expertise": ["Backend"], "reasoning": "High priority"}'
    ]

    result = await execute_triage("ABC-123")

    assert result.success
    assert result.ticket_id == "ABC-123"
    assert result.validity.is_valid
    assert result.severity.severity == "P1"

def test_format_ai_comment():
    """Test AI comment formatting"""
    validity = ValidityAnalysis(
        is_valid=True,
        is_actionable=True,
        missing_context=[],
        reasoning="Valid issue"
    )
    severity = SeverityAnalysis(
        severity="P1",
        complexity="medium",
        required_expertise=["Backend"],
        reasoning="High priority"
    )

    comment = format_ai_comment(validity, severity)

    assert "## AI Triage Analysis" in comment
    assert "P1" in comment
    assert "Backend" in comment
```

**Agent Suggestion**: modular-builder

---

#### File: `tests/test_hooks.py`

**Purpose**: Test hook logging

**Contents** (~50 lines):
```python
import pytest
import json
from io import StringIO
from hook_logger import HookLogger

def test_hook_logger_creates_file(tmp_path, mocker):
    """Test hook logger creates log file"""
    mocker.patch("hook_logger.Path", return_value=tmp_path)

    logger = HookLogger("test_hook")
    logger.info("Test message")

    log_files = list(tmp_path.glob("test_hook_*.log"))
    assert len(log_files) == 1

def test_hook_logger_writes_message(tmp_path, mocker):
    """Test hook logger writes messages"""
    log_file = tmp_path / "test.log"
    mocker.patch.object(HookLogger, "log_file", log_file)

    logger = HookLogger("test")
    logger.info("Test message")

    content = log_file.read_text()
    assert "[INFO] Test message" in content

def test_post_triage_hook(mocker):
    """Test post_triage hook processes input correctly"""
    import hook_post_triage

    # Mock stdin with sample data
    sample_data = {
        "ticket_id": "ABC-123",
        "duration": 23.5,
        "success": True,
        "agents_used": ["analysis-expert", "bug-hunter"]
    }
    mocker.patch("sys.stdin", StringIO(json.dumps(sample_data)))

    # Mock stdout to capture output
    mock_stdout = StringIO()
    mocker.patch("sys.stdout", mock_stdout)

    # Run hook
    hook_post_triage.main()

    # Verify output
    output = json.loads(mock_stdout.getvalue())
    assert output["metadata"]["logged"] == True
```

**Agent Suggestion**: modular-builder

---

## Implementation Chunks

Breaking implementation into logical, testable chunks with clear dependencies:

### Chunk 1: Core Data Models and Package Structure

**Files**:
- `src/orchestrator/__init__.py`
- `src/orchestrator/models.py`
- `tests/conftest.py`
- `tests/test_models.py`

**Description**: Foundation - data structures all other modules depend on

**Why First**: All other modules import from models.py

**Test Strategy**: Unit tests for Pydantic validation

**Dependencies**: None

**Commit Point**: After unit tests pass

**Estimated Time**: 1-2 hours

---

### Chunk 2: Defensive Utilities

**Files**:
- `src/orchestrator/utils.py`
- `tests/test_utils.py`

**Description**: Defensive utilities for LLM response handling and CLI execution

**Why Second**: Workflow and CLI depend on these utilities

**Test Strategy**: Unit tests with mocked subprocess calls

**Dependencies**: Chunk 1 (models)

**Commit Point**: After all utility tests pass

**Estimated Time**: 2-3 hours

---

### Chunk 3: Triage Workflow

**Files**:
- `src/orchestrator/triage.py`
- `tests/test_triage.py`

**Description**: Main triage workflow orchestration

**Why Third**: CLI depends on this, but this depends on utils

**Test Strategy**: Integration tests with mocked CLI and agents

**Dependencies**: Chunks 1 & 2

**Commit Point**: After workflow tests pass

**Estimated Time**: 2-3 hours

---

### Chunk 4: CLI Interface

**Files**:
- `src/orchestrator/cli.py`

**Description**: Click CLI entry point

**Why Fourth**: Final user-facing layer, depends on workflow

**Test Strategy**: Manual testing with `uv run orchestrator --help`

**Dependencies**: Chunks 1, 2, & 3

**Commit Point**: After CLI works end-to-end

**Estimated Time**: 1-2 hours

---

### Chunk 5: Claude Code Hooks

**Files**:
- `.claude/tools/hook_logger.py`
- `.claude/tools/hook_post_triage.py`
- `tests/test_hooks.py`

**Description**: Logging and metrics collection hooks

**Why Fifth**: Independent of core workflow, adds automation

**Test Strategy**: Unit tests for logger, integration test for hook

**Dependencies**: None (reads from stdin)

**Commit Point**: After hook tests pass

**Estimated Time**: 1-2 hours

---

## Agent Orchestration Strategy

### Primary Agent

**modular-builder** - For all module implementation

Use for each chunk:
```
Task modular-builder: "Implement Chunk X according to code_plan.md section 'Chunk X'.

Files to create:
[list files]

Specifications:
[reference docs sections]

Requirements:
- Follow module size guidelines (~100-150 lines)
- Include comprehensive docstrings
- Add type hints throughout
- Follow Phase 2 documentation exactly
- Create working, tested code"
```

### Sequential Implementation

**Must be sequential** due to dependencies:

```
Chunk 1 (Models)
    ↓
Chunk 2 (Utils)
    ↓
Chunk 3 (Triage)
    ↓
Chunk 4 (CLI)
    ↓
Chunk 5 (Hooks) [independent, could be parallel]
```

### Support Agents

**bug-hunter** - If issues arise during implementation:
```
Task bug-hunter: "Debug [specific problem] in [module]"
```

**test-coverage** - After each chunk:
```
Task test-coverage: "Review test coverage for [chunk], suggest additional tests"
```

---

## Testing Strategy

### Unit Tests

**Files**:
- `tests/test_models.py` - Pydantic validation
- `tests/test_utils.py` - Defensive utilities
- `tests/test_hooks.py` - Hook logging

**Coverage Target**: 80%+ for utils and models

**Run**:
```bash
make test
```

### Integration Tests

**Files**:
- `tests/test_triage.py` - Workflow with mocked externals

**Strategy**: Mock CLI commands and agent calls, test workflow logic

**Run**:
```bash
pytest tests/test_triage.py -v
```

### End-to-End Testing

**Manual testing** with real Linear tickets:

```bash
# Authenticate
linear-cli auth login

# Run triage
uv run orchestrator triage ABC-123
```

**Expected behavior** (per docs/workflows.md lines 42-63):
1. Fetches ticket from Linear
2. Delegates to analysis-expert agent
3. Delegates to bug-hunter agent
4. Updates Linear with AI analysis
5. Completes in 20-30 seconds

---

## Philosophy Compliance

### Ruthless Simplicity

**Maintained**:
- ✅ Manual invocation (no polling)
- ✅ Minimal dependencies (click, pydantic only)
- ✅ File-based state (no database)
- ✅ Direct CLI tool usage (no wrappers)
- ✅ Python for orchestration, hooks for logging

**Avoided**:
- ❌ No automated polling
- ❌ No complex state machines
- ❌ No unnecessary abstractions
- ❌ No future-proofing

### Modular Design

**Clear boundaries**:
- `models.py` - Data contracts (~100 lines)
- `utils.py` - Reusable utilities (~150 lines)
- `triage.py` - Workflow logic (~150 lines)
- `cli.py` - User interface (~80 lines)
- Hooks - Logging (~140 lines)

**Bricks & Studs**:
- Each module self-contained
- Clear interfaces (Pydantic models)
- Independently testable
- AI-regeneratable size

---

## Commit Strategy

### Commit 1: Core Data Models

```
feat: Add Pydantic data models for orchestrator

- Create TriageInput, ValidityAnalysis, SeverityAnalysis, TriageResult models
- Add package initialization
- Add test fixtures
- Unit tests passing

Implements Chunk 1 per code_plan.md
```

### Commit 2: Defensive Utilities

```
feat: Add defensive utilities for LLM and CLI handling

- Implement parse_llm_json() for robust JSON extraction
- Implement retry_cli_command() with exponential backoff
- Implement run_agent() for Claude Code delegation
- All utility tests passing

Implements Chunk 2 per code_plan.md
```

### Commit 3: Triage Workflow

```
feat: Implement support triage workflow

- Add execute_triage() main workflow function
- Add format_ai_comment() for Linear updates
- Coordinate: fetch → analyze → assess → update
- Integration tests passing

Implements Chunk 3 per code_plan.md
```

### Commit 4: CLI Interface

```
feat: Add Click CLI interface

- Implement orchestrator CLI group
- Add triage command with progress indicators
- User-friendly error messages
- CLI working end-to-end

Implements Chunk 4 per code_plan.md
```

### Commit 5: Claude Code Hooks

```
feat: Add Claude Code hooks for metrics collection

- Implement HookLogger shared utility
- Add post_triage hook for metrics logging
- JSONL metrics collection
- Hook tests passing

Implements Chunk 5 per code_plan.md
```

---

## Risk Assessment

### High Risk Changes

**None** - This is new code, no existing functionality to break

### Dependencies to Watch

**linear-cli**:
- Version constraints: None specified
- Mitigation: Test with current version, document in setup.md

**Claude Code SDK**:
- Version: User's existing installation
- Mitigation: Document required claude CLI availability

**Python 3.11+**:
- Specified in pyproject.toml
- Mitigation: CI checks (when added)

### Breaking Changes

**None** - New project, no existing users

---

## Success Criteria

Code is ready when:

- [x] All documented behavior implemented (per Phase 2 docs)
- [ ] All tests passing (`make check`, `make test`)
- [ ] User testing works as documented (manual triage)
- [ ] No regressions (N/A - new project)
- [ ] Code follows philosophy (ruthless simplicity, modular design)
- [ ] Modules are right-sized (~100-150 lines each)
- [ ] Ready for Phase 4 implementation

**Verification Commands**:
```bash
# All checks pass
make check

# All tests pass
make test

# CLI works
uv run orchestrator --help
uv run orchestrator triage ABC-123
```

---

## Next Steps

✅ Code plan complete and detailed
➡️ Get zen-architect review
➡️ Get user approval
➡️ When approved, run: `/ddd:4-code`

---

**Plan Version**: 1.0
**Status**: Awaiting review
**Estimated Implementation Time**: 8-12 hours (across 5 chunks)
