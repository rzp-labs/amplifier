# Amplifier Priority Implementation Guide

## Component 1: TaskTool for Sub-Agent Support

### Full Implementation Specification

```python
# File: amplifier-mod-tool-task/amplifier_mod_tool_task/__init__.py

import asyncio
import logging
from typing import Any, Optional
from amplifier_core import ModuleCoordinator, ToolResult, AmplifierSession
from amplifier_core.utils import create_sub_context

logger = logging.getLogger(__name__)

async def mount(coordinator: ModuleCoordinator, config: dict[str, Any] | None = None):
    """Mount the task delegation tool."""
    config = config or {}
    tool = TaskTool(coordinator, config)
    await coordinator.mount("tools", tool, name=tool.name)
    logger.info("Mounted TaskTool")
    return

class TaskTool:
    """
    Delegate complex tasks to sub-agents.
    Maintains isolated context while preserving key learnings.
    """
    
    name = "task"
    description = "Delegate a subtask to a specialized agent or sub-session"
    
    def __init__(self, coordinator: ModuleCoordinator, config: dict[str, Any]):
        self.coordinator = coordinator
        self.config = config
        self.max_depth = config.get("max_depth", 3)  # Prevent infinite recursion
        self.inherit_tools = config.get("inherit_tools", True)
        self.inherit_memory = config.get("inherit_memory", False)
        
    async def execute(self, input: dict[str, Any]) -> ToolResult:
        """
        Execute a subtask in an isolated context.
        
        Args:
            input: {
                "task": str - Description of the task to execute
                "agent": Optional[str] - Specific agent type to use
                "context": Optional[str] - Additional context for the task
                "max_iterations": Optional[int] - Override max iterations
                "return_transcript": Optional[bool] - Include full transcript
            }
        """
        task_description = input.get("task")
        if not task_description:
            return ToolResult(
                success=False,
                error={"message": "Task description is required"}
            )
        
        agent_type = input.get("agent", "default")
        additional_context = input.get("context", "")
        max_iterations = input.get("max_iterations", 20)
        return_transcript = input.get("return_transcript", False)
        
        # Check recursion depth
        current_depth = self._get_current_depth()
        if current_depth >= self.max_depth:
            return ToolResult(
                success=False,
                error={"message": f"Maximum task depth ({self.max_depth}) reached"}
            )
        
        try:
            # Emit spawn event
            hooks = self.coordinator.get("hooks")
            if hooks:
                await hooks.emit("agent:spawn", {
                    "task": task_description,
                    "agent": agent_type,
                    "depth": current_depth + 1
                })
            
            # Build sub-session configuration
            sub_config = self._build_sub_config(
                agent_type,
                max_iterations,
                current_depth + 1
            )
            
            # Create and initialize sub-session
            sub_session = AmplifierSession(sub_config)
            await sub_session.initialize()
            
            # Prepare the prompt with context
            prompt = self._prepare_prompt(
                task_description,
                additional_context,
                agent_type
            )
            
            # Execute the task
            logger.info(f"Executing subtask at depth {current_depth + 1}: {task_description[:100]}...")
            result = await sub_session.execute(prompt)
            
            # Clean up sub-session
            await sub_session.cleanup()
            
            # Emit complete event
            if hooks:
                await hooks.emit("agent:complete", {
                    "task": task_description,
                    "agent": agent_type,
                    "success": True,
                    "depth": current_depth + 1
                })
            
            # Prepare output
            output = {
                "result": result,
                "agent_used": agent_type,
                "depth": current_depth + 1
            }
            
            if return_transcript:
                # Get transcript from sub-session context
                output["transcript"] = await self._get_transcript(sub_session)
            
            return ToolResult(
                success=True,
                output=output
            )
            
        except Exception as e:
            logger.error(f"Task execution failed: {e}")
            
            # Emit failure event
            if hooks:
                await hooks.emit("agent:complete", {
                    "task": task_description,
                    "agent": agent_type,
                    "success": False,
                    "error": str(e),
                    "depth": current_depth + 1
                })
            
            return ToolResult(
                success=False,
                error={"message": f"Task failed: {str(e)}"}
            )
    
    def _get_current_depth(self) -> int:
        """Determine current recursion depth from context."""
        # This would check context or environment for depth indicator
        # For now, return 0 (can be enhanced to track via context)
        return 0
    
    def _build_sub_config(
        self, 
        agent_type: str, 
        max_iterations: int,
        depth: int
    ) -> dict[str, Any]:
        """Build configuration for sub-session."""
        
        # Start with current session's base config
        base_config = {
            "session": {
                "orchestrator": "loop-basic",
                "context": "context-simple"
            },
            "context": {
                "config": {
                    "max_tokens": 50_000,  # Smaller context for subtasks
                    "compact_threshold": 0.9
                }
            },
            "providers": [],
            "tools": [],
            "agents": [],
            "hooks": []
        }
        
        # Copy providers from parent
        providers = self.coordinator.get("providers")
        if providers:
            for name, provider in providers.items():
                base_config["providers"].append({
                    "module": f"provider-{name}",
                    "instance": provider  # Reuse instance
                })
        
        # Selectively copy tools
        if self.inherit_tools:
            tools = self.coordinator.get("tools")
            if tools:
                for name, tool in tools.items():
                    # Don't include 'task' tool to prevent deep recursion
                    if name != "task" or depth < self.max_depth - 1:
                        base_config["tools"].append({
                            "module": f"tool-{name}",
                            "instance": tool  # Reuse instance
                        })
        
        # Configure for specific agent type
        if agent_type != "default":
            agent_config = self._get_agent_config(agent_type)
            if agent_config:
                base_config.update(agent_config)
        
        # Add depth indicator
        base_config["metadata"] = {
            "task_depth": depth,
            "parent_session": True
        }
        
        # Set iteration limit
        if "orchestrator_config" not in base_config:
            base_config["orchestrator_config"] = {}
        base_config["orchestrator_config"]["max_iterations"] = max_iterations
        
        return base_config
    
    def _prepare_prompt(
        self, 
        task: str, 
        context: str,
        agent_type: str
    ) -> str:
        """Prepare the prompt for the sub-agent."""
        
        prompt_parts = []
        
        # Add agent-specific instructions
        if agent_type == "architect":
            prompt_parts.append(
                "You are executing as a specialized architect agent. "
                "Focus on system design with ruthless simplicity."
            )
        elif agent_type == "researcher":
            prompt_parts.append(
                "You are executing as a research agent. "
                "Gather comprehensive information and provide detailed analysis."
            )
        elif agent_type == "implementer":
            prompt_parts.append(
                "You are executing as an implementation agent. "
                "Focus on writing clean, functional code that solves the problem."
            )
        
        # Add context if provided
        if context:
            prompt_parts.append(f"Context:\n{context}")
        
        # Add the task
        prompt_parts.append(f"Task:\n{task}")
        
        # Add completion instruction
        prompt_parts.append(
            "\nComplete this task to the best of your ability. "
            "Be thorough but concise in your response."
        )
        
        return "\n\n".join(prompt_parts)
    
    def _get_agent_config(self, agent_type: str) -> Optional[dict[str, Any]]:
        """Get specific configuration for an agent type."""
        
        agent_configs = {
            "architect": {
                "orchestrator_config": {
                    "temperature": 0.7,
                    "system_prompt": "You are a zen architect valuing simplicity."
                }
            },
            "researcher": {
                "tools": [
                    {"module": "tool-web"},
                    {"module": "tool-search"}
                ]
            },
            "implementer": {
                "tools": [
                    {"module": "tool-filesystem"},
                    {"module": "tool-bash"}
                ],
                "orchestrator_config": {
                    "temperature": 0.3  # Lower temp for code generation
                }
            },
            "reviewer": {
                "tools": [
                    {"module": "tool-filesystem"},
                    {"module": "tool-grep"}
                ],
                "orchestrator_config": {
                    "system_prompt": "You are a code reviewer. Find issues and suggest improvements."
                }
            }
        }
        
        return agent_configs.get(agent_type)
    
    async def _get_transcript(self, session: AmplifierSession) -> list[dict]:
        """Extract transcript from completed session."""
        try:
            context = session.coordinator.get("context")
            if context:
                messages = await context.get_messages()
                return messages
        except Exception as e:
            logger.warning(f"Could not get transcript: {e}")
        return []
```

