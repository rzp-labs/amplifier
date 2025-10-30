# Architecture Decision: @Mention Processing Flow

## Zen-Architect Review Summary

**Key Insight**: Use existing kernel APIs, don't add new ones.

## Final Architecture (Philosophy-Compliant)

### Component Placement

**Kernel** (`amplifier-core`):
- `utils/mentions.py` - Pure text parsing (parse_mentions, has_mentions)
- `message_models.py` - REQUEST_ENVELOPE_V1 Pydantic models
- `ContextManager.add_message()` - **EXISTING API** (use this!)
- NO new APIs needed!

**Shared Library** (`amplifier-lib` or `app-cli/lib`):
- `MentionLoader` - File loading and deduplication
- `MentionResolver` - Search path resolution
- `ContentDeduplicator` - Hash-based dedup

**App Layer** (`amplifier-app-cli`):
- Processes user input for @mentions (policy)
- Calls MentionLoader (shared lib)
- Calls context.add_message() for each loaded file (existing kernel API)
- Passes original prompt to orchestrator

**Orchestrators**: No @mention knowledge
**Providers**: Convert developer → XML-wrapped user

### Clean Flow

```python
# App layer (commands/run.py)
user_input = "Explain @docs/API.md"

# 1. Parse @mentions (kernel util)
from amplifier_core.utils.mentions import parse_mentions, has_mentions
if has_mentions(user_input):
    mentions = parse_mentions(user_input)

    # 2. Load files (shared lib)
    from amplifier_lib.mention_loading import MentionLoader
    loader = MentionLoader(search_paths)
    context_messages = loader.load_mentions(user_input)

    # 3. Add to context (existing kernel API - no new API!)
    context = session.coordinator.get("context")
    for msg in context_messages:
        await context.add_message(msg.model_dump())

# 4. Execute (orchestrator sees loaded context)
response = await session.execute(user_input)  # @mentions stay in prompt
```

### Why This is Better

**No new kernel API**:
- ❌ NOT adding `session.add_context()`
- ✅ Using existing `context.add_message()`
- Kernel stays unchanged!

**Policy at edges**:
- App decides: when to process, what search paths, file types
- Different apps can handle differently
- Easy to disable/customize

**Philosophy compliant**:
- ✅ Kernel provides mechanism (parse_mentions, add_message)
- ✅ App provides policy (when/how to load)
- ✅ Small, stable kernel
- ✅ Clear boundaries

## Data Flow

```
User Input
    ↓
App Layer (POLICY)
    ├── parse_mentions(text)  ← kernel util
    ├── MentionLoader.load()  ← shared lib
    └── context.add_message()  ← existing kernel API
    ↓
Session/Orchestrator (MECHANISM)
    └── Executes with loaded context
    ↓
Provider (POLICY)
    └── Converts developer → XML-wrapped user
```

## Decisions

✅ **Use existing `context.add_message()`** - Don't add new kernel API
✅ **@mention processing in app layer** - Policy belongs at edges
✅ **Pure text utils in kernel** - parse_mentions only
✅ **File loading in shared lib** - Reusable, not kernel
✅ **No orchestrator changes** - Orchestrators stay pure

## Next Steps

Update plan.md to reflect:
- No Session.add_context() API
- Use existing context.add_message()
- Clear app layer processing
- Zen-architect approved architecture
