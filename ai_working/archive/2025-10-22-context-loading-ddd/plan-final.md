# DDD Plan: General-Purpose @Mention System + REQUEST_ENVELOPE_V1 Models

## FINAL ARCHITECTURE (Zen-Architect Approved)

### Key Design Decisions

**1. NO new kernel APIs** - Use existing `context.add_message()`
**2. @mention processing in APP layer** - Policy at edges
**3. Kernel provides ONLY**:
   - Pure text utils (parse_mentions)
   - Message models (REQUEST_ENVELOPE_V1)
   - Existing context API

**4. Flow**:
```
App → parse_mentions (kernel util)
    → MentionLoader (shared lib)
    → context.add_message() (existing kernel API)
    → session.execute()

Orchestrator → Reads from context (no @mention knowledge)
Provider → Converts messages (no @mention knowledge)
```

## Problem Statement

### Three Foundational Pieces

**1. Missing REQUEST_ENVELOPE_V1 Models**
- Spec exists, no Pydantic implementation
- Providers use dict[str, Any] (error-prone)

**2. No Context Loading**
- Main sessions lack rich context
- Profile markdown bodies unused

**3. @Mention Should Be General-Purpose**
- Should work in profiles (session init)
- Should work in user input (runtime)
- Should work anywhere text has @mentions
- Content loads at TOP, @mention stays as reference

### User Value

- Type-safe message handling
- Rich context from @mentioned files
- Natural @mention syntax everywhere
- Clean architecture (policy at edges)

## Proposed Solution

### Three-Part Architecture

**Part A: REQUEST_ENVELOPE_V1 Models** (Kernel)
- Pydantic models in amplifier-core
- Shared across all providers

**Part B: @Mention Library** (Shared + App)
- Kernel utils: parse_mentions (text only)
- Shared lib: MentionLoader (file loading)
- App layer: Integration (policy)

**Part C: Integration** (App + Providers)
- App: Process @mentions, add to context
- Providers: Convert developer → XML-wrapped user

### Clean Data Flow

```
User Input: "Explain @docs/API.md"
    ↓
APP LAYER (Policy):
    ├─ parse_mentions(text)  ← kernel util
    ├─ loader.load_mentions()  ← shared lib  
    ├─ context.add_message(msg)  ← existing kernel API (for each loaded file)
    └─ session.execute(original_text)  ← @mentions stay intact
    ↓
SESSION/ORCHESTRATOR (Mechanism):
    └─ Reads from context (no @mention knowledge)
    ↓
PROVIDER (Policy):
    └─ Converts developer → XML-wrapped user
```

## Key Interfaces

### Kernel APIs (amplifier-core)

**Text Parsing** (new util):
```python
# amplifier_core/utils/mentions.py
def parse_mentions(text: str) -> list[str]:
    """Extract @mentions. Pure text processing."""
    
def has_mentions(text: str) -> bool:
    """Check for @mentions."""
```

**Message Models** (new):
```python
# amplifier_core/message_models.py
class Message(BaseModel):
    role: Literal["system", "developer", "user", "assistant", "function"]
    content: str | list[ContentBlock]
```

**Context API** (EXISTING - no changes):
```python
# amplifier_core/interfaces.py
class ContextManager(Protocol):
    async def add_message(self, message: dict[str, Any]) -> None:
        """Add message to context."""
```

### Shared Library (amplifier-lib or app-cli/lib)

```python
class MentionLoader:
    """Load @mentioned files."""
    
    def load_mentions(self, text: str, search_paths: list[Path]) -> list[Message]:
        """
        Load all @mentioned files from text.
        
        Returns:
            List of Message objects (role=developer) with loaded content
        """
```

### App Layer Integration

```python
# In commands/run.py or session initialization
from amplifier_core.utils.mentions import parse_mentions, has_mentions
from amplifier_lib.mention_loading import MentionLoader

async def handle_user_input(session, user_input: str):
    # Process @mentions (app policy)
    if has_mentions(user_input):
        loader = MentionLoader(search_paths=[bundled, project, user])
        context_messages = loader.load_mentions(user_input)
        
        # Add to context (existing kernel API)
        context = session.coordinator.get("context")
        for msg in context_messages:
            await context.add_message(msg.model_dump())
    
    # Execute (original prompt with @mentions intact)
    return await session.execute(user_input)
```

