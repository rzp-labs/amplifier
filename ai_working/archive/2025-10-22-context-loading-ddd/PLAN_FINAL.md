# FINAL PLAN: @Mention System + REQUEST_ENVELOPE_V1 Models

**Status**: Zen-Architect Approved  
**Architecture**: Philosophy-Compliant (No new kernel APIs)

## Executive Summary

**Part A**: Create REQUEST_ENVELOPE_V1 Pydantic models in kernel  
**Part B**: Create general-purpose @mention library (kernel utils + shared lib)  
**Part C**: Integrate in app layer using EXISTING kernel APIs  

**Key Insight**: No new kernel APIs needed - use existing `context.add_message()`

## Architecture (Final)

### Component Placement

```
┌────────────────────────────────────────────┐
│ KERNEL (amplifier-core)                    │
│                                             │
│ utils/mentions.py:                         │
│   - parse_mentions(text) → list[str]      │
│   - has_mentions(text) → bool             │
│                                             │
│ message_models.py:                         │
│   - Message, ContentBlock, ChatRequest... │
│                                             │
│ ContextManager (EXISTING):                 │
│   - add_message(dict) ← REUSE THIS        │
└────────────────────────────────────────────┘
               ↓
┌────────────────────────────────────────────┐
│ SHARED LIBRARY (amplifier-lib)             │
│                                             │
│ mention_loading/:                          │
│   - MentionLoader                          │
│   - MentionResolver                        │
│   - ContentDeduplicator                    │
└────────────────────────────────────────────┘
               ↓
┌────────────────────────────────────────────┐
│ APP LAYER (amplifier-app-cli)              │
│                                             │
│ Policy decisions:                          │
│  - When to process @mentions              │
│  - What search paths                      │
│  - How to load files                      │
│                                             │
│ Integration:                               │
│  1. parse_mentions(input)                 │
│  2. MentionLoader.load()                  │
│  3. context.add_message() ← existing!     │
│  4. session.execute(original_input)       │
└────────────────────────────────────────────┘
```

### Clean Flow Example

```python
# App layer (commands/run.py)
from amplifier_core.utils.mentions import has_mentions, parse_mentions
from amplifier_lib.mention_loading import MentionLoader

user_input = "Explain @docs/API.md"

# 1. Check for @mentions (kernel util)
if has_mentions(user_input):
    # 2. Load files (shared lib - policy)
    loader = MentionLoader(search_paths=[bundled, project, user])
    context_messages = loader.load_mentions(user_input)
    
    # 3. Add to context (EXISTING kernel API - no new API!)
    context = session.coordinator.get("context")
    for msg in context_messages:
        await context.add_message(msg.model_dump())

# 4. Execute (orchestrator just reads context, no @mention knowledge)
response = await session.execute(user_input)  # @mentions stay in prompt
```

**Message Stack Result**:
```
[1] role=user: <context_file paths="docs/API.md">[full content]</context_file>
[2] role=user: "Explain @docs/API.md"  ← @mention stays as reference
```

## Philosophy Compliance

**Zen-Architect Approved**:
- ✅ NO new kernel APIs (reuses existing)
- ✅ Policy at edges (app decides when/where)
- ✅ Mechanism in kernel (parse_mentions, Message models)
- ✅ Small, stable kernel
- ✅ Orchestrators unchanged
- ✅ Clear boundaries

## Implementation Order

1. **Part A**: REQUEST_ENVELOPE_V1 models (kernel)
2. **Part B1**: mentions.py utils (kernel)
3. **Part B2**: MentionLoader library (shared lib)
4. **Part C**: App integration (use existing APIs)
5. **Providers**: Update to use models + convert developer → user

## Files to Create/Modify

### Kernel (amplifier-core)

**New**:
- utils/mentions.py (text parsing)
- message_models.py (Pydantic models)

**Modified**:
- __init__.py (exports)
- interfaces.py (Provider Protocol types)

**NOT modified**:
- session.py (no new API!)
- coordinator.py (unchanged)

### Shared Library (amplifier-lib or app-cli/lib)

**New**:
- mention_loading/loader.py
- mention_loading/resolver.py
- mention_loading/deduplicator.py

### App Layer (amplifier-app-cli)

**Modified**:
- commands/run.py (process @mentions in user input)
- profile_system/loader.py (process @mentions in profile markdown)

### Providers (4 modules)

**Modified**:
- Use ChatRequest/ChatResponse
- Convert developer → XML-wrapped user

## Success Criteria

✅ parse_mentions() works (kernel util)  
✅ Message models work (kernel)  
✅ MentionLoader works (shared lib)  
✅ @mentions work in profiles (session init)  
✅ @mentions work in user input (runtime)  
✅ Content at top, @mentions stay as references  
✅ NO new kernel APIs added  
✅ Orchestrators unchanged  
✅ Philosophy compliant  

## Ready for Implementation

**Next**: Update plan.md with this architecture, then proceed to Phase 2 docs updates (if needed) and Phase 4 implementation.