### pyproject.toml for TaskTool

```toml
[project]
name = "amplifier-mod-tool-task"
version = "0.1.0"
description = "Task delegation tool for Amplifier sub-agents"
dependencies = [
    "amplifier-core>=0.1.0"
]

[project.entry-points."amplifier.modules"]
tool-task = "amplifier_mod_tool_task:mount"
```

## Component 2: Essential Search Tools

### GrepTool Implementation

```python
# File: amplifier-mod-tool-search/amplifier_mod_tool_search/grep.py

import asyncio
import re
from pathlib import Path
from typing import Any, List, Tuple
from amplifier_core import ToolResult

class GrepTool:
    """Search file contents with regex patterns."""
    
    name = "grep"
    description = "Search for patterns in files"
    
    def __init__(self, config: dict[str, Any]):
        self.config = config
        self.max_results = config.get("max_results", 100)
        self.max_file_size = config.get("max_file_size", 10 * 1024 * 1024)  # 10MB
        self.allowed_paths = config.get("allowed_paths", ["."])
        
    async def execute(self, input: dict[str, Any]) -> ToolResult:
        """
        Search for pattern in files.
        
        Args:
            input: {
                "pattern": str - Regex pattern to search
                "path": str - File or directory to search
                "recursive": bool - Search recursively in directories
                "ignore_case": bool - Case-insensitive search
                "include": Optional[str] - File pattern to include (e.g., "*.py")
                "exclude": Optional[str] - File pattern to exclude
                "context_lines": int - Number of context lines to show
            }
        """
        pattern = input.get("pattern")
        search_path = input.get("path", ".")
        recursive = input.get("recursive", True)
        ignore_case = input.get("ignore_case", False)
        include_pattern = input.get("include", "*")
        exclude_pattern = input.get("exclude", "")
        context_lines = input.get("context_lines", 0)
        
        if not pattern:
            return ToolResult(
                success=False,
                error={"message": "Pattern is required"}
            )
        
        try:
            # Compile regex
            flags = re.IGNORECASE if ignore_case else 0
            regex = re.compile(pattern, flags)
            
            # Find files to search
            path = Path(search_path)
            if not path.exists():
                return ToolResult(
                    success=False,
                    error={"message": f"Path not found: {search_path}"}
                )
            
            files_to_search = self._find_files(
                path, 
                recursive, 
                include_pattern, 
                exclude_pattern
            )
            
            # Search files
            results = []
            for file_path in files_to_search:
                file_results = await self._search_file(
                    file_path, 
                    regex, 
                    context_lines
                )
                if file_results:
                    results.extend(file_results)
                    
                if len(results) >= self.max_results:
                    break
            
            # Format results
            output = {
                "pattern": pattern,
                "matches": len(results),
                "results": results[:self.max_results]
            }
            
            if len(results) > self.max_results:
                output["truncated"] = True
                output["total_matches"] = len(results)
            
            return ToolResult(
                success=True,
                output=output
            )
            
        except re.error as e:
            return ToolResult(
                success=False,
                error={"message": f"Invalid regex pattern: {e}"}
            )
        except Exception as e:
            return ToolResult(
                success=False,
                error={"message": f"Search failed: {e}"}
            )
    
    def _find_files(
        self, 
        path: Path, 
        recursive: bool,
        include_pattern: str,
        exclude_pattern: str
    ) -> List[Path]:
        """Find files to search."""
        files = []
        
        if path.is_file():
            return [path]
        
        pattern = "**/*" if recursive else "*"
        for file_path in path.glob(pattern):
            if not file_path.is_file():
                continue
                
            # Check file size
            if file_path.stat().st_size > self.max_file_size:
                continue
            
            # Check include pattern
            if include_pattern != "*":
                if not file_path.match(include_pattern):
                    continue
            
            # Check exclude pattern
            if exclude_pattern:
                if file_path.match(exclude_pattern):
                    continue
            
            # Skip binary files (simple heuristic)
            try:
                with open(file_path, 'rb') as f:
                    chunk = f.read(8192)
                    if b'\x00' in chunk:
                        continue  # Skip binary files
            except:
                continue
            
            files.append(file_path)
        
        return files
    
    async def _search_file(
        self, 
        file_path: Path, 
        regex: re.Pattern,
        context_lines: int
    ) -> List[dict]:
        """Search a single file."""
        results = []
        
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                lines = f.readlines()
            
            for i, line in enumerate(lines, 1):
                if regex.search(line):
                    # Get context
                    start = max(0, i - context_lines - 1)
                    end = min(len(lines), i + context_lines)
                    
                    context = []
                    for j in range(start, end):
                        context.append({
                            "line_no": j + 1,
                            "content": lines[j].rstrip(),
                            "is_match": j == i - 1
                        })
                    
                    results.append({
                        "file": str(file_path),
                        "line_no": i,
                        "content": line.rstrip(),
                        "context": context if context_lines > 0 else None
                    })
            
        except Exception as e:
            # Log but don't fail entirely
            pass
        
        return results
```

