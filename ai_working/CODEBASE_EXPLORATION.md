# Amplifier Codebase Exploration - Comprehensive Overview

## Executive Summary

Amplifier is a sophisticated metacognitive AI development system built on the philosophy of ruthless simplicity and modular architecture. It enables developers to create reusable AI tools by describing thinking processes rather than implementing code. The system orchestrates AI work through:

1. **Specialized agents** (44+ available) for focused tasks
2. **Modular tool architecture** following "bricks and studs" philosophy
3. **Claude Code SDK integration** for programmatic AI access
4. **MCP servers** for external system integration
5. **Knowledge synthesis** from documents
6. **State management** for resumable pipelines
7. **Defensive patterns** for reliable LLM integration

---

## 1. OVERALL ARCHITECTURE

### 1.1 Project Structure

```
amplifier/
├── amplifier/                    # Core Python module (AI/automation capabilities)
│   ├── ccsdk_toolkit/           # Claude Code SDK wrapper & utilities
│   ├── knowledge_synthesis/      # Extract knowledge from documents
│   ├── knowledge/                # Graph-based knowledge querying
│   ├── knowledge_integration/    # Integrate extracted knowledge
│   ├── knowledge_mining/         # Mining knowledge from sources
│   ├── memory/                   # Persistent memory system
│   ├── extraction/               # Extract memories from conversations
│   ├── search/                   # Semantic search capabilities
│   ├── validation/               # Validate claims against knowledge
│   ├── synthesis/                # Synthesis operations
│   ├── content_loader/           # Load content from various sources
│   ├── config/                   # Central path & configuration management
│   ├── utils/                    # Shared utilities (logging, file I/O)
│   └── smoke_tests/              # Integration testing framework
│
├── scenarios/                    # Production-ready AI tools (exemplars)
│   ├── blog_writer/              # Transform ideas into styled blog posts (1,866 LOC)
│   ├── tips_synthesizer/         # Synthesize scattered tips into guides
│   ├── article_illustrator/       # Generate contextual AI illustrations
│   ├── transcribe/               # Audio/video transcription
│   └── web_to_md/                # Convert web content to markdown
│
├── .claude/agents/               # 44+ specialized agents for different tasks
│   ├── zen-architect.md          # Design & architecture expert
│   ├── modular-builder.md        # Implementation from specifications
│   ├── integration-specialist.md # External system integration
│   ├── bug-hunter.md             # Find & diagnose issues
│   ├── test-coverage.md          # Testing strategy expert
│   ├── amplifier-cli-architect.md # CLI tool design expert
│   ├── knowledge-archaeologist.md # Deep knowledge mining
│   └── [37 more specialized agents]
│
├── ai_context/                   # AI context & documentation
│   ├── IMPLEMENTATION_PHILOSOPHY.md   # Ruthless simplicity principles
│   ├── MODULAR_DESIGN_PHILOSOPHY.md   # Bricks & studs approach
│   ├── claude_code/                   # Claude Code SDK documentation
│   └── generated/                     # Generated context files
│
├── ai_working/                   # AI session working directory
│   ├── decisions/                # Decision records (architectural choices)
│   └── [session working files]
│
├── docs/                         # User documentation
│   ├── CREATE_YOUR_OWN_TOOLS.md
│   ├── WORKSPACE_PATTERN.md
│   ├── WORKTREE_GUIDE.md
│   └── THIS_IS_THE_WAY.md
│
├── .mcp.json                     # MCP server configurations
├── CLAUDE.md                     # Claude Code-specific instructions
├── AGENTS.md                     # AI assistant guidance
├── DISCOVERIES.md                # Solutions to non-obvious problems
└── pyproject.toml                # Python dependencies & configuration
```

### 1.2 Core Design Philosophy

**Three foundational documents guide all development:**

1. **IMPLEMENTATION_PHILOSOPHY.md**
   - Ruthless simplicity (KISS taken to heart)
   - Minimize abstractions
   - Start minimal, grow as needed
   - Trust in emergence
   - Pragmatic approach to library vs. custom code

