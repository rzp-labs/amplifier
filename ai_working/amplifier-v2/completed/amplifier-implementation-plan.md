# Amplifier Implementation Plan: Path to Feature Parity

## Executive Summary

The new Amplifier codebase has successfully established a solid architectural foundation with its modular design, achieving approximately **40% feature parity** with the Claude Code-based version. The core loop, provider abstraction, and hook infrastructure are well-implemented, but critical capabilities for autonomous coding remain incomplete. This plan outlines a prioritized, incremental approach to achieve full parity within 2-3 weeks.

## Current State Assessment

### ✅ What's Working (Implemented)

1. **Core Agent Loop** (`loop-basic`)
   - Functional tool-calling loop matching Claude's pattern
   - Iterative execution until completion
   - Hook integration points

2. **Multi-Provider Support**
   - Anthropic provider with Claude models
   - OpenAI provider with GPT models
   - Unified interface abstraction

3. **Basic Tools**
   - `ReadTool`: File reading with safety checks
   - `WriteTool`: File creation/overwriting
   - `EditTool`: Functional with diff generation
   - `BashTool`: Command execution with safety features
   - `WebFetchTool`: Basic HTTP fetching with BeautifulSoup parsing
   - `WebSearchTool`: Stubbed with mock implementation

4. **Hook Infrastructure**
   - Full HookRegistry implementation
   - Event emission at lifecycle points
   - Priority-based handler execution
   - `TranscriptBackupHook` for session preservation

5. **Modular Architecture**
   - Dynamic module loading via entry points
   - Clean separation of concerns
   - Configuration-driven assembly

### ❌ What's Missing (Critical Gaps)

1. **Sub-Agent Orchestration**
   - No `TaskTool` for delegation
   - Agent modules exist but aren't invocable
   - No recursive session spawning

2. **User Commands**
   - No slash command parsing (`/think`, `/stop`, etc.)
   - No Plan Mode implementation
   - No command validation hooks

3. **Context Persistence**
   - Memory files defined in config but not loaded
   - No CLAUDE.md integration
   - No cross-session knowledge retention

4. **Essential Tools** (14 in Claude Code vs 6 current)
   - Missing: `Glob`, `Grep`, `Ls`, `Find`
   - Missing: `MultiEdit`, `NotebookRead/Edit`
   - `WebSearchTool` not connected to real API

5. **Safety & Approvals**
   - Tool approval mechanism exists but not UI-integrated
   - No interactive approval prompts
   - Security hooks not implemented

## Implementation Roadmap

### Phase 1: Critical Tool Expansion (Days 1-3)
**Goal**: Achieve 80% tool coverage for autonomous coding

#### 1.1 File System Tools
```python
# Priority implementations for amplifier-mod-tool-filesystem

class GlobTool:
    """Find files matching patterns"""
    name = "glob"
    # Implementation: Use pathlib.Path.glob()
    
class GrepTool:
    """Search file contents"""
    name = "grep"
    # Implementation: Async file search with regex

class LsTool:
    """List directory contents with details"""
    name = "ls"
    # Implementation: Enhanced directory listing
```

#### 1.2 Complete EditTool
- Fix the current stub implementation
- Add proper diff display using `difflib`
- Support multi-line replacements
- Return transparent change summaries

#### 1.3 Web Search Integration
```python
# Connect to real search API (DuckDuckGo or Serper)
class WebSearchTool:
    async def execute(self, input: dict) -> ToolResult:
        # Use duckduckgo-search library
        # Or integrate Serper API if API key available
```

**Deliverable**: 10+ functional tools matching Claude Code capabilities

### Phase 2: Sub-Agent System (Days 4-6)
**Goal**: Enable task delegation and specialized agents

#### 2.1 Task Tool Implementation
```python
# New file: amplifier-mod-tool-task/__init__.py

class TaskTool:
    """Spawn sub-agent for complex tasks"""
    name = "task"
    description = "Delegate a subtask to a specialized agent"
    
    async def execute(self, input: dict) -> ToolResult:
        task_description = input.get("task")
        agent_type = input.get("agent", "default")
        
        # Create sub-session with isolated context
        sub_config = self._build_sub_config(agent_type)
        sub_session = AmplifierSession(sub_config)
        await sub_session.initialize()
        
        # Emit agent:spawn hook
        await self.hooks.emit("agent:spawn", {
            "task": task_description,
            "agent": agent_type
        })
        
        # Execute task
        result = await sub_session.execute(task_description)
        
        # Emit agent:complete hook
        await self.hooks.emit("agent:complete", {
            "result": result
        })
        
        return ToolResult(
            success=True,
            output=result
        )
```

#### 2.2 Agent Registry
- Make architect agent invocable
- Add researcher, implementer, reviewer agents
- Connect agents to TaskTool selection

**Deliverable**: Working sub-agent delegation with at least 3 specialized agents

### Phase 3: Command Interface (Days 7-8)
**Goal**: Restore user control commands

#### 3.1 Command Parser
```python
# Modify amplifier-cli/amplifier_cli/main.py

class CommandParser:
    COMMANDS = {
        '/think': 'plan_mode',
        '/stop': 'halt_execution',
        '/save': 'save_transcript',
        '/status': 'show_status',
        '/clear': 'clear_context'
    }
    
    def parse(self, input: str) -> tuple[str, dict]:
        if input.startswith('/'):
            parts = input.split(maxsplit=1)
            command = parts[0]
            args = parts[1] if len(parts) > 1 else ''
            
            if command in self.COMMANDS:
                return self.COMMANDS[command], {'args': args}
        
        return 'prompt', {'text': input}
```

