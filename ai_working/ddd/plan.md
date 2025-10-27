# DDD Plan: AI-Powered Product Development Orchestrator

## Problem Statement

**What we're solving**: Product teams face a "tactical tax" - constant overhead from documentation updates, context switching, volume of small tasks, technical analysis requiring codebase knowledge, and coordination work that prevents strategic focus.

**Why it matters**: Tactical work drowns teams, causing:
- PM time competing with project work
- Volume of tickets falling through cracks
- Engineer availability bottleneck for technical analysis
- Inconsistent/outdated documentation across tools
- Loss of strategic thinking time

**User value**:
- ⏰ Time reclaimed for strategic work
- ✓ Nothing falls through the cracks (system handles volume)
- 🔧 Non-technical members get technical insights
- 📚 Consistent, up-to-date documentation everywhere
- 🎯 Single interface to multiple systems

**Concrete first pain point**: Support triage tickets in Linear. Client issues arrive → Support creates Linear ticket (Triage status) → **AI needs to investigate validity, assess priority, provide technical context** → PM can make informed decision without engineer time.

## Proposed Solution

Build a **standalone orchestrator** as git submodule that:

1. **Uses CLI tools** (not MCP servers) for external integrations (`linear-cli`, `gh`, etc.)
2. **Delegates to amplifier agents** via Claude Code SDK CLI (no code imports)
3. **Leverages Claude Code hooks/skills** for automation (not Python code where possible)
4. **Uses standard tooling** (uv, ruff, pnpm, shfmt) following amplifier conventions
5. **Implements workflows** starting with support triage
6. **Operates independently** with minimal dependencies
7. **Follows ruthless simplicity** - proven patterns only

### Why Standalone Submodule?

