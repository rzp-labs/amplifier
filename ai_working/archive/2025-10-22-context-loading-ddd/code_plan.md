# Code Implementation Plan

**Generated**: 2025-10-21
**Based on**: ai_working/ddd/plan.md + Phase 2 documentation
**Architecture**: Zen-Architect Approved

## Summary

Implement general-purpose @mention system and REQUEST_ENVELOPE_V1 Pydantic models using existing kernel APIs (no new APIs).

**Scope**: 3 parts, 7 implementation chunks
- Part A: REQUEST_ENVELOPE_V1 models (kernel)
- Part B: @Mention library (kernel utils + shared lib)
- Part C: Integration (app layer using existing APIs)

## Implementation Strategy

### Decision: Where to Place Mention Loading Library

**amplifier-lib** (new package) vs **amplifier-app-cli/lib** (in-app)

**Recommendation**: **amplifier-app-cli/lib** (simpler, sufficient)
- Mention loading is app-layer policy
- No need for separate package initially
- Can extract to amplifier-lib later if other apps need it
- KISS principle: Start in-app, extract if needed

### Chunk Order (Dependencies)

```
Chunk 1: message_models.py (foundation - nothing depends on others)
Chunk 2: utils/mentions.py (text parsing - depends on nothing)
Chunk 3: app-cli/lib/mention_loading (depends on Chunks 1 & 2)
Chunk 4: Profile loading integration (depends on Chunk 3)
Chunk 5: Provider updates (depends on Chunk 1)
Chunk 6: Runtime @mention processing (depends on Chunks 3 & 4)
Chunk 7: End-to-end testing (depends on all)
```

## Part A: REQUEST_ENVELOPE_V1 Models

### Chunk 1: Core Message Models

**New Files**:
- `amplifier-core/amplifier_core/message_models.py`
- `amplifier-core/tests/test_message_models.py`

**Modified Files**:
- `amplifier-core/amplifier_core/__init__.py` - Export models
- `amplifier-core/amplifier_core/interfaces.py` - Update Provider Protocol signatures

**Implementation Spec**:

Create complete Pydantic models from REQUEST_ENVELOPE_V1 spec:
- Message (role, content, name, tool_call_id)
- ContentBlock union (Text, Thinking, RedactedThinking, ToolCall, ToolResult, Image, Reasoning)
- ChatRequest (messages, tools, params)
- ChatResponse (content, tool_calls, usage)
- Supporting models (ToolSpec, ToolCall, Usage, Degradation)

**Test Strategy**:
- Model validation (valid/invalid inputs)
- Serialization round-trips
- ContentBlock discriminated union
- Extra fields preservation

**Agent**: modular-builder

**Commit**: "feat(core): Add REQUEST_ENVELOPE_V1 Pydantic models"

**Dependencies**: None

**Estimated Effort**: 2-3 hours

### Integration with Current content_models.py

**Current State**: amplifier_core/content_models.py has partial ContentBlock classes

**Decision**:
- Create message_models.py with complete REQUEST_ENVELOPE_V1 models
- Deprecate content_models.py (or integrate)
- Update imports throughout

**Plan**: In this chunk, note deprecation; actual migration can be separate cleanup task

## Part B: @Mention Library

### Chunk 2: Core @Mention Text Utils

**New Files**:
- `amplifier-core/amplifier_core/utils/mentions.py`
- `amplifier-core/tests/test_mentions.py`

**Modified Files**:
- `amplifier-core/amplifier_core/utils/__init__.py` - Export parse_mentions, has_mentions

**Implementation Spec**:

Pure text processing (NO file I/O):
```python
import re

MENTION_PATTERN = re.compile(r'@([a-zA-Z0-9_\-/\.]+)')

def parse_mentions(text: str) -> list[str]:
    """Extract @mentions from text."""
    return ['@' + m for m in MENTION_PATTERN.findall(text)]

def has_mentions(text: str) -> bool:
    """Check if text has @mentions."""
    return bool(MENTION_PATTERN.search(text))

def extract_mention_path(mention: str) -> str:
    """Remove @ prefix from mention."""
    return mention.lstrip('@')
```

