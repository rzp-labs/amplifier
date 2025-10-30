# DDD Plan: General-Purpose @Mention System + REQUEST_ENVELOPE_V1 Models

## Problem Statement

### What We're Solving

**Three foundational problems**:

1. **Missing REQUEST_ENVELOPE_V1 Models**: Spec exists, but no Pydantic models in amplifier-core
   - Providers use `dict[str, Any]` (ad-hoc, error-prone)
   - No shared message models
   - Data loss in conversions

2. **No Context Loading**: Main sessions lack rich context
   - No system instructions from profiles
   - No @mention-based context loading
   - Asymmetry with sub-agents

3. **@Mention Should Be General-Purpose**: Not just for profiles
   - Should work in user input: `"Explain @docs/API.md"`
   - Should work in any message
   - Should work in agent instructions
   - Should work anywhere text can have @mentions

**These must be solved together**: Need proper message models (Part A) to build general-purpose @mention system (Part B).

### Why It Matters

**User Value**:
- Type-safe message handling across all providers
- Rich context loading from @mentioned files
- Natural @mention syntax works everywhere (profiles, chat, messages)
- Content stays at top of message stack, @mention stays as reference

### The Key Insight (User Feedback)

**@mention processing should be general-purpose**:
- Works in profile markdown (session init)
- Works in user input at runtime
- Works in any message content
- Works in agent instructions

**@mention behavior**:
- ✅ Load content as context messages (top of stack)
- ✅ Original @mention STAYS in place (contextual reference)
- ❌ NEVER replace @mention inline with content

**Example**:
```
User: "Explain the architecture in @docs/ARCHITECTURE.md"

Resulting Message Stack:
1. [Context] role=user, content=<context_file paths="docs/ARCHITECTURE.md">[arch content]</context_file>
2. [Original] role=user, content="Explain the architecture in @docs/ARCHITECTURE.md"
                                                                ↑ stays as reference marker
```

**Why this works**:
- Content at top (model sees it)
- @mention in original (shows WHERE content is relevant)
- Model can reference "@docs/ARCHITECTURE.md" naturally
- Context clearly attributed

## Proposed Solution

### Three-Part Architecture

**Part A: REQUEST_ENVELOPE_V1 Pydantic Models** (Foundation)
- Complete Pydantic models in amplifier-core
- Shared across all providers
- Type-safe message handling

**Part B: General-Purpose @Mention Library** (Mechanism)
- Pure text utilities in amplifier-core
- File loading in shared library
- Works anywhere (profiles, runtime, messages)

**Part C: Integration Points** (Policy)
- Profile loading (session init)
- Message preprocessing (runtime)
- Provider conversion (XML wrapping)

### Architecture Overview

```
Part A: Foundation
    amplifier-core/message_models.py
        → Message, ContentBlock, ChatRequest, ChatResponse

Part B: @Mention Library (General-Purpose)
    amplifier-core/utils/
        → mentions.py (parse @mentions - pure text processing)

    amplifier-lib/ (or amplifier-app-cli/lib/)
        → mention_loader.py (load files, deduplicate)
        → mention_resolver.py (search paths)
        → content_deduplicator.py (hash-based)

Part C: Integration
    Profile Loading (amplifier-app-cli)
        → Process profile markdown → load @mentions

    Message Preprocessing (orchestrator or app)
        → Scan messages for @mentions → load → prepend

    Provider Conversion (providers)
        → Convert developer → XML-wrapped user
```

### Core Design Principle

**@mention is a reference, content loads separately**:

```
Input: "Compare @file1.md and @file2.md"

Message Stack:
1. <context_file paths="file1.md">content1</context_file>
2. <context_file paths="file2.md">content2</context_file>
3. "Compare @file1.md and @file2.md"  ← references stay!

Model sees:
- Full context content (at top)
- Original question with @mentions as semantic markers
- Can naturally reference "@file1.md says X, while @file2.md says Y"
```

## Part A: REQUEST_ENVELOPE_V1 Models

(Same as before - see previous plan sections)

## Part B: General-Purpose @Mention Library

### Component Placement

