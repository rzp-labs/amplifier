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

---

## Detailed File Manifest

### Part A: REQUEST_ENVELOPE_V1 Models

**Kernel (amplifier-core)**:
- [ ] `amplifier_core/message_models.py` - NEW: Complete Pydantic models
- [ ] `amplifier_core/__init__.py` - MODIFY: Export models
- [ ] `amplifier_core/interfaces.py` - MODIFY: Update Provider Protocol
- [ ] `tests/test_message_models.py` - NEW: Model tests

**Providers** (4 modules):
- [ ] `amplifier-module-provider-anthropic/__init__.py` - MODIFY: Use models
- [ ] `amplifier-module-provider-openai/__init__.py` - MODIFY: Use models
- [ ] `amplifier-module-provider-azure-openai/__init__.py` - MODIFY: Use models
- [ ] `amplifier-module-provider-ollama/__init__.py` - MODIFY: Use models

### Part B: @Mention Library

**Kernel Utils** (amplifier-core):
- [ ] `amplifier_core/utils/__init__.py` - NEW: Utils package
- [ ] `amplifier_core/utils/mentions.py` - NEW: Text parsing only
- [ ] `tests/test_mentions_parsing.py` - NEW: Parsing tests

**Shared Library** (amplifier-lib or app-cli/lib):
- [ ] `mention_loading/__init__.py` - NEW: Package
- [ ] `mention_loading/loader.py` - NEW: MentionLoader
- [ ] `mention_loading/resolver.py` - NEW: MentionResolver
- [ ] `mention_loading/deduplicator.py` - NEW: ContentDeduplicator
- [ ] `mention_loading/models.py` - NEW: ContextFile model
- [ ] `tests/test_mention_loader.py` - NEW: Loader tests
- [ ] `tests/test_resolver.py` - NEW: Resolver tests
- [ ] `tests/test_deduplicator.py` - NEW: Dedup tests

### Part C: Integration

**App Layer** (amplifier-app-cli):
- [ ] `commands/run.py` - MODIFY: Process @mentions in user input
- [ ] `profile_system/loader.py` - MODIFY: Process profile markdown @mentions
- [ ] `tests/test_mention_integration.py` - NEW: End-to-end tests

**Documentation** (already completed in Phase 2):
- [x] `docs/REQUEST_ENVELOPE_MODELS.md` - NEW
- [x] `docs/CONTEXT_LOADING.md` - NEW
- [x] `docs/PROFILE_AUTHORING.md` - MODIFIED
- [x] `docs/specs/provider/REQUEST_ENVELOPE_V1.md` - MODIFIED
- [x] `docs/specs/provider/PROVIDER_MODULE_PROTOCOL.md` - MODIFIED
- [x] `amplifier-app-cli/data/context/` - NEW (3 files)
- [x] `amplifier-app-cli/data/profiles/` - MODIFIED (6 profiles)

---

## Implementation Chunks (Detailed)

### Chunk 1: Core Message Models (Foundation)
- Create message_models.py
- Message, ContentBlock types, ChatRequest, ChatResponse
- Unit tests
- **Depends on**: Nothing
- **Enables**: Everything else

### Chunk 2: Core @Mention Utils (Text Processing)
- Create utils/mentions.py
- parse_mentions(), has_mentions()
- Unit tests
- **Depends on**: Nothing
- **Enables**: MentionLoader

### Chunk 3: Shared @Mention Library (File Loading)
- Create amplifier-lib/mention_loading/
- MentionLoader, MentionResolver, ContentDeduplicator
- Unit tests
- **Depends on**: Chunk 1 (Message models), Chunk 2 (parse_mentions)
- **Enables**: App integration

### Chunk 4: App Integration - Profile Loading
- Modify profile_system/loader.py
- Process profile markdown @mentions
- Use existing context.add_message()
- Integration tests
- **Depends on**: Chunk 3
- **Enables**: Profile @mentions

### Chunk 5: App Integration - Runtime Processing
- Modify commands/run.py
- Process user input @mentions
- Use existing context.add_message()
- Integration tests
- **Depends on**: Chunk 3
- **Enables**: Runtime @mentions

### Chunk 6: Provider Updates (4 providers)
- Update each provider to use ChatRequest/ChatResponse
- Convert developer → XML-wrapped user
- Provider-specific tests
- **Depends on**: Chunk 1
- **Enables**: Full system

### Chunk 7: End-to-End Verification
- Test @mentions in profiles
- Test @mentions in user input
- Test recursive loading
- Test deduplication
- Test all providers
- **Depends on**: All previous chunks

---

## Test Strategy

### Unit Tests

**Part A: Message Models**:
- Message validation
- ContentBlock discriminated union
- ChatRequest/ChatResponse serialization
- Extra fields preservation

**Part B: @Mention Utils**:
- parse_mentions extracts correctly
- has_mentions detects correctly
- Edge cases (@@, code blocks, etc.)

**Part B: @Mention Library**:
- MentionLoader loads files
- MentionResolver resolves paths correctly
- ContentDeduplicator deduplicates by content
- Recursive loading works
- Cycle detection works

### Integration Tests

**Profile @mentions**:
- Profile markdown processed
- @mentions loaded
- Context injected
- {{parent_instruction}} works

**Runtime @mentions**:
- User input processed
- @mentions loaded
- Context prepended
- Original @mention stays

**Provider Integration**:
- Each provider converts correctly
- XML wrapping works
- Message order correct

### End-to-End Tests

**Manual scenarios**:
```bash
# Test 1: Profile @mentions
amplifier run --profile dev "test"

# Test 2: Runtime @mentions
amplifier run "Explain @AGENTS.md"

# Test 3: Multiple @mentions
amplifier run "Compare @file1.md and @file2.md"

# Test 4: Recursive @mentions
# (AGENTS.md mentions other files)
amplifier run --profile base "test"
```

---

## Success Criteria

✅ parse_mentions() works (kernel util)  
✅ Message models work (kernel)  
✅ MentionLoader works (shared lib)  
✅ @mentions work in profiles  
✅ @mentions work in user input  
✅ Content at top, @mentions stay as references  
✅ NO new kernel APIs  
✅ Orchestrators unchanged  
✅ Philosophy compliant (zen-architect approved)  
✅ All tests pass  
✅ Documentation complete  

---

## Next Steps

✅ **Phase 1 Complete**: Planning Approved (Zen-Architect Reviewed)

**Plan Location**: `ai_working/ddd/plan.md`

**Architecture**: 
- Kernel: Utils + models only (no new APIs)
- Shared lib: File loading
- App: Integration using existing APIs
- Orchestrators: Unchanged
- Providers: Message conversion

**Ready for Phase 4**: `/ddd:4-code`

The plan is complete, approved, and ready for implementation!