**Test Strategy**:
- Parse single @mention
- Parse multiple @mentions
- Parse @mentions with paths
- Ignore non-@mentions
- Edge cases (@@, @@ in code blocks)

**Agent**: modular-builder

**Commit**: "feat(core): Add @mention text parsing utilities"

**Dependencies**: None

**Estimated Effort**: 1 hour

### Chunk 3: Mention Loading Library

**New Files**:
- `amplifier-app-cli/lib/mention_loading/__init__.py`
- `amplifier-app-cli/lib/mention_loading/loader.py` - MentionLoader
- `amplifier-app-cli/lib/mention_loading/resolver.py` - MentionResolver
- `amplifier-app-cli/lib/mention_loading/deduplicator.py` - ContentDeduplicator
- `amplifier-app-cli/lib/mention_loading/models.py` - ContextFile model
- `amplifier-app-cli/tests/lib/test_mention_loader.py`
- `amplifier-app-cli/tests/lib/test_resolver.py`
- `amplifier-app-cli/tests/lib/test_deduplicator.py`

**Implementation Spec**:

**MentionLoader**:
```python
class MentionLoader:
    def __init__(self, resolver, deduplicator):
        self.resolver = resolver
        self.deduplicator = deduplicator

    def load_mentions(self, text: str, base_path: Path | None = None) -> list[Message]:
        """
        Load @mentioned files and return as Message objects.

        Process:
        1. parse_mentions(text) using kernel util
        2. Resolve each to file path
        3. Load file content recursively
        4. Deduplicate by content hash
        5. Return Message objects (role=developer)
        """
        pass
```

**MentionResolver**:
```python
class MentionResolver:
    def __init__(self, search_paths: list[Path]):
        self.search_paths = search_paths

    def resolve(self, mention: str, base_path: Path | None) -> Path | None:
        """Resolve @mention to file path (first match wins)."""
        pass
```

**ContentDeduplicator**:
```python
class ContentDeduplicator:
    def __init__(self):
        self.content_map = {}  # hash → ContextFile

    def add_file(self, path: str, content: str) -> bool:
        """Add file, return True if new content."""
        pass

    def get_messages(self) -> list[Message]:
        """Get deduplicated messages."""
        pass
```

**Test Strategy**:
- Load single file
- Load with @mentions (recursive)
- Deduplication (same content, different paths)
- Missing files (silent skip)
- Cycle detection

**Agent**: modular-builder

**Commit**: "feat(app-cli): Add @mention loading library"

**Dependencies**: Chunks 1 & 2

**Estimated Effort**: 3-4 hours

## Part C: Integration

### Chunk 4: Profile Loading with @Mentions

**Modified Files**:
- `amplifier-app-cli/amplifier_app_cli/profile_system/loader.py`
- `amplifier-app-cli/amplifier_app_cli/profile_system/compiler.py`
- `amplifier-app-cli/tests/test_profile_mention_loading.py`

**Implementation Spec**:

In profile loader:
```python
from amplifier_core.utils.mentions import has_mentions
from amplifier_app_cli.lib.mention_loading import MentionLoader

class ProfileLoader:
    def load_profile_with_context(self, profile_path: Path) -> tuple[Profile, list[Message]]:
        """
        Load profile and process @mentions in markdown body.

        Returns:
            (profile, context_messages)
        """
        profile = self.load_profile(profile_path)
        markdown_body = extract_markdown_body(profile_path)

        if has_mentions(markdown_body):
            loader = MentionLoader(search_paths)
            context_msgs = loader.load_mentions(markdown_body, profile_path.parent)
            return profile, context_msgs

        return profile, []
```