**Kernel Utilities** (`amplifier-core/amplifier_core/utils/mentions.py`):
```python
# Pure text processing - no file I/O, no policy

def parse_mentions(text: str) -> list[str]:
    """Extract @mentions from text. Returns list of mention strings."""
    pass

def has_mentions(text: str) -> bool:
    """Check if text contains @mentions."""
    pass

def extract_mention_info(mention: str) -> dict:
    """Parse mention into components (path, name, etc.)."""
    pass
```

**Shared Library** (`amplifier-app-cli/lib/mention_loading/` or new `amplifier-lib`):
```python
# File loading and resolution - policy decisions

class MentionLoader:
    """General-purpose @mention loading."""

    def load_mentions(
        self,
        text: str,
        search_paths: list[Path],
        base_path: Path | None = None
    ) -> list[Message]:
        """
        Load @mentioned files and return as context Messages.

        Process:
        1. Parse @mentions from text
        2. Resolve to file paths
        3. Load files recursively
        4. Deduplicate by content
        5. Return as Message objects (role=developer)

        Args:
            text: Text containing @mentions
            search_paths: Paths to search for files
            base_path: Base path for relative resolution

        Returns:
            List of Message objects with developer role
        """
        pass
```

### Usage Scenarios

#### Scenario 1: Profile Loading (Session Init)

```python
# In profile compiler/loader
from amplifier.lib.mention_loading import MentionLoader

# Load profile markdown body
markdown_body = profile.get_markdown_body()

# Process @mentions
mention_loader = MentionLoader()
context_messages = mention_loader.load_mentions(
    text=markdown_body,
    search_paths=[bundled_path, project_path, user_path],
    base_path=profile_file_path
)

# Inject into session
for msg in context_messages:
    await context.add_message(msg.model_dump())

# Original markdown body becomes system instruction (with @mentions intact)
system_msg = Message(role="system", content=markdown_body)
await context.add_message(system_msg.model_dump())
```

#### Scenario 2: Runtime User Input

```python
# In orchestrator or message preprocessing
from amplifier.lib.mention_loading import MentionLoader

# User submits message with @mentions
user_input = "Explain the architecture in @docs/ARCHITECTURE.md"

# Process @mentions
mention_loader = MentionLoader()
context_messages = mention_loader.load_mentions(
    text=user_input,
    search_paths=[project_path, user_path],
)

# Prepend context messages
all_messages = context_messages + [
    Message(role="user", content=user_input)  # Original with @mentions
]

# Send to provider
response = await provider.complete(ChatRequest(messages=all_messages))
```

#### Scenario 3: Agent Instructions

```python
# In agent spawning
agent_instruction = """
Analyze the codebase structure.

Reference:
- @docs/ARCHITECTURE.md
- @docs/MODULE_DEVELOPMENT.md
"""

# Process @mentions
context_messages = mention_loader.load_mentions(agent_instruction, ...)

# Agent sees both:
# 1. Context content (at top)
# 2. Original instruction with @mentions as references
```

### Message Stack Examples

**Example 1: User asks about specific file**:
```
Input: "What does @AGENTS.md say about testing?"

Message Stack:
[1] role=user: <context_file paths="AGENTS.md">[full AGENTS.md content]</context_file>
[2] role=user: "What does @AGENTS.md say about testing?"

Model response: "In @AGENTS.md, the testing section specifies..."
                     ↑ natural reference
```

**Example 2: Profile with @mentions**:
```
Profile markdown:
"You are a dev assistant.
Context:
- @AGENTS.md
- @DISCOVERIES.md"

Message Stack:
[1] role=user: <context_file paths="AGENTS.md">[AGENTS content]</context_file>
[2] role=user: <context_file paths="DISCOVERIES.md">[DISCOVERIES content]</context_file>
[3] role=system: "You are a dev assistant.\nContext:\n- @AGENTS.md\n- @DISCOVERIES.md"
                                                    ↑ references stay
```

**Example 3: User mentions multiple files**:
```
Input: "Compare @file1.md and @file2.md"

Message Stack:
[1] role=user: <context_file paths="file1.md">content1</context_file>
[2] role=user: <context_file paths="file2.md">content2</context_file>
[3] role=user: "Compare @file1.md and @file2.md"

Model can naturally say: "@file1.md uses approach X, while @file2.md uses approach Y"
```