#### 3.2 Plan Mode Implementation
```python
# Hook-based approach for read-only mode
class PlanModeHook:
    def __init__(self):
        self.plan_mode = False
    
    async def on_tool_pre(self, event: str, data: dict) -> HookResult:
        if self.plan_mode:
            tool_name = data['tool']
            # Deny write operations in plan mode
            if tool_name in ['write', 'edit', 'bash']:
                return HookResult(
                    action='deny',
                    reason='Write operations disabled in Plan Mode'
                )
        return HookResult(action='continue')
```

**Deliverable**: Working `/think`, `/stop`, `/save` commands

### Phase 4: Context Persistence (Days 9-10)
**Goal**: Enable cross-session memory

#### 4.1 Memory Manager Module
```python
# New: amplifier-mod-context-persistent/__init__.py

class PersistentContextManager:
    """Context manager with memory file support"""
    
    async def initialize(self, memory_files: list[str]):
        """Load memory files at session start"""
        for file_path in memory_files:
            if Path(file_path).exists():
                content = Path(file_path).read_text()
                await self.add_message({
                    'role': 'system',
                    'content': f'[Memory from {file_path}]\n{content}'
                })
    
    async def save_memories(self):
        """Update memory files at session end"""
        # Extract learnings and update CLAUDE.md
```

#### 4.2 Memory Hooks
```python
class MemoryHook:
    async def on_session_start(self, event, data):
        # Load memory files
        memory_files = self.config.get('memory', [])
        await self.load_memories(memory_files)
    
    async def on_session_end(self, event, data):
        # Save important learnings
        await self.save_learnings()
```

**Deliverable**: Persistent CLAUDE.md integration

### Phase 5: Safety & Polish (Days 11-12)
**Goal**: Production-ready safety features

#### 5.1 Interactive Approval System
```python
# Enhance BashTool with real approval
class InteractiveApproval:
    async def get_approval(self, command: str) -> bool:
        # For CLI: Use click.confirm()
        # For API: Return approval request to client
        # For testing: Check config flags
```

#### 5.2 Security Hooks
- File modification tracking
- Command audit logging
- Resource limit enforcement

### Phase 6: Testing & Migration (Days 13-14)
**Goal**: Validate parity and migrate existing workflows

#### 6.1 Feature Parity Tests
- Port Claude Code test scenarios
- Validate each tool produces equivalent output
- Test sub-agent delegation flows
- Verify memory persistence

#### 6.2 Migration Tools
```bash
# Script to migrate from Claude Code setup
./scripts/migrate-from-claude-code.sh
# - Convert .clinerules to config.toml
# - Import existing CLAUDE.md
# - Map custom commands to hooks
```

## Quick Start Actions (Do Today)

### 1. **Complete EditTool** (30 minutes)
```python
# In amplifier-mod-tool-filesystem/__init__.py
# Replace the EditTool.execute stub with full implementation
# Use the diff generation that's already partially there
```

### 2. **Add Essential Search Tools** (2 hours)
```python
# Create amplifier-mod-tool-search module
# Implement Grep, Glob, Find tools
# These enable the AI to navigate codebases
```

### 3. **Create TaskTool Skeleton** (1 hour)
```python
# Create amplifier-mod-tool-task module
# Start with synchronous sub-session execution
# This unblocks multi-step reasoning
```

## Success Metrics

- **Week 1**: 10+ working tools, basic sub-agent support
- **Week 2**: Full command interface, persistent memory, safety features
- **Week 3**: Complete testing, migration tools, production deployment

## Configuration Template for Testing

```toml
# amplifier-parity.toml
[provider]
name = "anthropic"
model = "claude-sonnet-4-5"

[modules]
orchestrator = "loop-basic"
context = "context-persistent"  # New persistent context
tools = [
    "filesystem",  # Now includes Glob, Grep, etc.
    "bash",
    "web",
    "task",  # New task delegation tool
    "search"  # New search tools
]
agents = [
    "architect",
    "researcher",
    "implementer"
]
hooks = [
    "backup",
    "memory",  # New memory persistence
    "security",  # New security checks
    "plan-mode"  # New command support
]

[memory]
files = [
    "./CLAUDE.md",
    "./.amplifier/PROJECT.md"
]

[commands]
enabled = true
prefix = "/"
```

## Risk Mitigation

1. **Incremental Testing**: Each phase includes tests before moving forward
2. **Backward Compatibility**: Keep `loop-basic` as fallback orchestrator
3. **Feature Flags**: Use config to enable/disable new features
4. **Parallel Development**: Multiple developers can work on different modules

## Conclusion

The path to feature parity is clear and achievable within 2-3 weeks. The modular architecture makes it possible to add capabilities incrementally without disrupting the stable core. Priority should be on **tools and sub-agents first**, as these unlock the most autonomous coding capabilities, followed by commands and persistence for the full Claude Code experience.

Start with the Quick Start Actions today to immediately improve capabilities while the larger features are developed in parallel.