2. **MODULAR_DESIGN_PHILOSOPHY.md** ("Bricks & Studs")
   - "Bricks" = self-contained modules with one responsibility
   - "Studs" = public contracts (interfaces) others connect to
   - Regeneratable modules (rebuild without breaking connections)
   - AI-friendly specs (~150 lines per module)
   - Enables parallel experimentation and AI-assisted rebuilds

3. **DISCOVERIES.md** (Institutional Memory)
   - Documents non-obvious problems solved
   - Captures root causes and solutions
   - Prevention strategies for future issues
   - Examples: cloud sync I/O errors, DevContainer setup, LLM response handling

### 1.3 Technology Stack

**Core Languages:**
- Python 3.11+ (main development)
- Node.js/pnpm (dev tools, some CLI components)
- Bash (scripting & Makefile)

**Key Dependencies:**
- `claude-code-sdk` - Programmatic Claude Code access
- `pydantic` - Data validation & settings
- `pydantic-ai` - LLM integration framework
- `click` - CLI tool framework
- `networkx` - Knowledge graph construction
- `langchain` - LLM chains & integrations
- `openai`, `anthropic` - LLM provider SDKs
- `sentence-transformers` - Semantic search embeddings
- `aiohttp`, `httpx` - Async HTTP clients

---

## 2. MCP INTEGRATION PATTERNS

### 2.1 Configured MCP Servers (.mcp.json)

```json
{
  "mcpServers": {
    "browser-use": {
      "command": "uvx",
      "args": ["browser-use[cli]==0.5.10", "--mcp"],
      "env": { "OPENAI_API_KEY": "${OPENAI_API_KEY}" }
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    },
    "deepwiki": {
      "type": "http",
      "url": "https://mcp.deepwiki.com/mcp"
    },
    "repomix": {
      "command": "npx",
      "args": ["-y", "repomix", "--mcp"]
    },
    "zen": {
      "command": "uvx",
      "args": ["--from", "git+https://github.com/BeehiveInnovations/zen-mcp-server.git", "zen-mcp-server"]
    }
  }
}
```

### 2.2 MCP Server Usage Patterns

**Five MCP servers currently integrated:**

1. **browser-use** - Web automation & content extraction
2. **context7** - Library documentation searching
3. **deepwiki** - Repository documentation queries
4. **repomix** - Repository content aggregation
5. **zen** - Specialized knowledge tools

### 2.3 Integration Philosophy

From AGENTS.md:
- **MCP for service communication** - Use when connecting to external services
- **Direct integration** - Avoid unnecessary adapter layers
- **Pragmatic error handling** - Trust systems appropriately, handle failures gracefully
- **Minimal wrappers** - Use MCP tools as intended

**Example: Content Extraction Pattern**
```python
# Rather than building elaborate wrapper layers:
# 1. Use browser-use for web content extraction
# 2. Use repomix for repository aggregation
# 3. Pass results directly to knowledge extraction pipeline
# 4. Store in knowledge graph for querying
```

---

## 3. AGENT/ORCHESTRATION PATTERNS

### 3.1 Available Agents (44 Total)

**Categories:**

**Development Agents (7):**
- `zen-architect` - Architecture design & planning
- `modular-builder` - Implementation from specs
- `architecture-reviewer` - Code architecture review
- `bug-hunter` - Issue diagnosis & finding
- `test-coverage` - Testing strategy & coverage
- `refactor-architect` - Refactoring expert
- `integration-specialist` - External system integration

**Knowledge Synthesis Agents (8):**
- `triage-specialist` - Task prioritization
- `analysis-expert` - Deep problem analysis
- `synthesis-master` - Knowledge synthesis
- `content-researcher` - Research methodologies
- `concept-extractor` - Concept identification
- `insight-synthesizer` - Insight generation
- `knowledge-archaeologist` - Historical knowledge mining
- `visualization-architect` - Data visualization expert