## Architecture & Design

### Key Interfaces

#### Kernel Utils (amplifier-core/utils/mentions.py)

```python
def parse_mentions(text: str) -> list[str]:
    """
    Extract @mentions from text.

    Returns:
        List of mention strings (e.g., ["@AGENTS.md", "@ai_context/FILE.md"])
    """
    pass

def has_mentions(text: str) -> bool:
    """Check if text contains any @mentions."""
    pass
```

#### Shared Library (amplifier-lib/mention_loading/)

```python
from amplifier_core.message_models import Message

class MentionLoader:
    """General-purpose @mention file loader."""

    def __init__(self, search_paths: list[Path]):
        self.resolver = MentionResolver(search_paths)
        self.deduplicator = ContentDeduplicator()

    def load_mentions(
        self,
        text: str,
        base_path: Path | None = None
    ) -> list[Message]:
        """
        Load @mentioned files and return as context Messages.

        Process:
        1. Parse @mentions using core util
        2. Resolve to file paths
        3. Load files recursively (follow @mentions in them)
        4. Deduplicate by content
        5. Create Message objects (role=developer)

        Returns:
            List of Message objects with loaded content (role=developer)
            Original text unchanged (keep @mentions as references)
        """
        pass

    def process_message(
        self,
        message: Message,
        base_path: Path | None = None
    ) -> list[Message]:
        """
        Process a message and load any @mentions.

        Returns:
            List of context Messages (role=developer)
            Original message NOT modified (@mentions stay as references)
        """
        pass
```

### Module Boundaries

**Kernel** (`amplifier-core`):
- REQUEST_ENVELOPE_V1 Pydantic models
- Pure @mention parsing utilities (text processing only)
- NO file loading (policy)

**Shared Library** (`amplifier-lib` or `amplifier-app-cli/lib`):
- MentionLoader (file loading, deduplication)
- MentionResolver (search paths)
- ContentDeduplicator (hash-based)
- Policy: Which paths, how to resolve, when to load

**App Layer** (`amplifier-app-cli`):
- Profile loading integration
- Session initialization with context
- Configuration of search paths

**Orchestrators** (`amplifier-module-loop-*`):
- Runtime @mention processing (optional)
- Scan user messages for @mentions
- Load and prepend context messages

**Providers** (`amplifier-module-provider-*`):
- Convert developer → XML-wrapped user (if needed)
- Provider-specific message formatting

### Data Flow

```
Anywhere @mentions appear:
    ↓
1. Text with @mentions
   Example: "Explain @docs/API.md"
    ↓
2. Parse @mentions (core util)
   Result: ["@docs/API.md"]
    ↓
3. Load files (mention loader)
   Result: [Message(role=developer, content="[from @docs/API.md]...")]
    ↓
4. Prepend to message stack
   Stack: [context messages, original message with @mentions intact]
    ↓
5. Provider converts
   developer → XML-wrapped user (if needed)
    ↓
6. Model sees:
   - Content at top (full context)
   - Original message with @mentions (reference markers)
```

### Where @Mention Processing Happens

**Option A: Orchestrator Level** (Recommended for runtime)
```python
class StreamingOrchestrator:
    async def execute(self, prompt: str):
        # Check for @mentions in user input
        if has_mentions(prompt):
            context_msgs = mention_loader.load_mentions(prompt)
            # Prepend context to conversation
            all_messages = context_msgs + conversation + [Message(role="user", content=prompt)]
        else:
            all_messages = conversation + [Message(role="user", content=prompt)]

        # Send to provider
        response = await provider.complete(ChatRequest(messages=all_messages))
```

**Option B: Profile Loading** (Already planned)
```python
# At session init
profile_context = mention_loader.load_mentions(profile.markdown_body)
await context.add_message(Message(role="system", content=profile.markdown_body))
for ctx_msg in profile_context:
    await context.add_message(ctx_msg.model_dump())
```

**Option C: Message Preprocessing Hook** (Future)
```python
# Hook that processes all messages before provider
class MentionPreprocessor(Hook):
    async def on_messages_prepared(self, messages: list[Message]):
        # Scan all messages for @mentions
        # Load referenced content
        # Prepend as context messages
        pass
```