### GlobTool Implementation

```python
# File: amplifier-mod-tool-search/amplifier_mod_tool_search/glob.py

from pathlib import Path
from typing import Any, List
from amplifier_core import ToolResult

class GlobTool:
    """Find files matching glob patterns."""
    
    name = "glob"
    description = "Find files matching a pattern"
    
    def __init__(self, config: dict[str, Any]):
        self.config = config
        self.max_results = config.get("max_results", 1000)
        self.allowed_paths = config.get("allowed_paths", ["."])
    
    async def execute(self, input: dict[str, Any]) -> ToolResult:
        """
        Find files matching pattern.
        
        Args:
            input: {
                "pattern": str - Glob pattern (e.g., "**/*.py")
                "path": Optional[str] - Base path to search from
                "type": Optional[str] - Filter by type: "file", "dir", "any"
                "exclude": Optional[List[str]] - Patterns to exclude
            }
        """
        pattern = input.get("pattern")
        base_path = input.get("path", ".")
        filter_type = input.get("type", "any")
        exclude_patterns = input.get("exclude", [])
        
        if not pattern:
            return ToolResult(
                success=False,
                error={"message": "Pattern is required"}
            )
        
        try:
            path = Path(base_path)
            if not path.exists():
                return ToolResult(
                    success=False,
                    error={"message": f"Path not found: {base_path}"}
                )
            
            # Find matching paths
            matches = []
            for match_path in path.glob(pattern):
                # Apply type filter
                if filter_type == "file" and not match_path.is_file():
                    continue
                elif filter_type == "dir" and not match_path.is_dir():
                    continue
                
                # Apply exclusions
                excluded = False
                for exclude_pattern in exclude_patterns:
                    if match_path.match(exclude_pattern):
                        excluded = True
                        break
                
                if not excluded:
                    matches.append({
                        "path": str(match_path),
                        "type": "file" if match_path.is_file() else "dir",
                        "size": match_path.stat().st_size if match_path.is_file() else None
                    })
                
                if len(matches) >= self.max_results:
                    break
            
            return ToolResult(
                success=True,
                output={
                    "pattern": pattern,
                    "base_path": str(path),
                    "count": len(matches),
                    "matches": matches
                }
            )
            
        except Exception as e:
            return ToolResult(
                success=False,
                error={"message": f"Glob search failed: {e}"}
            )
```