**Meta Agents (3):**
- `subagent-architect` - Create new specialized agents
- `amplifier-cli-architect` - CLI tool design expert
- `module-intent-architect` - Module purpose alignment

**Additional Specialized Agents (26+):**
- Domain-specific experts (security, performance, etc.)
- Specialized pattern matchers
- Focused optimizers

### 3.2 Agent Invocation Pattern

**Proactive Usage Philosophy:**
Agents are not "tools to request" but "specialists to delegate to." The default approach is to use agents proactively when their expertise matches the task.

```python
# Pattern: Orchestrator delegates to specialized agents
# Rather than trying to do everything with one general model:

Task: "Implement a caching layer"
↓
Orchestrator recognizes architecture decision needed
↓
Delegates to zen-architect PROACTIVELY (ANALYZE mode)
↓
zen-architect designs specifications (ARCHITECT mode)
↓
Orchestrator delegates to modular-builder
↓
modular-builder implements from specs
↓
Orchestrator delegates to bug-hunter
↓
bug-hunter finds issues
↓
Orchestrator validates results
```

### 3.3 Orchestration Infrastructure

**No explicit "orchestrator agent" exists yet** - this is what needs to be designed.

Current orchestration is:
1. **Manual** - Humans explicitly invoke agents
2. **Sequential** - One agent at a time
3. **Linear** - Follow straightforward task flows
4. **Human-guided** - User decides agent sequence

**Needed improvements:**
- Automatic task decomposition
- Parallel agent coordination
- Context management across agents
- Result synthesis and validation
- Intelligent sequencing decisions

### 3.4 Agent Design Pattern (Example: zen-architect)

```yaml
name: zen-architect
description: Master designer for architecture, planning, and code review
model: inherit  # Uses Claude's capability

Operating Modes (context-determined):
1. ANALYZE MODE
   - Break down problems
   - Generate solution options
   - Create implementation specs
   - Trade-off analysis

2. ARCHITECT MODE  
   - System design
   - Module specification
   - Dependency mapping
   - Design patterns

3. REVIEW MODE
   - Code quality assessment
   - Philosophy compliance
   - Performance analysis
   - Recommendations
```

---

## 4. CLAUDE CODE SDK USAGE

### 4.1 CCSDK Toolkit Architecture

```
amplifier/ccsdk_toolkit/
├── core/              # Core SDK wrapper (foundation brick)
│   ├── session.py     # ClaudeSession main class
│   ├── models.py      # SessionOptions, SessionResponse
│   └── utils.py       # Utilities, check_claude_cli()
│
├── defensive/         # Battle-tested patterns for reliability
│   ├── llm_parsing.py     # parse_llm_json() - Extract JSON from any format
│   ├── prompt_isolation.py # isolate_prompt() - Prevent context contamination
│   ├── file_io.py         # write_json_with_retry() - Cloud sync aware
│   ├── retry_patterns.py  # retry_with_feedback() - Smart retry logic
│   └── pydantic_extraction.py # Structured LLM output extraction
│
├── logger/            # Structured logging
│   ├── logger.py      # ToolkitLogger class
│   └── models.py      # Log models
│
├── config/            # Configuration management
│   ├── models.py      # Agent & server configs
│   └── loader.py      # Config loading
│
├── sessions/          # Session persistence (not yet fully integrated)
│   └── [Session manager implementation]
│
├── cli/               # CLI tool builder
│   ├── builder.py     # CliBuilder for tool generation
│   └── templates.py   # Tool templates
│
├── examples/          # Production-ready example tools
│   ├── idea_synthesis/     # 4-stage knowledge synthesis pipeline
│   └── code_complexity_analyzer.py
│
└── templates/         # Tool generation templates
    └── tool_template.py    # Production-ready starting template
```

### 4.2 Core Session Usage

**Basic Pattern:**
```python
from amplifier.ccsdk_toolkit import ClaudeSession, SessionOptions

async def process_with_claude():
    options = SessionOptions(
        system_prompt="You are a helpful assistant",
        max_turns=1,  # Or None for natural completion
    )
    
    async with ClaudeSession(options) as session:
        response = await session.query("Your prompt here")
        
        if response.success:
            print(response.content)
        else:
            print(f"Error: {response.error}")
```