## Files to Change

### Non-Code Files (Phase 2 - Documentation)

#### Part A: Request Envelope Documentation

- [x] `docs/REQUEST_ENVELOPE_MODELS.md` - Guide to using models
- [x] `docs/specs/provider/REQUEST_ENVELOPE_V1.md` - Reference Python models
- [x] `docs/specs/provider/PROVIDER_MODULE_PROTOCOL.md` - Use Pydantic models

#### Part B: @Mention Library Documentation

- [x] `docs/CONTEXT_LOADING.md` - **UPDATE**: General-purpose @mention system (not just profiles)
- [x] `docs/PROFILE_AUTHORING.md` - **UPDATE**: Profile markdown body with @mentions
- [ ] `docs/MENTION_PROCESSING.md` - **NEW**: General-purpose @mention guide
- [ ] `docs/USER_ONBOARDING.md` - **UPDATE**: Using @mentions in chat
- [ ] `docs/AMPLIFIER_CONTEXT_GUIDE.md` - **UPDATE**: @mention architecture
- [ ] `docs/README.md` - **UPDATE**: Link to @mention docs

#### Bundled Context Files

- [x] `amplifier-app-cli/amplifier_app_cli/data/context/README.md`
- [x] `amplifier-app-cli/amplifier_app_cli/data/context/AGENTS.md`
- [x] `amplifier-app-cli/amplifier_app_cli/data/context/DISCOVERIES.md`

#### Profile Updates

- [x] All 6 bundled profiles updated with system instructions

### Code Files (Phase 4 - Implementation)

#### Part A: Request Envelope Models

**New Files - Kernel**:
- [ ] `amplifier-core/amplifier_core/message_models.py` - Complete models

**Modified Files - Kernel**:
- [ ] `amplifier-core/amplifier_core/__init__.py` - Export models
- [ ] `amplifier-core/amplifier_core/interfaces.py` - Update Provider Protocol

**Modified Files - Providers** (4 providers):
- [ ] Each provider: Use ChatRequest/ChatResponse, converters

#### Part B: @Mention Library

**New Files - Kernel Utils**:
- [ ] `amplifier-core/amplifier_core/utils/__init__.py` - Utils package
- [ ] `amplifier-core/amplifier_core/utils/mentions.py` - @mention parsing (pure text)

**New Files - Shared Library** (amplifier-lib or amplifier-app-cli/lib):
- [ ] `lib/mention_loading/__init__.py` - Package
- [ ] `lib/mention_loading/loader.py` - MentionLoader
- [ ] `lib/mention_loading/resolver.py` - MentionResolver
- [ ] `lib/mention_loading/deduplicator.py` - ContentDeduplicator
- [ ] `lib/mention_loading/models.py` - ContextFile model

#### Part C: Integration Points

**Profile Loading** (amplifier-app-cli):
- [ ] `amplifier-app-cli/profile_system/loader.py` - Use MentionLoader

**Runtime Processing** (orchestrator):
- [ ] `amplifier-module-loop-streaming/__init__.py` - Process user input @mentions
- [ ] `amplifier-module-loop-basic/__init__.py` - Process user input @mentions

**Provider Conversion**:
- [ ] Each provider: Convert developer → XML-wrapped user

**Tests**:
- [ ] Core: `test_mentions.py` (parsing tests)
- [ ] Lib: `test_mention_loader.py`, `test_resolver.py`, `test_deduplicator.py`
- [ ] Integration: `test_mention_integration.py` (profile + runtime)
- [ ] Provider: `test_context_conversion.py` (each provider)

## General-Purpose @Mention Design

### Where @Mentions Work

**Everywhere**:
1. Profile markdown bodies (session init)
2. User input at runtime (`"Explain @file.md"`)
3. System messages
4. User messages in conversation
5. Agent instructions
6. Anywhere text can contain @mentions

### Processing Flow