In run command:
```python
# Load profile with context
profile, context_msgs = profile_loader.load_profile_with_context(profile_path)

# Create session
session = AmplifierSession(mount_plan, loader)
await session.initialize()

# Add context messages (existing kernel API)
context = session.coordinator.get("context")
for msg in context_msgs:
    await context.add_message(msg.model_dump())

# Add system instruction (profile markdown with @mentions as references)
await context.add_message(Message(
    role="system",
    content=markdown_body  # @mentions stay in text!
).model_dump())
```

**Test Strategy**:
- Profile without @mentions
- Profile with @mentions
- Profile with {{parent_instruction}}
- Recursive @mention loading
- Content deduplication

**Agent**: modular-builder

**Commit**: "feat(app-cli): Add @mention processing to profile loading"

**Dependencies**: Chunk 3

**Estimated Effort**: 2-3 hours

### Chunk 5: Provider Updates (Use Models)

**Modified Files**:
- `amplifier-module-provider-anthropic/__init__.py`
- `amplifier-module-provider-openai/__init__.py`
- `amplifier-module-provider-azure-openai/__init__.py`
- `amplifier-module-provider-ollama/__init__.py`
- Tests for each provider

**Implementation Spec**:

Each provider:
1. Update `complete()` signature: Use ChatRequest/ChatResponse
2. Add converter methods:
   - `_convert_to_provider(request: ChatRequest) → provider_format`
   - `_convert_from_provider(response) → ChatResponse`
3. Handle developer role → XML-wrapped user conversion

**Anthropic example**:
```python
async def complete(self, request: ChatRequest) -> ChatResponse:
    # Extract system and developer messages
    system_msgs = [m for m in request.messages if m.role == "system"]
    developer_msgs = [m for m in request.messages if m.role == "developer"]
    conversation = [m for m in request.messages if m.role in ("user", "assistant")]

    # System → system parameter (combined)
    system = "\n\n".join(m.content for m in system_msgs) if system_msgs else None

    # Developer → XML-wrapped user messages (prepend)
    context_user_msgs = []
    for dev_msg in developer_msgs:
        wrapped = f"<context_file>\n{dev_msg.content}\n</context_file>"
        context_user_msgs.append({"role": "user", "content": wrapped})

    # Build message list: context then conversation
    all_messages = context_user_msgs + self._convert_messages(conversation)

    # Call Anthropic API
    response = await self.client.messages.create(
        system=system,
        messages=all_messages,
        ...
    )

    # Convert response → ChatResponse
    return self._convert_response(response)
```

**Test Strategy**:
- Round-trip tests (Message → provider → Message)
- Developer message conversion (XML wrapping)
- Content block preservation
- Each provider independently

**Agent**: modular-builder (one per provider, can parallelize)

**Commits**: 4 commits (one per provider)

**Dependencies**: Chunk 1

**Estimated Effort**: 4-6 hours (all providers)

### Chunk 6: Runtime @Mention Processing

**Modified Files**:
- `amplifier-app-cli/amplifier_app_cli/commands/run.py`
- `amplifier-app-cli/tests/test_runtime_mentions.py`

**Implementation Spec**:

In run command, before execute:
```python
from amplifier_core.utils.mentions import has_mentions
from amplifier_app_cli.lib.mention_loading import MentionLoader

async def run_session(session, user_prompt: str):
    # Process @mentions in user input (app-layer policy)
    if has_mentions(user_prompt):
        loader = MentionLoader(search_paths=[project, user])
        context_msgs = loader.load_mentions(user_prompt)

        # Add to context (existing kernel API)
        context = session.coordinator.get("context")
        for msg in context_msgs:
            await context.add_message(msg.model_dump())

    # Execute (original prompt with @mentions intact)
    response = await session.execute(user_prompt)
    return response
```

**Test Strategy**:
- User input without @mentions
- User input with @mentions
- Multiple @mentions
- Missing files (silent skip)
- Context messages at top of stack

**Agent**: modular-builder

**Commit**: "feat(app-cli): Add runtime @mention processing to user input"

**Dependencies**: Chunks 3 & 4

**Estimated Effort**: 2 hours

### Chunk 7: End-to-End Testing