- Amplifier has breaking changes frequently
- Independent version control and release cycle
- Cleaner boundaries (can't casually import)
- More portable (could work independently eventually)

### Why CLI Tools Over MCP?

User's experience: CLI tools are more reliable than MCP servers
- `linear-cli` is mature, battle-tested
- Better error handling
- Simpler authentication
- Standard Unix philosophy

### Why Agent Delegation via CLI?

Can use amplifier's 44 agents without code coupling:
```bash
claude code task --agent analysis-expert "Analyze this issue..."
```

Clean process isolation, no imports needed.

## Alternatives Considered

### Alternative A: Modify Amplifier Directly
**Rejected**: Amplifier has breaking changes; can't couple tightly

### Alternative B: MCP Server for Integrations
**Rejected**: User experience shows CLI tools more reliable

### Alternative C: Build Own Agent Framework
**Rejected**: Violates ruthless simplicity; leverage existing agents

### Alternative D: Python Library (Not CLI)
**Deferred**: Start with CLI, evolve to library if needed

## Architecture & Design

### Project Structure (Git Submodule)

```
orchestrator/                    # Git submodule
├── .git/                       # Own repository
├── pyproject.toml              # uv-managed dependencies (click, pydantic)
├── uv.lock                     # Dependency lock file
├── ruff.toml                   # Ruff configuration
├── README.md                   # Setup, usage, architecture
├── Makefile                    # Standard commands (install, check, test, format-sh)
├── .claude/                    # Claude Code configuration
│   └── tools/                 # Hook scripts (following amplifier pattern)
│       ├── hook_post_triage.py   # Log triage metrics
│       └── hook_logger.py        # Shared logging (from amplifier)
├── src/
│   └── orchestrator/
│       ├── __init__.py
│       ├── models.py           # Pydantic domain models
│       ├── utils.py            # Defensive utilities (parse_llm_json, retry, etc)
│       ├── triage.py           # Main triage workflow
│       └── cli.py              # Click CLI entry point
├── scripts/                    # Shell scripts (zsh-compatible, shfmt validated)
│   ├── setup.sh               # Project setup automation
│   └── triage.sh              # Thin wrapper: python -m orchestrator.cli triage
├── tests/
│   ├── conftest.py
│   ├── test_models.py
│   ├── test_utils.py
│   ├── test_triage.py
│   └── test_hooks.py
├── logs/                       # Hook logs and metrics
│   └── triage_metrics.jsonl
└── docs/
    ├── setup.md
    └── workflows.md
```

**Key changes from typical Python project**:
- **Python for orchestration** - Click CLI, workflow logic, defensive utils
- **Hooks for logging/metrics** - Following amplifier pattern exactly
- **Scripts are thin wrappers** - zsh-compatible, shfmt validated
- **uv manages dependencies** - Not poetry/pip
- **ruff for linting/formatting** - Configured separately
- **Manual invocation** - User runs `orchestrator triage <ticket-id>`

### Claude Code Integration: Pragmatic Hooks Pattern

**Core Principle**: Use Python for orchestration, hooks for automation/logging (following amplifier pattern)

#### How Amplifier Uses Hooks

**Pattern observed in amplifier**:
- Hooks are Python scripts (e.g., `hook_stop.py`, `hook_post_tool_use.py`)
- Read JSON from stdin, write JSON to stdout
- Call amplifier modules for actual logic
- Log outcomes to file using `hook_logger.py`
- Return metadata about execution

**Example from amplifier**:
```python
#!/usr/bin/env python3
# .claude/tools/hook_stop.py
from hook_logger import HookLogger
from amplifier.extraction import MemoryExtractor

logger = HookLogger("stop_hook")

async def main():
    logger.info("Starting memory extraction")
    # Actual logic via amplifier modules
    extractor = MemoryExtractor()
    memories = await extractor.extract(input_json)

    logger.info(f"Extracted {len(memories)} memories")
    # Return metadata
    json.dump({"metadata": {"memoriesExtracted": len(memories)}}, sys.stdout)
```

#### Orchestrator Hook Pattern

**Use hooks for automation AFTER core work, not orchestration**:

```python
#!/usr/bin/env python3
# .claude/tools/hook_post_triage.py
"""Log triage execution metadata for optimization analysis"""

from hook_logger import HookLogger
import json, sys

logger = HookLogger("post_triage")

def main():
    # Read what just happened from stdin
    input_data = json.load(sys.stdin)

    logger.info(f"Triage completed for ticket {input_data.get('ticket_id')}")
    logger.info(f"Analysis duration: {input_data.get('duration')}s")

    # Log for future optimization
    with open("logs/triage_metrics.jsonl", "a") as f:
        f.write(json.dumps({
            "ticket_id": input_data.get("ticket_id"),
            "duration": input_data.get("duration"),
            "agents_used": input_data.get("agents"),
            "success": input_data.get("success")
        }) + "\n")

    # Return metadata (Claude Code protocol)
    json.dump({"metadata": {"logged": True}}, sys.stdout)
```

#### Actual Orchestration: Python + Shell

**Primary workflow** (manual invocation):

```python
#!/usr/bin/env python3
# orchestrator/triage.py - Main entry point

import asyncio
from orchestrator.core import TriageWorkflow
from orchestrator.utils import parse_llm_json, retry_cli_command

async def main(ticket_id: str):
    # Fetch ticket via linear-cli
    ticket_json = retry_cli_command(["linear-cli", "issue", "get", ticket_id, "--json"])

    # Delegate to agents
    validity = await run_agent("analysis-expert", f"Analyze: {ticket_json}")
    severity = await run_agent("bug-hunter", f"Assess severity: {ticket_json}")

    # Parse AI responses (defensive)
    validity_data = parse_llm_json(validity)
    severity_data = parse_llm_json(severity)

    # Update Linear
    retry_cli_command([
        "linear-cli", "issue", "update", ticket_id,
        "--comment", f"AI Analysis:\n{validity_data}\n{severity_data}"
    ])

    print(f"✓ Triage complete for {ticket_id}")
```

**Shell wrapper** (optional):
```bash
#!/usr/bin/env zsh
# scripts/triage.sh
python -m orchestrator.triage "$@"
```

#### Python Does the Work, Hooks Do the Logging

```
User → Python Script → CLI Tools + Agents → Parse → Update Linear
                ↓                                       ↓
           Core Logic                            Hook logs execution
           (orchestrator/)                       (.claude/tools/hook_*)
```

**Hooks are for**:
- Logging execution metadata (duration, success, errors)
- Collecting data for future optimization
- Cleanup tasks after workflows complete
- NOT for orchestration or complex logic

### Key Interfaces ("Studs")

#### 1. Workflow Base Class
```python
from abc import ABC, abstractmethod
from pydantic import BaseModel

class WorkflowResult(BaseModel):
    success: bool
    outputs: dict
    errors: list[str] = []

class Workflow(ABC):
    """Base abstraction for all orchestrated workflows."""

    @abstractmethod
    async def execute(self, inputs: dict) -> WorkflowResult:
        """Run the workflow end-to-end."""
        pass

    @abstractmethod
    def describe(self) -> dict:
        """Describe workflow for AI/human understanding."""
        pass
```

#### 2. CLI Tool Wrapper
```python
class ToolResult(BaseModel):
    stdout: str
    stderr: str
    returncode: int
    success: bool

class CLITool:
    """Wrapper for external CLI tools with retry logic."""

    def __init__(self, command: str, max_retries: int = 3):
        self.command = command
        self.max_retries = max_retries

    async def run(self, *args, **kwargs) -> ToolResult:
        """Execute CLI command with retries."""
        pass
```

#### 3. Agent Delegator
```python
class AgentResult(BaseModel):
    agent_name: str
    output: str
    success: bool
    parsed: dict = {}

class AgentDelegator:
    """Delegate tasks to amplifier agents via Claude Code SDK."""

    async def delegate(
        self,
        agent_name: str,
        task_description: str,
        context_files: list[str] = None
    ) -> AgentResult:
        """
        Runs: claude code task --agent {agent_name} "{task_description}"
        """
        pass
```

### Module Boundaries

**Core Modules** (foundational):
- `workflow.py` - Base abstraction, all workflows inherit
- `cli_tools.py` - Subprocess wrapper, retry logic, error handling
- `delegation.py` - Agent task delegation via Claude CLI

**Workflow Modules** (concrete implementations):
- `support_triage.py` - First workflow: support ticket triage
- (future) `notion_prd_sync.py` - Sync PRDs from Notion
- (future) `release_notes.py` - Generate release notes

**CLI Module**:
- `cli.py` - Click-based entry point, orchestrates workflows

### Data Models

```python
# Support Triage Workflow Models

class TriageInput(BaseModel):
    issue_text: str
    reporter: str
    team_id: str
    source: Literal["email", "github", "slack"]

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
    validity: ValidityAnalysis
    severity: SeverityAnalysis
    ai_comment: str
    success: bool
```

## Files to Change

### Non-Code Files (Phase 2: Documentation)

Since this is a new submodule, these files need to be **created**, not updated:

#### In `orchestrator/` (new submodule):
- [ ] `README.md` - Project overview, setup instructions, usage examples
- [ ] `docs/setup.md` - Detailed setup guide (uv, linear-cli, auth)
- [ ] `docs/workflows.md` - Documentation of available workflows
- [ ] `docs/architecture.md` - Architecture decisions, hooks/skills pattern
- [ ] `docs/adding_workflows.md` - Guide for adding new workflows
- [ ] `docs/hooks_and_skills.md` - Claude Code automation guide
- [ ] `pyproject.toml` - uv-managed dependencies, ruff config
- [ ] `ruff.toml` - Ruff linting/formatting configuration
- [ ] `package.json` - pnpm-managed node dependencies (shfmt)
- [ ] `Makefile` - Standard commands (install, check, test, format-sh)
- [ ] `.gitignore` - Python, node, IDE, logs, state files
- [ ] `LICENSE` - Project license
- [ ] `CHANGELOG.md` - Version history

#### In parent `amplifier/`:
- [ ] `README.md` - Add section on orchestrator submodule
- [ ] `.gitmodules` - Register orchestrator as submodule
- [ ] `docs/tools.md` (if exists) - Document orchestrator tool

### Code Files (Phase 4: Implementation)

**Pragmatic Python orchestration + hooks for logging**

#### Core Python Modules:
- [ ] `src/orchestrator/__init__.py` - Package exports (~10 lines)
- [ ] `src/orchestrator/models.py` - Pydantic domain models (~100 lines)
  - TriageInput, ValidityAnalysis, SeverityAnalysis, TriageResult
- [ ] `src/orchestrator/utils.py` - Defensive utilities (~150 lines)
  - `parse_llm_json()` - Extract JSON from LLM responses
  - `retry_cli_command()` - Execute CLI with exponential backoff
  - `run_agent()` - Delegate to Claude Code agents
- [ ] `src/orchestrator/triage.py` - Main triage workflow (~150 lines)
  - Fetch ticket, delegate analysis, update Linear
- [ ] `src/orchestrator/cli.py` - CLI entry point using Click (~80 lines)
  - `orchestrator triage <ticket-id>`
  - Progress indicators, error messages

#### Claude Code Hooks (logging/automation):
- [ ] `.claude/tools/hook_post_triage.py` - Log triage metrics (~60 lines)
- [ ] `.claude/tools/hook_logger.py` - Shared logging utility (~80 lines, copy from amplifier)

#### Shell Scripts (zsh-compatible, shfmt validated):
- [ ] `scripts/setup.sh` - Project setup automation (~50 lines)
- [ ] `scripts/triage.sh` - Thin wrapper for Python CLI (~20 lines)

#### Tests:
- [ ] `tests/conftest.py` - Pytest fixtures (~30 lines)
- [ ] `tests/test_models.py` - Test Pydantic models (~50 lines)
- [ ] `tests/test_utils.py` - Test defensive utilities (~100 lines)
- [ ] `tests/test_triage.py` - Test triage workflow (~100 lines)
- [ ] `tests/test_hooks.py` - Test hook logging (~50 lines)

#### Build/Config:
- [ ] `Makefile` - Standard commands (install, check, test, format-sh) (~60 lines)
- [ ] `pyproject.toml` - uv config, ruff config, click dependency (~50 lines)
- [ ] `ruff.toml` - Ruff linting/formatting settings (~20 lines)
- [ ] `package.json` - pnpm config for shfmt (~10 lines)

**Total estimated lines: ~1,120 lines** (close to original, but better architecture)
- Python: ~820 lines (models + utils + workflow + CLI + hooks)
- Shell: ~70 lines (setup + wrapper)
- Tests: ~330 lines (comprehensive coverage)
- Config: ~140 lines (build/test/lint)

**Trade-off**: Similar line count to original, but:
- ✅ Cleaner separation (Python orchestration, hooks for logging)
- ✅ Defensive utilities (robust LLM response handling)
- ✅ Manual invocation (no polling complexity)
- ✅ Follows amplifier hook pattern exactly
- ✅ Standard tooling (uv, ruff, pnpm, shfmt)

## Philosophy Alignment

### Ruthless Simplicity

**Start minimal, grow as needed**:
- ✅ One workflow initially (support triage)
- ✅ Minimal dependencies (click, pydantic only)
- ✅ No frameworks, no databases, no complex state
- ✅ **Manual invocation** (no polling/webhook complexity)

**Avoid future-proofing**:
- ✅ Not building for hypothetical workflows
- ✅ Not over-abstracting (pragmatic Python modules)
- ✅ Not premature optimization
- ✅ **Manual invocation first**, automation later if needed

**Clear over clever**:
- ✅ Python for orchestration (clear, debuggable)
- ✅ Hooks for logging (following amplifier pattern)
- ✅ Shell scripts are thin wrappers (zsh-compatible, shfmt validated)
- ✅ Defensive utilities for LLM response handling

### Modular Design

**Bricks (self-contained modules)**:
- `models.py` - Pydantic domain models (~100 lines)
- `utils.py` - Defensive utilities (~150 lines)
- `triage.py` - Workflow orchestration (~150 lines)
- `cli.py` - Click CLI (~80 lines)
- Hooks - Logging/metrics (~140 lines total)

**Studs (clear interfaces)**:
- CLI → Workflow → Utils → External tools/agents
- Hooks read stdin → call Python modules → write stdout
- Models define data contracts (Pydantic)
- Utils provide defensive patterns (parse_llm_json, retry)

**Regeneratable**:
- ✅ Each module focused and ~100-150 lines
- ✅ Clear contracts between modules
- ✅ Hooks follow amplifier pattern (copy/modify)
- ✅ Tests validate behavior, not implementation

### Present-Moment Focus

**Handle what's needed now**:
- ✅ Support triage is real pain point
- ✅ Linear CLI is proven tool
- ✅ Agent delegation is existing capability

**Not anticipating**:
- ❌ Not building Notion integration yet (though planned)
- ❌ Not building cross-team features yet
- ❌ Not optimizing for scale yet

### Pragmatic Trust

**Trust external systems**:
- ✅ linear-cli handles Linear API complexity
- ✅ Claude Code SDK handles agent orchestration
- ✅ Handle failures as they occur (retry logic)

**Don't over-engineer**:
- ✅ No elaborate error recovery
- ✅ No complex state machines
- ✅ Simple subprocess + retry = reliable enough

## Test Strategy

### Unit Tests

**Core abstractions**:
- `test_cli_tools.py` - Verify subprocess handling, retry logic, error capture
- `test_delegation.py` - Verify Claude CLI invocation, output parsing

**Focus**: Individual component behavior in isolation

### Integration Tests

**Workflow tests**:
- `test_support_triage.py` - End-to-end with mocked CLI tools
  - Mock linear-cli responses
  - Mock agent delegation results
  - Verify workflow logic correct

**Focus**: Component interaction without external dependencies

### End-to-End Tests

**Real workflow execution**:
- Manual testing with real Linear tickets
- Real agent delegation via Claude Code
- Verify actual ticket updates in Linear

**Focus**: Validate in production-like environment

### Testing Pyramid

```
    E2E (10%)         Manual validation with real data
   ────────
  Integration (30%)  Workflow logic with mocked tools
 ─────────────
Unit (60%)           Core components isolated
```

## Implementation Approach

### Phase 1: Submodule Setup & Core Abstractions

**Goal**: Prove the foundation works

**Tasks**:
1. Create git submodule in amplifier repo
2. Set up project structure (pyproject.toml, src/, tests/)
3. Implement `workflow.py` - Base Workflow class
4. Implement `cli_tools.py` - CLI tool wrapper with retry
5. Implement `delegation.py` - Agent delegation via Claude CLI
6. Write unit tests for each module

**Success criteria**:
- Can invoke linear-cli via CLITool wrapper
- Can delegate to amplifier agent via AgentDelegator
- All unit tests pass

### Phase 2: Documentation (DDD Phase 2)

**Goal**: Document the system as if it already exists

**Tasks**:
1. Write `README.md` - Project overview, quick start
2. Write `docs/setup.md` - Installation, CLI tool setup, auth
3. Write `docs/architecture.md` - Design decisions, module boundaries
4. Write `docs/workflows.md` - Available workflows (support triage)
5. Update parent `amplifier/README.md` - Reference submodule

**Success criteria**:
- New user can set up from README
- Architecture is clear to future developers
- Workflows are documented for users

### Phase 3: Support Triage Workflow Implementation

**Goal**: Complete first concrete workflow end-to-end

**Tasks**:
1. Implement `support_triage.py` - SupportTriageWorkflow class
2. Implement CLI command: `orchestrator triage`
3. Write integration tests with mocked tools
4. Document workflow in `docs/workflows.md`

**Success criteria**:
- Can run `orchestrator triage --issue "..." --team "..."`
- Workflow creates Linear ticket
- Workflow delegates to analysis-expert and bug-hunter
- Workflow updates Linear with AI insights
- Integration tests pass

### Phase 4: CLI Interface & User Experience

**Goal**: Polished CLI for human use

**Tasks**:
1. Implement `cli.py` - Click-based CLI
2. Add progress indicators (rich library?)
3. Add error messaging
4. Add `--help` documentation
5. Package for distribution (`pip install -e .`)

**Success criteria**:
- Clean UX with progress feedback
- Helpful error messages
- Easy to install and run
- `--help` is comprehensive

### Phase 5: Real-World Validation

**Goal**: Validate with actual Linear tickets

**Tasks**:
1. Set up linear-cli authentication
2. Test on real support triage tickets
3. Validate Linear updates work correctly
4. Iterate based on real usage
5. Document learnings in CHANGELOG

**Success criteria**:
- Successfully triages 5+ real tickets
- Linear integration works reliably
- Agent delegation provides useful insights
- PM finds it valuable

### Phase 6: Notion Integration (Future)

**Goal**: Add second high-value workflow

**Tasks**:
1. Research Notion CLI options (or API wrapper)
2. Implement `notion_prd_sync.py` workflow
3. Test with real PRDs
4. Document in `docs/workflows.md`

**Success criteria**:
- Can sync PRDs from Notion
- Can extract relevant context for other workflows
- Reliable and useful

## Success Criteria

### Technical Success

- [ ] Support triage workflow completes end-to-end
- [ ] Linear tickets created and updated via linear-cli
- [ ] Agent delegation works via Claude Code SDK CLI
- [ ] All unit and integration tests pass
- [ ] No imports from amplifier codebase
- [ ] Modules stay under 200 lines each

### User Success

- [ ] PM can triage ticket in <2 minutes (vs 15+ minutes manual)
- [ ] AI analysis is accurate and useful
- [ ] No tickets fall through cracks
- [ ] Documentation enables self-service
- [ ] Tool feels reliable, not flaky

### Philosophy Success

- [ ] Ruthless simplicity maintained (minimal deps, clear code)
- [ ] Modular design (clear bricks & studs)
- [ ] Independent submodule (own git, own deps)
- [ ] Proven patterns only (no experiments)

## Dependencies

### Required CLI Tools

- `linear-cli` - Linear integration (https://github.com/schpet/linear-cli)
- `claude` - Claude Code SDK (already installed in amplifier)
- `jq` - JSON processing (standard tool)
- `git` - Version control (standard tool)

### Python Dependencies

**Managed via uv** (not pip/poetry):

```toml
[project]
name = "orchestrator"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = [
    "click>=8.2.1",              # CLI framework
    "pydantic>=2.11.7",          # Data validation
    "pydantic-settings>=2.10.1", # Settings management (if needed)
]

[project.optional-dependencies]
dev = [
    "pytest>=8.3.5",
    "pytest-asyncio>=0.23.0",
    "pytest-cov>=6.1.1",         # Coverage reporting
    "pytest-mock>=3.14.0",       # Mocking utilities
    "pyright>=1.1.406",          # Type checking
    "ruff>=0.11.10",             # Linting/formatting
]

[tool.ruff]
line-length = 120
target-version = "py311"

[tool.pytest.ini_options]
asyncio_mode = "auto"
```

**Install via uv**:
```bash
cd orchestrator
uv sync              # Install dependencies
uv add <package>     # Add new dependency
```

### Node Dependencies (if needed)

**Managed via pnpm** (not npm/yarn):

```json
{
  "name": "orchestrator",
  "version": "0.1.0",
  "devDependencies": {
    "shfmt": "^3.8.0"
  }
}
```

**Install via pnpm**:
```bash
pnpm install         # Install dependencies
pnpm add -D <pkg>    # Add dev dependency
```

### Shell Script Standards

**All shell scripts must follow these standards**:

1. **zsh-compatible** - Entire R&D org uses macOS (zsh default shell)
2. **shfmt validated** - Automated formatting/linting
3. **Shell-agnostic patterns preferred** - POSIX where possible

**Template for shell scripts**:

```bash
#!/usr/bin/env zsh
# Description: Support triage automation
# Usage: ./triage.sh <ticket-id>

set -euo pipefail  # Fail fast, catch errors

# Check dependencies
command -v linear-cli >/dev/null 2>&1 || {
    echo "Error: linear-cli not installed" >&2
    exit 1
}

# Main logic
ticket_id="${1:?Ticket ID required}"

# Invoke hooks/skills (not Python code)
claude skill analyze-validity --ticket-id="$ticket_id"
claude skill assess-severity --ticket-id="$ticket_id"
claude skill update-linear-ticket --ticket-id="$ticket_id"

echo "✓ Triage complete for $ticket_id"
```

**Quality checks**:
```bash
# Format shell scripts
shfmt -i 4 -w scripts/*.sh

# Lint shell scripts (catches common errors)
shfmt -d scripts/*.sh

# Add to Makefile
make format-sh    # Format shell scripts
make check-sh     # Validate shell scripts
```

**Integration with Makefile**:
```makefile
# In Makefile
.PHONY: format-sh check-sh

format-sh:
	pnpm exec shfmt -i 4 -w scripts/*.sh

check-sh:
	pnpm exec shfmt -d scripts/*.sh
	@echo "✓ Shell scripts formatted correctly"
```

### External Services

- Linear API (via linear-cli)
- Claude API (via Claude Code SDK)
- (Future) Notion API

## Risk Mitigation

### Risk: linear-cli reliability
**Mitigation**: Retry logic in CLITool wrapper, fallback to manual

### Risk: Agent delegation fails
**Mitigation**: Graceful degradation, log errors, continue workflow

### Risk: Breaking changes in amplifier
**Mitigation**: Git submodule isolation, own version control

### Risk: CLI tool installation complexity
**Mitigation**: Clear setup docs, installation scripts

### Risk: Token usage costs
**Mitigation**: Start with small team, monitor usage, optimize prompts

## Next Steps

✅ **Phase 1 Complete: Planning Approved**

Plan written to: `ai_working/ddd/plan.md`

**Next Phase**: Update all non-code files (docs, configs, READMEs)

**Run**: `/ddd:2-docs`

The plan will guide all subsequent phases. All commands can now run without arguments using the plan as their guide.

---

## Plan Summary

**Architecture**: Standalone git submodule with pragmatic Python orchestration + hooks for logging

**Key Technologies**:
- uv (Python deps), pnpm (Node deps), ruff (linting), shfmt (shell validation)
- Click (CLI framework), Pydantic (data validation)
- Claude Code hooks (logging/metrics, following amplifier pattern)
- linear-cli (Linear integration), claude CLI (agent delegation)

**Code Volume**: ~1,120 total lines
- Python: ~820 lines (models + utils + workflow + CLI + hooks)
- Shell: ~70 lines (zsh-compatible, shfmt validated)
- Tests: ~330 lines (comprehensive coverage)
- Config: ~140 lines (build/test/lint)

**Philosophy Wins**:
- ✅ Ruthless simplicity: Manual invocation, no polling complexity
- ✅ Modular design: Clear Python modules, each ~100-150 lines
- ✅ Standard tooling: uv, ruff, pnpm, shfmt (amplifier conventions)
- ✅ Pragmatic hooks: Logging/metrics following amplifier pattern exactly
- ✅ Defensive utilities: Robust LLM response handling
- ✅ Python fills gaps: Where Claude Code not intended or not optimal

**Key Decisions**:
1. **Manual invocation** (`orchestrator triage <ticket-id>`) - no automated polling
2. **Python for orchestration** - Click CLI, workflow logic, defensive utils
3. **Hooks for logging** - Metrics collection for future optimization
4. **Standard tooling** - uv, ruff, pnpm, shfmt (amplifier conventions)

---

**Plan Version**: 3.0 (Final: Pragmatic Python + hooks for logging)
**Last Updated**: 2025-10-26
**Status**: Awaiting approval