## Component 3: Command System Implementation

### Enhanced CLI with Commands

```python
# File: amplifier-cli/amplifier_cli/commands.py

from typing import Optional, Tuple, Dict, Any
import re

class CommandProcessor:
    """Process slash commands and special directives."""
    
    COMMANDS = {
        '/think': {
            'action': 'enable_plan_mode',
            'description': 'Enable read-only planning mode'
        },
        '/do': {
            'action': 'disable_plan_mode', 
            'description': 'Exit plan mode and allow modifications'
        },
        '/stop': {
            'action': 'halt_execution',
            'description': 'Stop current execution'
        },
        '/save': {
            'action': 'save_transcript',
            'description': 'Save conversation transcript'
        },
        '/status': {
            'action': 'show_status',
            'description': 'Show session status'
        },
        '/clear': {
            'action': 'clear_context',
            'description': 'Clear conversation context'
        },
        '/help': {
            'action': 'show_help',
            'description': 'Show available commands'
        },
        '/config': {
            'action': 'show_config',
            'description': 'Show current configuration'
        },
        '/tools': {
            'action': 'list_tools',
            'description': 'List available tools'
        }
    }
    
    def __init__(self, session):
        self.session = session
        self.plan_mode = False
        self.halted = False
    
    def process_input(self, user_input: str) -> Tuple[str, Dict[str, Any]]:
        """
        Process user input and extract commands.
        
        Returns:
            (action, data) tuple
        """
        # Check for commands
        if user_input.startswith('/'):
            parts = user_input.split(maxsplit=1)
            command = parts[0].lower()
            args = parts[1] if len(parts) > 1 else ''
            
            if command in self.COMMANDS:
                cmd_info = self.COMMANDS[command]
                return cmd_info['action'], {'args': args, 'command': command}
            else:
                return 'unknown_command', {'command': command}
        
        # Regular prompt
        return 'prompt', {'text': user_input, 'plan_mode': self.plan_mode}
    
    async def handle_command(self, action: str, data: Dict[str, Any]) -> str:
        """Handle a command action."""
        
        if action == 'enable_plan_mode':
            self.plan_mode = True
            self._configure_plan_mode(True)
            return "✓ Plan Mode enabled - all modifications disabled"
        
        elif action == 'disable_plan_mode':
            self.plan_mode = False
            self._configure_plan_mode(False)
            return "✓ Plan Mode disabled - modifications enabled"
        
        elif action == 'halt_execution':
            self.halted = True
            # Signal orchestrator to stop
            if hasattr(self.session, 'halt'):
                await self.session.halt()
            return "✓ Execution halted"
        
        elif action == 'save_transcript':
            path = await self._save_transcript(data.get('args', ''))
            return f"✓ Transcript saved to {path}"
        
        elif action == 'show_status':
            status = await self._get_status()
            return status
        
        elif action == 'clear_context':
            await self._clear_context()
            return "✓ Context cleared"
        
        elif action == 'show_help':
            return self._format_help()
        
        elif action == 'show_config':
            return await self._get_config_display()
        
        elif action == 'list_tools':
            return await self._list_tools()
        
        elif action == 'unknown_command':
            return f"Unknown command: {data['command']}. Use /help for available commands."
        
        else:
            return f"Unhandled action: {action}"
    
    def _configure_plan_mode(self, enabled: bool):
        """Configure session for plan mode."""
        # Add/remove plan mode hook
        hooks = self.session.coordinator.get("hooks")
        if hooks:
            if enabled:
                # Register plan mode hook that denies write operations
                def plan_mode_hook(event, data):
                    tool_name = data.get('tool')
                    if tool_name in ['write', 'edit', 'bash', 'task']:
                        return {
                            'action': 'deny',
                            'reason': 'Write operations disabled in Plan Mode'
                        }
                    return {'action': 'continue'}
                
                hooks.register('tool:pre', plan_mode_hook, 
                             priority=0, name='plan_mode')
            else:
                # Unregister plan mode hook
                hooks.unregister('tool:pre', name='plan_mode')
    
    async def _save_transcript(self, filename: str) -> str:
        """Save current transcript."""
        from datetime import datetime
        from pathlib import Path
        import json
        
        # Default filename if not provided
        if not filename:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"transcript_{timestamp}.json"
        
        # Get messages from context
        context = self.session.coordinator.get("context")
        if context:
            messages = await context.get_messages()
            
            # Save to file
            path = Path(".amplifier/transcripts") / filename
            path.parent.mkdir(parents=True, exist_ok=True)
            
            with open(path, 'w') as f:
                json.dump({
                    "timestamp": datetime.now().isoformat(),
                    "messages": messages,
                    "config": self.session.config
                }, f, indent=2)
            
            return str(path)
        
        return "No transcript available"
    
    async def _get_status(self) -> str:
        """Get session status information."""
        lines = ["Session Status:"]
        
        # Plan mode status
        lines.append(f"  Plan Mode: {'ON' if self.plan_mode else 'OFF'}")
        
        # Context size
        context = self.session.coordinator.get("context")
        if context:
            messages = await context.get_messages()
            lines.append(f"  Messages: {len(messages)}")
        
        # Active providers
        providers = self.session.coordinator.get("providers")
        if providers:
            lines.append(f"  Providers: {', '.join(providers.keys())}")
        
        # Available tools
        tools = self.session.coordinator.get("tools")
        if tools:
            lines.append(f"  Tools: {len(tools)}")
        
        return "\n".join(lines)
    
    async def _clear_context(self):
        """Clear the conversation context."""
        context = self.session.coordinator.get("context")
        if context:
            await context.clear()
    
    def _format_help(self) -> str:
        """Format help text."""
        lines = ["Available Commands:"]
        for cmd, info in self.COMMANDS.items():
            lines.append(f"  {cmd:<12} - {info['description']}")
        return "\n".join(lines)
    
    async def _get_config_display(self) -> str:
        """Display current configuration."""
        import json
        config_str = json.dumps(self.session.config, indent=2)
        return f"Current Configuration:\n{config_str}"
    
    async def _list_tools(self) -> str:
        """List available tools."""
        tools = self.session.coordinator.get("tools")
        if not tools:
            return "No tools available"
        
        lines = ["Available Tools:"]
        for name, tool in tools.items():
            desc = getattr(tool, 'description', 'No description')
            lines.append(f"  {name:<20} - {desc}")
        
        return "\n".join(lines)
```