### 4.3 Defensive Patterns (Critical for Reliability)

**Three core patterns for LLM integration:**

#### 1. JSON Parsing from Any Format
```python
from amplifier.ccsdk_toolkit.defensive import parse_llm_json

# Handles: markdown blocks, explanations, malformed JSON
result = parse_llm_json(llm_response, default={})
```

**Solves:** LLMs wrap JSON in markdown, add explanations, return malformed data

#### 2. Context Isolation
```python
from amplifier.ccsdk_toolkit.defensive import isolate_prompt

# Prevents system instructions from leaking into response
safe_content = isolate_prompt(user_input)
```

**Solves:** System prompt contamination in generated content

#### 3. Cloud-Aware File I/O
```python
from amplifier.ccsdk_toolkit.defensive import write_json_with_retry, read_json_with_retry

# Handles OneDrive/Dropbox sync delays with exponential backoff
write_json_with_retry(data, path)
result = read_json_with_retry(path)
```

**Solves:** OSError errno 5 in WSL2 with OneDrive/cloud sync folders

### 4.4 Amplifier CLI Tools (Tool Template Pattern)

**Located:** `amplifier/ccsdk_toolkit/templates/tool_template.py`

**Comprehensive template includes:**
- ✓ Recursive file discovery (`**/*.ext`)
- ✓ Input validation & error handling
- ✓ Progress visibility & logging
- ✓ Resume capability
- ✓ Defensive LLM parsing
- ✓ Cloud sync-aware I/O

**Usage:** Copy template, modify sections, remove what you don't need

### 4.5 Example Tool: Idea Synthesis (Canonical CCSDK Example)

**Location:** `amplifier/ccsdk_toolkit/examples/idea_synthesis/`

**4-stage pipeline demonstrating:**
1. **Read stage** - Load markdown files
2. **Summarize stage** - Extract key ideas (~10s per file)
3. **Synthesize stage** - Generate synthesis (~3s per idea)
4. **Expand stage** - Elaborate on ideas (~45s per idea)

**Key patterns demonstrated:**
- Incremental processing (saves after each item)
- Defensive JSON parsing
- Progress tracking with logging
- Resume capability at any stage
- State persistence to JSON

**Performance:** 62.5% completion rate (5 of 8 ideas) before timeout with zero JSON parsing failures

---

## 5. SCENARIO TOOLS (EXEMPLARS)

### 5.1 Blog Writer Tool (Primary Exemplar - 1,866 LOC)

**Purpose:** Transform rough ideas into styled blog posts

**Architecture:**
```
blog_writer/
├── main.py              # BlogPostPipeline orchestrator
├── state.py             # StateManager for resumability
├── blog_writer/         # Draft generation
│   └── core.py
├── style_extractor/     # Learn author's voice
│   └── core.py
├── source_reviewer/     # Verify content accuracy
│   └── core.py
├── style_reviewer/      # Check style consistency
│   └── core.py
└── user_feedback/       # Handle user review input
    └── core.py
```

**Key Patterns:**

1. **Modular Components** - Each reviewer is independent module
2. **State Management** - Persistent state for resumability
3. **Iterative Refinement** - Feedback loops between stages
4. **Pipeline Orchestration** - Sequential stages with fallback
5. **File I/O** - Draft files saved per iteration

**Pipeline Stages:**
```
1. Initialize          ↓
2. Extract Style       ↓  (Load author's writings, profile voice)
3. Write Draft         ↓  (Generate initial version)
4. Source Review       ↓  (Verify against input)
5. Style Review        ↓  (Check voice consistency)
6. User Feedback       ↓  (Get human input)
7. Iterate or Complete ↓  (Max 10 iterations)
```

**Resume Capability:**
- Stage tracked in state
- Can resume at any stage
- All iteration history preserved
- Draft files named by iteration number

### 5.2 Other Scenario Tools