```python
# Generic flow (works anywhere)

def process_text_with_mentions(
    text: str,
    search_paths: list[Path],
    base_path: Path | None = None
) -> tuple[list[Message], str]:
    """
    Process text containing @mentions.

    Returns:
        (context_messages, original_text)

    Context messages: Loaded content (role=developer)
    Original text: UNCHANGED (keeps @mentions as references)
    """
    # 1. Parse @mentions
    mentions = parse_mentions(text)

    # 2. Load mentioned files
    mention_loader = MentionLoader(search_paths)
    context_messages = []

    for mention in mentions:
        # Resolve and load
        loaded = mention_loader.load_file(mention, base_path)
        context_messages.extend(loaded)  # May be multiple if recursive

    # 3. Deduplicate by content
    deduplicated = deduplicator.deduplicate(context_messages)

    # 4. Return context + original text (UNCHANGED)
    return deduplicated, text  # text still has @mentions!
```

### Integration Examples

**Example 1: Profile Loading**:
```python
# Session initialization
profile_markdown = """
You are a dev assistant.
Context:
- @AGENTS.md
"""

# Load @mentions
context_msgs, original = process_text_with_mentions(profile_markdown, search_paths)

# Inject both
for msg in context_msgs:
    await context.add_message(msg.model_dump())  # Context at top

await context.add_message(Message(
    role="system",
    content=original  # System instruction with @mentions as references
).model_dump())
```

**Example 2: Runtime User Input**:
```python
# User submits
user_input = "Explain @docs/API.md and compare with @docs/ARCHITECTURE.md"

# Load @mentions
context_msgs, original = process_text_with_mentions(user_input, search_paths)

# Build message stack
messages = (
    context_msgs +  # Context at top
    conversation_history +  # Previous conversation
    [Message(role="user", content=original)]  # User message with @mentions
)

# Send to provider
response = await provider.complete(ChatRequest(messages=messages))
```

**Example 3: System Message with @Mentions**:
```python
# System instruction
system_text = """
Core guidelines:
- @guidelines/coding-standards.md
- @guidelines/security-policy.md
"""

# Load @mentions
context_msgs, original = process_text_with_mentions(system_text, search_paths)

# Message stack
messages = [
    *context_msgs,  # Context files
    Message(role="system", content=original),  # System with @mentions
    *conversation
]
```

### Why @Mention Stays as Reference

**Contextual Marker**:
- Shows WHERE/WHEN content is relevant
- "in @file.md" - model can reference naturally
- Semantic link between content and question

**Example**:
```
User: "What does @AGENTS.md say about testing?"

Context loaded: [full AGENTS.md content at top]
Question keeps: "@AGENTS.md" as reference

Model response: "In @AGENTS.md, the testing philosophy emphasizes..."
                     ↑ natural, semantic reference
```

**Not Inline Replacement**:
```
❌ BAD: Replace @mention with content inline
"What does [50KB of content] say about testing?"
→ Breaks question structure

✅ GOOD: Keep reference, load content separately
Content at top: [50KB]
Question: "What does @AGENTS.md say about testing?"
→ Question structure preserved, content available
```

## Component Design

### amplifier-core/utils/mentions.py

```python
"""Pure text processing for @mentions - no file I/O."""

import re
from typing import Pattern

# @mention pattern
MENTION_PATTERN: Pattern = re.compile(r'@([a-zA-Z0-9_\-/\.]+)')

def parse_mentions(text: str) -> list[str]:
    """
    Extract all @mentions from text.

    Examples:
        >>> parse_mentions("Load @AGENTS.md and @ai_context/FILE.md")
        ['@AGENTS.md', '@ai_context/FILE.md']

    Returns:
        List of @mention strings (includes @ prefix)
    """
    return MENTION_PATTERN.findall(text)

def has_mentions(text: str) -> bool:
    """Check if text contains @mentions."""
    return bool(MENTION_PATTERN.search(text))

def extract_mention_path(mention: str) -> str:
    """
    Extract path from @mention (remove @ prefix).

    Examples:
        >>> extract_mention_path("@AGENTS.md")
        'AGENTS.md'
        >>> extract_mention_path("@ai_context/FILE.md")
        'ai_context/FILE.md'
    """
    return mention.lstrip('@')
```

### amplifier-lib/mention_loading/loader.py