## Module Boundaries

**Kernel** (`amplifier-core`):
- Utils: parse_mentions (text processing)
- Models: REQUEST_ENVELOPE_V1 Pydantic models
- Context: Existing add_message() API
- NO mention loading, NO file I/O, NO policy

**Shared Library** (`amplifier-lib` or `app-cli/lib`):
- MentionLoader: File loading, deduplication
- MentionResolver: Search path resolution
- ContentDeduplicator: Hash-based
- Depends on: amplifier-core (for parse_mentions, Message)

**App Layer** (`amplifier-app-cli`):
- @mention processing integration
- Profile loading with @mentions
- Runtime input processing with @mentions
- Search path configuration (policy)

**Orchestrators** (`amplifier-module-loop-*`):
- NO changes needed
- NO @mention knowledge
- Just reads from context

**Providers** (`amplifier-module-provider-*`):
- Convert developer → XML-wrapped user
- NO @mention knowledge

## Philosophy Compliance

### Kernel Philosophy ✓

**Mechanism, not policy**:
- ✅ Kernel: parse_mentions (mechanism), Message models (mechanism)
- ✅ App: when/where to load (policy)
- ✅ NO new kernel APIs (reuses existing context.add_message())

**Small, stable, boring**:
- ✅ Kernel adds ONLY: text utils + models
- ✅ NO behavioral changes
- ✅ NO new APIs

**Don't break modules**:
- ✅ Uses existing ContextManager protocol
- ✅ Orchestrators unchanged
- ✅ Providers just convert messages

### Ruthless Simplicity ✓

**Simpler than original proposal**:
- ❌ Original: New Session.add_context() API
- ✅ Final: Reuse existing context.add_message()

**Clear over clever**:
- ✅ App calls kernel util
- ✅ App calls shared lib
- ✅ App calls existing kernel API
- ✅ Straight line, no magic

## Implementation Plan (Revised)

### Part A: REQUEST_ENVELOPE_V1 Models

**Chunk A1**: Create message_models.py in amplifier-core
**Chunk A2**: Update providers to use models

### Part B: @Mention Library

**Chunk B1**: Create utils/mentions.py in amplifier-core (text parsing only)
**Chunk B2**: Create amplifier-lib (or app-cli/lib) with MentionLoader
**Chunk B3**: Integrate in app layer (use existing context.add_message())

### Part C: Integration

**Profile Loading**: App processes profile markdown @mentions
**Runtime Processing**: App processes user input @mentions
**Provider Conversion**: Providers convert developer → XML-wrapped user

## Files to Change

### Kernel (amplifier-core)

**New**:
- [ ] `amplifier_core/utils/__init__.py`
- [ ] `amplifier_core/utils/mentions.py` - Text parsing
- [ ] `amplifier_core/message_models.py` - REQUEST_ENVELOPE_V1 models

**Modified**:
- [ ] `amplifier_core/__init__.py` - Export models and utils
- [ ] `amplifier_core/interfaces.py` - Update Provider Protocol types

**NO changes to**:
- ✅ Session (no new API)
- ✅ Coordinator (no changes)
- ✅ Context protocol (no changes)

### Shared Library

**New package** (amplifier-lib or use app-cli/lib):
- [ ] `mention_loading/__init__.py`
- [ ] `mention_loading/loader.py` - MentionLoader
- [ ] `mention_loading/resolver.py` - MentionResolver
- [ ] `mention_loading/deduplicator.py` - ContentDeduplicator

### App Layer

**Modified**:
- [ ] `amplifier-app-cli/commands/run.py` - Process @mentions before execute
- [ ] `amplifier-app-cli/profile_system/loader.py` - Process profile markdown @mentions

### Providers

**Modified** (4 providers):
- [ ] Each: Use ChatRequest/ChatResponse
- [ ] Each: Convert developer → XML-wrapped user

## Summary

Zen-architect review confirms:

✅ **Simpler**: No new kernel API
✅ **Cleaner**: Reuses existing context.add_message()
✅ **Philosophy compliant**: Mechanism (kernel) vs policy (app)
✅ **Clear boundaries**: Text parsing (core) → File loading (lib) → Integration (app)

**Ready for final plan update and implementation!**