**New Files**:
- `amplifier-app-cli/tests/integration/test_mention_system.py`
- `amplifier-dev/tests/integration/test_full_stack.py`

**Test Scenarios**:

1. Profile @mentions (session init)
2. Runtime @mentions (user input)
3. Recursive @mention loading
4. Content deduplication
5. All providers handle context correctly
6. {{parent_instruction}} inheritance

**Manual Testing**:
```bash
# Test 1: Profile with @mentions
amplifier run --profile dev "test"

# Test 2: Runtime @mentions
amplifier run "Explain @AGENTS.md"

# Test 3: Multiple @mentions
amplifier run "Compare @file1.md and @file2.md"
```

**Agent**: test-coverage (for test planning), modular-builder (for implementation)

**Commit**: "test: Add end-to-end tests for @mention system"

**Dependencies**: All previous chunks

**Estimated Effort**: 2-3 hours

## Detailed File Specifications

### amplifier-core/message_models.py

**Purpose**: REQUEST_ENVELOPE_V1 Pydantic models

**Exports**:
- Message
- ContentBlock types (TextBlock, ThinkingBlock, ToolCallBlock, etc.)
- ChatRequest, ChatResponse
- ToolSpec, ToolCall, Usage, Degradation

**Implementation**: Follow REQUEST_ENVELOPE_V1 spec and JSON schema exactly

**Cross-reference**: See docs/REQUEST_ENVELOPE_MODELS.md for usage

### amplifier-core/utils/mentions.py

**Purpose**: Pure text @mention parsing

**Exports**:
- parse_mentions(text) → list[str]
- has_mentions(text) → bool
- extract_mention_path(mention) → str

**Implementation**: Simple regex, no file I/O

**Cross-reference**: See docs/MENTION_PROCESSING.md for usage

### amplifier-app-cli/lib/mention_loading/

**Purpose**: File loading and deduplication for @mentions

**Modules**:
- loader.py - MentionLoader class
- resolver.py - MentionResolver class
- deduplicator.py - ContentDeduplicator class
- models.py - ContextFile model

**Dependencies**: amplifier-core (for parse_mentions, Message)

**Cross-reference**: See docs/CONTEXT_LOADING.md for architecture

### amplifier-app-cli/profile_system/loader.py

**Current**: Loads profile YAML frontmatter, extracts markdown body

**Changes Needed**:
- Add method to process @mentions in markdown body
- Use MentionLoader to load files
- Return context messages separately from profile

**Integration Point**: commands/run.py

### amplifier-app-cli/commands/run.py

**Current**: Creates session, initializes, executes prompt

**Changes Needed**:
- Process @mentions in profile markdown (session init)
- Process @mentions in user input (runtime)
- Add context via existing context.add_message() API

**Key**: Keep @mentions in original text (reference markers)

### Provider Modules (4 files)

**Current**: Use dict[str, Any] for messages

**Changes Needed**:
- Update signature: complete(request: ChatRequest) → ChatResponse
- Add converters: to_provider(), from_provider()
- Handle developer role → XML-wrapped user

**Each Provider**:
- amplifier-module-provider-anthropic
- amplifier-module-provider-openai
- amplifier-module-provider-azure-openai
- amplifier-module-provider-ollama

## Test Strategy

### Unit Tests

**message_models.py**:
- Model validation
- Serialization/deserialization
- ContentBlock discrimination
- Round trips

**utils/mentions.py**:
- Parse simple @mention
- Parse multiple @mentions
- Parse @mentions with paths
- Ignore non-mentions
- Edge cases