```python
"""@mention file loading with deduplication."""

from pathlib import Path
from amplifier_core.utils.mentions import parse_mentions
from amplifier_core.message_models import Message

class MentionLoader:
    """Load @mentioned files into context messages."""

    def __init__(self, resolver: MentionResolver, deduplicator: ContentDeduplicator):
        self.resolver = resolver
        self.deduplicator = deduplicator

    def load_mentions(
        self,
        text: str,
        base_path: Path | None = None,
        visited: set[str] | None = None
    ) -> list[Message]:
        """
        Load all @mentioned files from text.

        Args:
            text: Text containing @mentions
            base_path: Base path for relative resolution
            visited: Cycle detection set

        Returns:
            List of Message objects (role=developer, XML-wrapped content)
        """
        if visited is None:
            visited = set()

        # Parse @mentions
        mentions = parse_mentions(text)
        if not mentions:
            return []

        messages = []

        for mention in mentions:
            # Resolve to file path
            file_path = self.resolver.resolve(mention, base_path)
            if not file_path or not file_path.exists():
                continue  # Silent skip

            # Cycle detection
            if str(file_path) in visited:
                continue
            visited.add(str(file_path))

            # Load file content
            content = file_path.read_text()

            # Recursively load @mentions in this file
            nested_messages = self.load_mentions(content, file_path.parent, visited)
            messages.extend(nested_messages)

            # Add this file's content
            is_new = self.deduplicator.add_file(str(file_path), content)

            # Deduplicator tracks all paths for this content
            # Messages created after all loading (see get_context_messages())

        return self.deduplicator.get_context_messages()
```

### Module Placement Decision

**Where should `mention_loading` library live?**

**Option 1: New `amplifier-lib` package**
- Shared utilities not part of kernel
- Can be used by app-cli, modules, or external tools
- Clean separation from app-specific code

**Option 2: `amplifier-app-cli/lib`**
- Part of app package
- Simpler (no new package)
- Tightly coupled with app

**Option 3: `amplifier-core`**
- Would violate kernel philosophy (adds policy: file loading, search paths)
- Kernel should only have text parsing utils

**Recommendation**: **amplifier-lib** (new package)
- Reusable across app and modules
- Kernel stays pure (only text utils)
- Clean architecture

## Implementation Approach

### Phase 4: Code Implementation (Revised Order)

**Chunk A1: Core Message Models**
- amplifier-core/message_models.py
- Complete REQUEST_ENVELOPE_V1 models
- Tests

**Chunk A2: Core @Mention Utils**
- amplifier-core/utils/mentions.py
- Pure text parsing (no file I/O)
- Tests

**Chunk B1: @Mention Loading Library**
- Create amplifier-lib package (or use amplifier-app-cli/lib)
- MentionLoader, MentionResolver, ContentDeduplicator
- Tests

**Chunk B2: Profile Loading Integration**
- amplifier-app-cli: Use MentionLoader for profiles
- Load @mentions from profile markdown
- Tests

**Chunk B3: Runtime @Mention Processing**
- amplifier-module-loop-streaming: Process user input @mentions
- amplifier-module-loop-basic: Process user input @mentions
- Tests

**Chunk A3-A6: Provider Updates**
- Update each provider to use ChatRequest/ChatResponse
- Add developer → XML-wrapped user conversion
- Tests

**Chunk B4: End-to-End Testing**
- Profile @mentions
- Runtime @mentions
- Recursive loading
- Deduplication
- All providers

## Use Case Examples

### Use Case 1: Profile with Shared Context

```markdown
# dev.md
---
profile:
  name: dev
---

You are an Amplifier development assistant.

Guidelines:
- @AGENTS.md
- @DISCOVERIES.md
- @ai_context/KERNEL_PHILOSOPHY.md

Work efficiently following project conventions.
```

**Result**:
```
Message Stack:
[1-3] Context messages (AGENTS, DISCOVERIES, KERNEL_PHILOSOPHY contents)
[4] System: "You are... @AGENTS.md @DISCOVERIES.md @ai_context/KERNEL_PHILOSOPHY.md..."
    (references preserved)
```

### Use Case 2: User References Doc at Runtime