**tips_synthesizer** - Multi-stage knowledge synthesis
- Extract scattered tips
- Organize into categories
- Create cohesive document
- Review for completeness

**article_illustrator** - AI image generation for articles
- Analyze content for illustration points
- Generate image prompts
- Create images (multiple API support)
- Insert at optimal positions

**transcribe** - Audio/video transcription
**web_to_md** - Web content to markdown

### 5.3 How Scenario Tools Are Built

**Zero-code approach:**
1. **Describe the problem** - What are you trying to solve?
2. **Describe the thinking process** - How should the tool approach it?
3. **Amplifier builds it** - Complete implementation with all patterns

**No need to understand:**
- Async/await patterns
- State management
- File I/O error handling
- Retry logic
- CLI integration

---

## 6. CONFIGURATION & EXTENSION

### 6.1 Configuration Architecture

**Single Source of Truth Principle:**

Every configuration setting has exactly ONE authoritative location:

```
pyproject.toml (primary source)
    ├── project metadata
    ├── dependencies
    ├── [tool.pyright]
    ├── [tool.ruff]
    └── other tool configs
         ↑
         ├── Referenced by: VSCode settings.json
         ├── Referenced by: Makefile
         └── Referenced by: Python config modules
```

**Path Configuration:**
```python
from amplifier.config import paths

# All paths resolve through centralized config
data_dir = paths.data_dir              # .data/
content_dirs = paths.content_dirs      # [list of content dirs]
knowledge_dir = paths.data_dir / "knowledge"
memory_file = paths.data_dir / "memory.json"
```

**Environment Variables:**
```bash
AMPLIFIER_DATA_DIR=.data               # Main data dir
AMPLIFIER_CONTENT_DIRS=content,docs    # Comma-separated content dirs
```

### 6.2 Adding New Tools

**Scenario Tool Template:**
```
scenarios/your_tool/
├── README.md                    # What it does & how to use
├── HOW_TO_CREATE_YOUR_OWN.md   # Creation process walkthrough
├── main.py                      # CLI entry point & orchestrator
├── state.py                     # State management (if resumable)
├── module_1/                    # Component modules
│   ├── __init__.py
│   └── core.py
├── module_2/
│   ├── __init__.py
│   └── core.py
└── tests/
    ├── test_module_1.py
    └── test_module_2.py
```

**Amplifier CLI Tool Template:**
```
amplifier/your_tool.py          # Standalone in ai_working/ initially

Then integrate into:
amplifier/your_module/          # Permanent module
├── __init__.py
├── cli.py                       # CLI entry point
├── core.py                      # Main implementation
└── README.md                    # Module contract
```

### 6.3 Extension Patterns

**Modular Architecture Enables:**

1. **Independent Development** - Modules developed in isolation
2. **Parallel Variants** - A/B test approaches (v1/ vs v2/)
3. **Incremental Integration** - Add features without rebuilding
4. **AI Regeneration** - Rebuild modules from specifications
5. **Isolated Testing** - Test modules independently

**Agent Extension:**
```yaml
# Create new agent in .claude/agents/
name: your-specialized-agent
description: What this agent specializes in
model: inherit  # Use Claude's capability

---

You are [Your Expert]...
[Define operating modes and patterns]
```

### 6.4 Knowledge System Integration

**Three-layer extraction pipeline:**

```
1. Content Files (.data/content/)
         ↓
2. Knowledge Synthesis
   (extract concepts, relationships, insights, patterns)
         ↓
3. Knowledge Graph
   (build NetworkX graph, detect tensions, search semantically)
         ↓
4. Query Interface
   (GraphSearch for natural language queries)
```

**Making New Tools Knowledge-Aware:**
```python
from amplifier.knowledge.graph_search import GraphSearch

search = GraphSearch()

# Natural language queries
results = search.query("what relates to AI agents?")

# Find connections between concepts
path = search.find_path("problem", "solution")

# Explore neighborhoods
context = search.get_neighborhood("topic", hops=3)
```

---

## 7. MEMORY SYSTEM