**mention_loading/**:
- MentionLoader loads files
- MentionResolver resolves paths
- ContentDeduplicator deduplicates
- Recursive loading
- Cycle detection

### Integration Tests

**Profile loading**:
- Profile without @mentions works
- Profile with @mentions loads context
- {{parent_instruction}} expands
- Context messages prepended

**Runtime processing**:
- User input without @mentions works
- User input with @mentions loads context
- @mentions stay in user message
- Content at top of stack

**Provider integration**:
- Each provider converts correctly
- XML wrapping works
- Message order correct
- Tool calls preserved

### End-to-End Tests

**Full system**:
- Create profile with @mentions
- Run session
- Input with @mentions
- Verify context loaded
- Verify @mentions as references
- All providers tested

## Commit Strategy

**Commit 1**: Core message models
```
feat(core): Add REQUEST_ENVELOPE_V1 Pydantic models

- Complete Pydantic models for REQUEST_ENVELOPE_V1 spec
- Message, ContentBlock, ChatRequest, ChatResponse
- All supporting models (ToolSpec, ToolCall, Usage, Degradation)
- Comprehensive unit tests
```

**Commit 2**: @mention text utils
```
feat(core): Add @mention text parsing utilities

- parse_mentions() for extracting @mentions from text
- has_mentions() for detection
- Pure text processing, no file I/O
- Unit tests with edge cases
```

**Commit 3**: Mention loading library
```
feat(app-cli): Add @mention file loading library

- MentionLoader for loading and deduplication
- MentionResolver for search path resolution
- ContentDeduplicator for hash-based dedup
- Recursive loading with cycle detection
- Comprehensive unit tests
```

**Commit 4**: Profile integration
```
feat(app-cli): Add @mention processing to profile loading

- Process @mentions in profile markdown bodies
- Load context files via MentionLoader
- Add to session via existing context.add_message() API
- System instruction keeps @mentions as references
- Integration tests
```

**Commit 5-8**: Provider updates (one per provider)
```
feat(provider-anthropic): Use REQUEST_ENVELOPE_V1 models

- Update to use ChatRequest/ChatResponse
- Convert developer → XML-wrapped user messages
- Preserve content blocks (thinking, tool_calls)
- Round-trip tests
```

**Commit 9**: Runtime processing
```
feat(app-cli): Add runtime @mention processing to user input

- Process @mentions in user input at runtime
- Load context before execution
- Original @mention stays as reference
- Integration tests
```

**Commit 10**: End-to-end tests
```
test: Add comprehensive @mention system tests

- Profile @mentions
- Runtime @mentions
- Recursive loading
- Deduplication
- All providers
```

## Philosophy Compliance

### Ruthless Simplicity ✓

**What we're doing**:
- Simple regex for parsing
- Straightforward file loading
- Reusing existing APIs

**What we're NOT doing**:
- ❌ Complex template systems
- ❌ Conditional loading
- ❌ Runtime reloading
- ❌ New kernel APIs

### Modular Design ✓

**Clear bricks**:
- mentions.py (kernel util)
- message_models.py (kernel models)
- mention_loading library (shared)
- Profile integration (app)
- Provider conversions (providers)

**Stable studs**:
- parse_mentions() → list[str]
- MentionLoader.load_mentions() → list[Message]
- context.add_message() (existing!)

### Kernel Philosophy ✓

**Mechanism in kernel**:
- Text parsing utility
- Message models
- Existing context API

**Policy at edges**:
- App decides when/where to process
- App decides search paths
- Providers decide conversion format

## Risk Assessment

**Low Risk**:
- Text parsing (simple regex)
- Using existing APIs (no kernel changes)
- Isolated library (new code, no dependencies)

**Medium Risk**:
- Provider updates (cross-cutting)
- Message model migration (from dict to models)

**Mitigation**:
- Test each provider independently
- Round-trip tests ensure no data loss
- Incremental rollout (one provider at a time)

## Success Criteria

Code is ready when:

✅ All chunks implemented and tested
✅ make check passes
✅ Profile @mentions work
✅ Runtime @mentions work
✅ All providers handle context correctly
✅ Content at top, @mentions stay as references
✅ NO new kernel APIs added
✅ Orchestrators unchanged
✅ Documentation matches implementation

## Next Steps

✅ **Phase 3 Complete**: Code Plan Ready

**Plan Location**: `ai_working/ddd/code_plan.md`

**Ready for Phase 4**: `/ddd:4-code`

Phase 4 will implement each chunk incrementally with tests.