```
User: "Explain the session lifecycle described in @docs/SESSION.md"

Message Stack:
[existing context...]
[N] Context from user input: <context_file paths="docs/SESSION.md">[content]</context_file>
[N+1] User: "Explain the session lifecycle described in @docs/SESSION.md"
              (reference preserved)
Model can say: "The @docs/SESSION.md describes three phases..."
```

### Use Case 3: Compare Multiple Docs

```
User: "Compare the testing approaches in @docs/testing-guide.md and @examples/test-example.md"

Message Stack:
[context1] <context_file paths="docs/testing-guide.md">[content]</context_file>
[context2] <context_file paths="examples/test-example.md">[content]</context_file>
[user] "Compare the testing approaches in @docs/testing-guide.md and @examples/test-example.md"

Model can say: "@docs/testing-guide.md emphasizes X, while @examples/test-example.md demonstrates Y"
```

### Use Case 4: Agent with Context

```
Task delegation: "zen-architect: Design a caching system. Reference @docs/ARCHITECTURE.md for patterns."

Agent message stack:
[context] <context_file paths="docs/ARCHITECTURE.md">[content]</context_file>
[instruction] "Design a caching system. Reference @docs/ARCHITECTURE.md for patterns."

Agent can naturally say: "Following the pattern in @docs/ARCHITECTURE.md..."
```

## Success Criteria

### Part A: Request Envelope Models

✅ Complete Pydantic models match REQUEST_ENVELOPE_V1 spec
✅ All providers use shared models
✅ Type safety throughout
✅ Content blocks preserved
✅ Round-trip tests pass
✅ No kernel behavioral changes

### Part B: @Mention Library

✅ Pure text utils in kernel (parse_mentions, has_mentions)
✅ File loading library (amplifier-lib or app-cli/lib)
✅ Works in profile markdown (session init)
✅ Works in user input (runtime)
✅ Works in any message
✅ Recursive loading with deduplication
✅ Content at top, @mentions stay as references

### Part C: Integration

✅ Profile loading uses @mention library
✅ Orchestrators process runtime @mentions
✅ Providers convert developer → XML-wrapped user
✅ All integration points tested

## Philosophy Alignment

### Ruthless Simplicity ✓

**Start minimal**:
- Core utils: Just regex parsing
- Lib: Basic file loading
- Integrate: Profile first, runtime second

**Avoid future-proofing**:
- ❌ NOT building template engines
- ❌ NOT building conditional loading
- ❌ NOT building complex @mention syntax extensions

**Clear over clever**:
- ✅ Simple regex pattern
- ✅ Straightforward file resolution
- ✅ Clear deduplication algorithm

### Modular Design ✓

**Bricks (Self-Contained)**:
- mentions.py (kernel util)
- mention_loading library (shared)
- Profile loading (app)
- Runtime processing (orchestrators)

**Studs (Clear Interfaces)**:
- parse_mentions() → list[str]
- MentionLoader.load_mentions() → list[Message]
- Message models (REQUEST_ENVELOPE_V1)

**Regeneratable**:
- Each component isolated
- Clear contracts
- Can rebuild from spec

### Kernel Philosophy ✓

**Mechanism, not policy**:
- ✅ Kernel: parse_mentions (mechanism)
- ✅ Lib: file loading (shared mechanism)
- ✅ App/modules: when/where to load (policy)

**Small, stable, boring**:
- ✅ Kernel adds only models + text utils
- ✅ No behavioral changes
- ✅ Minimal expansion

## Summary

This revised plan implements:

**Part A: REQUEST_ENVELOPE_V1 Models**
- Type-safe message handling
- Shared across all providers
- Foundation for context loading

**Part B: General-Purpose @Mention Library**
- Works ANYWHERE (profiles, runtime, messages)
- Content loads at top, @mention stays as reference
- Recursive, deduplicated
- Pure kernel utils + shared library

**Part C: Integration**
- Profile loading (session init)
- Runtime processing (user input)
- Provider conversion (XML wrapping)

**Key Design**:
- ✅ @mentions work everywhere
- ✅ Content always at top of message stack
- ✅ @mention stays in original text (contextual reference)
- ✅ Model can naturally reference "@file.md says..."
- ✅ Kernel provides utilities, library provides loading, app/modules provide policy

**Ready for implementation!**