### 7.1 Architecture

**Four independent modules ("bricks"):**

1. **Memory Storage** (`memory/`)
   - JSON file persistence
   - Pydantic data validation
   - Access count tracking

2. **Memory Extraction** (`extraction/`)
   - Uses Claude Code SDK
   - Categories: learning, decision, issue_solved, preference, pattern
   - Automatic categorization

3. **Semantic Search** (`search/`)
   - Sentence transformer embeddings
   - Fallback keyword search
   - Relevance scoring

4. **Claim Validation** (`validation/`)
   - Detects contradictions
   - Verifies support
   - Confidence scoring

### 7.2 Integration Point

Memories can be retrieved in any tool:
```python
from amplifier.memory import MemoryStore
from amplifier.search import MemorySearcher

store = MemoryStore()
searcher = MemorySearcher()

# Find relevant memories
memories = store.get_all()
relevant = searcher.search("current topic", memories)

# Use in tool context
for memory in relevant:
    # Apply learning to current task
```

---

## 8. KNOWLEDGE SYNTHESIS PIPELINE

### 8.1 Single-Pass Extraction

```python
from amplifier.knowledge_synthesis import KnowledgeSynthesizer

synthesizer = KnowledgeSynthesizer()

# Single Claude call extracts:
extraction = await synthesizer.extract(text, title="Document")

# Returns:
{
    "concepts": [{"name": "...", "description": "...", "importance": 0.9}],
    "relationships": [{"subject": "...", "predicate": "...", "object": "...", "confidence": 0.95}],
    "insights": ["..."],
    "patterns": [{"name": "...", "description": "..."}]
}
```

### 8.2 Incremental Processing

- Tracks processed documents
- Saves to both:
  - Individual files (`.data/extractions/{id}.json`)
  - Consolidated JSONL (`.data/knowledge/extractions.jsonl`)
- Append-only event log (`.data/knowledge/events.jsonl`)
- Resumable at any point

### 8.3 Knowledge Graph

- NetworkX MultiDiGraph
- Entity resolution for concept merging
- Co-occurrence edges
- Source attribution tracking
- Tension detection (productive contradictions)
- Interactive visualization (PyVis)

---

## 9. DECISION TRACKING SYSTEM

### 9.1 Purpose

**Institutional memory for significant decisions:**
- Prevents uninformed reversals
- Documents rationale & alternatives
- Tracks consequences & learnings
- Guides evolution of patterns

### 9.2 Format

```markdown
# [DECISION-XXX] Title

**Date**: YYYY-MM-DD
**Status**: Active | Superseded | Deprecated

## Context
What situation prompted this decision?

## Decision  
What was decided?

## Rationale
Why this choice over alternatives?

## Alternatives Considered
- Option A: ... - Rejected because...
- Option B: ... - Rejected because...

## Consequences
- Positive: ...
- Negative: ...
- Risks: ...

## Review Triggers
When should this be reconsidered?
```

### 9.3 Current Records

- Located in `ai_working/decisions/`
- Referenced before making major changes
- Updated as consequences become apparent

---

## 10. KEY INSIGHTS & PATTERNS

### 10.1 "Bricks & Studs" in Action

**Every module follows this pattern:**

```python
# __init__.py - Public contract
from .core import ModuleClass

__all__ = ["ModuleClass"]  # Only expose what's needed

# core.py - Implementation
class ModuleClass:
    def public_method(self) -> Contract:
        """Clear contract with examples"""
        return Contract(...)
    
    def _private_method(self):
        """Internal only - not exposed"""
        pass
```

**Why this matters:**
- Interfaces never change when rebuilding
- Other modules depend only on `__all__`
- Can regenerate a module without affecting others

### 10.2 Ruthless Simplicity Examples

**Don't do this:**
```python
# Over-engineered state machine
class ConnectionRegistry:
    def __init__(self, metrics, cleanup_interval=60):
        self.connections_by_id = {}
        self.connections_by_resource = defaultdict(list)
        self.connections_by_user = defaultdict(list)
        # 50+ more lines of complex indexing
```