## Installation Instructions

### 1. Create the new modules

```bash
# Create task tool module
cd amplifier-dev
./scripts/create-module.sh tool-task

# Create search tools module  
./scripts/create-module.sh tool-search

# Install in development mode
pip install -e amplifier-mod-tool-task/
pip install -e amplifier-mod-tool-search/
```

### 2. Update configuration

```toml
# Add to your config file
[[tools]]
module = "tool-task"
config = {
    max_depth = 3,
    inherit_tools = true
}

[[tools]]
module = "tool-search"
config = {
    max_results = 100
}
```

### 3. Test the new capabilities

```python
# Test script
from amplifier_core import AmplifierSession

config = {
    "providers": [{"module": "provider-anthropic"}],
    "tools": [
        {"module": "tool-filesystem"},
        {"module": "tool-task"},
        {"module": "tool-search"}
    ]
}

session = AmplifierSession(config)
await session.initialize()

# Test task delegation
result = await session.execute(
    "Create a task to analyze the codebase structure and then "
    "create another task to document the findings"
)
```

## Next Steps After Implementation

1. **Add Integration Tests**: Create test cases for each new tool
2. **Performance Optimization**: Profile sub-agent spawning overhead
3. **Enhanced Agent Types**: Add more specialized agents (debugger, optimizer, etc.)
4. **Memory Persistence**: Implement the PersistentContextManager
5. **Streaming Support**: Complete the streaming orchestrator for real-time output

This implementation provides the critical missing pieces for autonomous coding capability while maintaining the clean modular architecture of the new system.