**Do this:**
```python
# Simple, focused solution
class SseManager:
    def __init__(self):
        self.connections = {}  # Simple dict tracking
    
    async def add_connection(self, resource_id, user_id):
        connection_id = str(uuid.uuid4())
        queue = asyncio.Queue()
        self.connections[connection_id] = {
            "resource_id": resource_id,
            "user_id": user_id,
            "queue": queue
        }
        return queue, connection_id
```

### 10.3 Vertical Slices Over Horizontal Layers

**Amplifier builds in vertical slices:**

```
❌ Layer-by-Layer:
   Infrastructure → Database → API → Business Logic → UI
   (Can't test end-to-end until everything done)

✓ Vertical Slices:
   Slice 1: End-to-end blog writing (store → process → output)
   Slice 2: Add style extraction (enhance existing flow)
   Slice 3: Add review stages (iterative enhancement)
   (Each slice is testable immediately)
```

### 10.4 State Management Pattern (From blog_writer)

```python
@dataclass
class PipelineState:
    stage: str = "initialized"
    iteration: int = 0
    max_iterations: int = 10
    
    # Module outputs
    style_profile: dict = field(default_factory=dict)
    current_draft: str = ""
    
    # Metadata
    created_at: str = field(default_factory=lambda: datetime.now().isoformat())

class StateManager:
    def __init__(self, session_dir: Path | None = None):
        # Creates timestamped session
        self.session_dir = session_dir or Path(".data") / "tool" / timestamp
        self.state = self._load_state()  # Resume if exists
    
    def save(self) -> None:
        # ALWAYS save after every operation
        # Enables interruption recovery
        write_json_with_retry(asdict(self.state), self.state_file)
```

**Key principle:** Save state after every operation, not just at intervals

### 10.5 Parallel Experimentation

From AMPLIFIER_VISION.md:
```
Traditional:    Human codes solution → tests → learns
Amplified:      Human describes goal
                    ↓
                AI generates 3 variants in parallel
                    ↓
                Human compares results
                    ↓
                AI learns from comparison
                    ↓
                AI regenerates all variants with improvements
```

---

## 11. CURRENT GAPS & FUTURE ORCHESTRATOR NEEDS

### 11.1 Current Orchestration State

**What exists:**
- Individual agents with clear specialties
- Examples of sequential pipelines (blog_writer)
- Manual invocation of agents
- Linear task execution

**What's missing:**
- Automatic task decomposition
- Parallel agent coordination
- Intelligent sequencing decisions
- Context management across agents
- Result synthesis & validation
- Feedback loop management

### 11.2 Orchestrator Requirements

**An orchestrator agent should:**

1. **Analyze requests** - Decompose into subtasks
2. **Select agents** - Match tasks to agent expertise
3. **Parallelize** - Run independent tasks simultaneously
4. **Sequence** - Order dependent tasks correctly
5. **Manage context** - Share results between agents
6. **Validate** - Check agent outputs for quality
7. **Retry** - Handle failures intelligently
8. **Synthesize** - Combine results coherently
9. **Learn** - Improve sequencing over time

### 11.3 Integration Points

Orchestrator should leverage:
- **zen-architect** for planning
- **modular-builder** for implementation
- **integration-specialist** for external systems
- **bug-hunter** for validation
- **test-coverage** for quality assurance
- **Knowledge graph** for context
- **Memory system** for learnings
- **Decision records** for guidance

---

## CONCLUSION

Amplifier is a sophisticated system that combines:
- **Ruthless simplicity** in implementation
- **Modular architecture** for regenerability
- **Specialized agents** for expertise
- **Defensive patterns** for reliability
- **State management** for resumability
- **Knowledge synthesis** for context
- **Memory system** for learning

The missing piece is an **orchestrator agent** that coordinates these capabilities intelligently, automatically decomposes complex requests, manages parallel work, and synthesizes results coherently.

The foundation is solid and proven (blog_writer shows it works). The orchestrator would complete the system.
