# DDD Plan: Context Loading System for Amplifier (REVISED)

## Problem Statement

### What We're Solving

Amplifier needs a context loading system that supports:

1. **System instructions** for main sessions (like sub-agents have)
2. **Additional context files** (treated as developer/user messages by providers)
3. **Easy distribution** - profiles must be shareable without complex packaging
4. **Flexible reuse** - shared context across profiles without duplication

**Critical Challenge Identified**: How do context files travel with profiles when:
- Bundling with the app?
- Sharing with other users?
- Distributing via Git repos?

### Why It Matters

**User Value**:
- Main sessions get rich context (like sub-agents already do)
- Profiles can include instructions without editing code
- Context can be shared across profiles (AGENTS.md, DISCOVERIES.md)
- Easy to customize per project/user/profile

**Distribution Problem**:
- ❌ Simple @mention approach doesn't solve distribution
- ❌ File references create "where do I put these?" questions
- ✅ Need solution that handles bundling AND sharing

## Proposed Solution: Hybrid Context System

### Architecture Overview

**Support THREE context loading patterns:**

1. **Inline Context** (self-contained, easy to share)
2. **File References** (reusable, shared context)
3. **Bundled Context Library** (ship common context with app)

### Context Loading Spec

#### Pattern 1: Inline Context (Self-Contained)

**Use case**: Simple profiles that are easy to share

```yaml
# profiles/simple-python.md
---
profile:
  name: simple-python
  version: 1.0.0

context:
  - type: system
    content: |
      You are a Python development assistant.

      Core principles:
      - Write clear, PEP 8 compliant code
      - Use type hints
      - Test everything

  - type: developer
    content: |
      Project uses pytest for testing.
      Code style enforced by ruff.
---

# Python Development Profile

Simple, self-contained profile for Python work.
```

**Distribution**: ✅ Single file, easy to share (email, paste, gist)

#### Pattern 2: File References (Reusable Context)

**Use case**: Projects with shared context files

```yaml
# .amplifier/profiles/team-standard.md
---
profile:
  name: team-standard
  version: 1.0.0

context:
  - type: system
    file: ./context/system-instruction.md
  - type: developer
    file: ./context/team-guidelines.md
  - type: developer
    file: @bundled/context/AGENTS.md  # Reference bundled file
---

# Team Standard Profile

Uses context files from .amplifier/context/
```

**Distribution**: ✅ Via Git (natural - whole `.amplifier/` directory travels)

#### Pattern 3: Bundled Context Library

**Use case**: App-bundled profiles with common context

```yaml
# amplifier_app_cli/data/profiles/dev.md
---
profile:
  name: dev
  version: 1.2.0
  extends: base

context:
  - type: system
    file: @bundled/context/dev-system.md
  - type: developer
    file: @bundled/context/AGENTS.md
  - type: user  # Will be user message for some providers
    file: @bundled/context/DISCOVERIES.md
---

# Development Profile

Uses bundled context from app package data.
```

**Distribution**: ✅ Packaged with app (works out of the box)

### File Reference Resolution

**Resolution Order**:

1. `@bundled/path` → `amplifier_app_cli/data/path` (shipped with app)
2. `./path` → Relative to profile file location
3. `~/path` or absolute → Explicit paths
4. `@ai_context/FILE.md` → Special shorthand for `@bundled/ai_context/FILE.md`

**Examples**:
- `@bundled/context/AGENTS.md` → App's bundled AGENTS.md
- `./context/custom.md` → `.amplifier/context/custom.md` (if profile in `.amplifier/profiles/`)
- `~/my-contexts/special.md` → User's home directory
- `@ai_context/KERNEL_PHILOSOPHY.md` → Bundled philosophy doc

### Context Message Types

Different providers handle context differently:

```yaml
context:
  - type: system  # Always system message (all providers)
  - type: developer  # Developer message (Anthropic), system or user (others)
  - type: user  # User message (all providers)
```

**Provider Behavior**:
- **Anthropic**: system, developer (as developer msgs), user
- **OpenAI**: system (merged), user
- **Others**: Best-effort mapping

## Alternatives Considered

### Option A: Inline Only (Simplest)

```yaml
context:
  - type: system
    content: |
      All context inline in YAML
```

**Pros**: Self-contained, easy to share
**Cons**: No reuse, large files, hard to maintain
**Decision**: Too limiting for complex use cases

### Option B: File References Only

```yaml
context:
  - type: system
    file: ./system.md
```

**Pros**: Reusable, maintainable
**Cons**: Distribution problem, hard to share simple profiles
**Decision**: Too complex for simple use cases

### Option C: Hybrid (Inline + File References) ✅ SELECTED

```yaml
context:
  - type: system
    content: |
      Inline critical content
  - type: developer
    file: @bundled/shared.md
```

**Pros**: Flexibility, handles all scenarios
**Cons**: Two ways to load context
**Decision**: ✅ **CHOSEN** - Best of both worlds

### Option D: Profile Packages (Archives)

Package profiles as archives with context files:

```
my-profile.amplifier.tar.gz/
  ├── profile.yaml
  ├── context/
  └── agents/
```

**Pros**: Complete bundling
**Cons**: Complex, needs unpacking tooling
**Decision**: Rejected - Over-engineering for this problem

## Architecture & Design

### Key Interfaces

#### Context Entry Schema

```python
@dataclass
class ContextEntry:
    """Single context entry in profile."""
    type: Literal["system", "developer", "user"]
    content: str | None = None  # Inline content
    file: str | None = None  # File reference

    # Exactly one of content or file must be set
```

#### ContextLoader Interface

```python
class ContextLoader:
    """Load and inject context from profile configuration."""

    def load_context_for_profile(
        self,
        profile: Profile,
        context_manager: ContextManager,
        profile_path: Path | None = None
    ) -> None:
        """
        Load context entries and inject into session.

        Args:
            profile: Profile with context configuration
            context_manager: Session's context manager
            profile_path: Path to profile file (for relative resolution)
        """
        pass

    def resolve_file_reference(
        self,
        file_ref: str,
        profile_path: Path | None
    ) -> Path:
        """
        Resolve file reference to actual path.

        Supports:
        - @bundled/path → App bundle
        - ./path → Relative to profile
        - ~/path → User home
        - /path → Absolute
        """
        pass
```

### Module Boundaries

**App Layer** (`amplifier-app-cli`):
- Context loading configuration (YAML schema)
- File reference resolution (@bundled, relative, absolute)
- Context injection orchestration
- Provider-specific message type mapping

**Bundled Context** (`amplifier-app-cli/data/context/`):
- AGENTS.md - Shared project guidelines
- DISCOVERIES.md - Shared learnings
- Standard system instructions
- Philosophy documents

**Kernel** (`amplifier-core`):
- NO CHANGES
- Uses existing `context.add_message()` mechanism

### Data Flow

```
1. Profile Loading
   └── Load profile.md → Profile object with context config

2. Mount Plan Compilation
   └── Profile → Mount Plan (context config preserved)

3. Session Creation + Initialization
   └── Mount Plan → AmplifierSession → Mount modules

4. Context Loading (NEW)
   ├── For each context entry:
   │   ├── If inline: Use content directly
   │   ├── If file ref: Resolve path → load file
   │   └── Map type to message role (provider-specific)
   ├── Inject via context.add_message()
   └── Preserve order (system first, then developer, then user)

5. Execution
   └── LLM sees system instruction + context + user prompt
```

## Files to Change

### Non-Code Files (Phase 2 - Documentation)

#### Bundled Context Files (New)

- [ ] `amplifier-app-cli/amplifier_app_cli/data/context/` - New directory
- [ ] `amplifier-app-cli/amplifier_app_cli/data/context/AGENTS.md` - Shared guidelines
- [ ] `amplifier-app-cli/amplifier_app_cli/data/context/DISCOVERIES.md` - Shared learnings
- [ ] `amplifier-app-cli/amplifier_app_cli/data/context/dev-system.md` - Dev profile system instruction
- [ ] `amplifier-app-cli/amplifier_app_cli/data/context/README.md` - Context library docs

#### Documentation Updates

- [ ] `docs/CONTEXT_LOADING.md` - New: Complete context loading guide
- [ ] `docs/PROFILE_AUTHORING.md` - Update: Context configuration section
- [ ] `docs/USER_ONBOARDING.md` - Update: Mention context customization
- [ ] `docs/README.md` - Update: Link to context docs
- [ ] `docs/AMPLIFIER_CONTEXT_GUIDE.md` - Update: Context loading architecture

#### Profile Updates (Add Context Examples)

- [ ] `amplifier-app-cli/amplifier_app_cli/data/profiles/foundation.md` - Add minimal context example
- [ ] `amplifier-app-cli/amplifier_app_cli/data/profiles/base.md` - Add base context
- [ ] `amplifier-app-cli/amplifier_app_cli/data/profiles/dev.md` - Add full context with file refs
- [ ] `amplifier-app-cli/amplifier_app_cli/data/profiles/production.md` - Add production context

### Code Files (Phase 4 - Implementation)

#### New Files

- [ ] `amplifier-app-cli/amplifier_app_cli/context_loader.py` - Main context loading logic
- [ ] `amplifier-app-cli/amplifier_app_cli/context_resolver.py` - File reference resolution
- [ ] `amplifier-app-cli/amplifier_app_cli/profile_system/context_schema.py` - Context entry Pydantic models

#### Modified Files

- [ ] `amplifier-app-cli/amplifier_app_cli/profile_system/schema.py` - Add context field to Profile model
- [ ] `amplifier-app-cli/amplifier_app_cli/profile_system/loader.py` - Parse context from YAML
- [ ] `amplifier-app-cli/amplifier_app_cli/commands/run.py` - Call context loader after session init
- [ ] `amplifier-app-cli/amplifier_app_cli/commands/profile.py` - Show context in `profile show`

#### Test Files

- [ ] `amplifier-app-cli/tests/test_context_loader.py` - Context loading tests
- [ ] `amplifier-app-cli/tests/test_context_resolver.py` - File resolution tests
- [ ] `amplifier-app-cli/tests/test_context_integration.py` - End-to-end tests
- [ ] `amplifier-app-cli/tests/fixtures/profiles/` - Test profiles with context

## Philosophy Alignment

### Ruthless Simplicity ✓

**Start minimal:**
- ✅ Phase 1: Inline context only (simplest)
- ✅ Phase 2: Add file references if needed
- ✅ Phase 3: Add @bundled shorthand if needed

**Avoid future-proofing:**
- ❌ NOT building template engines
- ❌ NOT building context inheritance
- ❌ NOT building runtime reloading
- ❌ NOT building profile packages/archives

**Clear over clever:**
- ✅ Explicit inline vs file choice
- ✅ Simple @ prefix for bundled files
- ✅ Standard relative/absolute paths

### Modular Design ✓

**Bricks (Self-Contained):**
- `ContextLoader` - Loads and injects context
- `ContextResolver` - Resolves file references
- `ContextEntry` - Data model for context

**Studs (Interfaces):**
- Input: Profile with context config
- Output: Messages in context manager
- Mechanism: `context.add_message()` (exists!)

**Regeneratable:**
- Isolated app-layer code
- Clear specs and contracts
- No kernel dependencies

### Kernel Philosophy ✓

**Mechanism, not policy:**
- ✅ Kernel: `context.add_message()` mechanism (unchanged)
- ✅ App: Decides what/when/how to load

**Small, stable, boring:**
- ✅ Kernel completely unchanged
- ✅ All new code at app layer
- ✅ No new kernel APIs

**Text-first, inspectable:**
- ✅ Context files are plain markdown
- ✅ YAML config is readable
- ✅ No binary formats

## Distribution Scenarios

### Scenario 1: Bundled Profiles (Works Out of Box)

```
amplifier-app-cli/data/
  ├── profiles/
  │   └── dev.md (references @bundled/...)
  └── context/
      ├── AGENTS.md
      └── dev-system.md
```

**Distribution**: ✅ Packaged together in wheel/pip install

### Scenario 2: Simple User-Shared Profile

```yaml
# Share this single file via email/paste/gist
context:
  - type: system
    content: |
      Inline instructions
```

**Distribution**: ✅ Self-contained, copy-paste friendly

### Scenario 3: Project Profiles (Git Repo)

```
.amplifier/
  ├── profiles/
  │   └── team.md (references ./context/...)
  └── context/
      ├── system.md
      └── guidelines.md
```

**Distribution**: ✅ Natural - whole `.amplifier/` dir in git

### Scenario 4: Complex Shared Profile

Option A (self-contained):
```yaml
# Inline everything for easy sharing
context:
  - type: system
    content: |
      ... (all content inline)
```

Option B (with instructions):
```
Share these files together:
1. profiles/my-profile.md
2. context/custom-system.md
3. context/guidelines.md

User puts them in:
- ~/.amplifier/profiles/my-profile.md
- ~/.amplifier/context/custom-system.md
- ~/.amplifier/context/guidelines.md
```

## Test Strategy

### Unit Tests

**ContextLoader:**
- Load inline context
- Load context from file reference
- Handle missing files gracefully
- Map message types correctly
- Preserve context order

**ContextResolver:**
- Resolve @bundled/ references
- Resolve relative paths (./context/file.md)
- Resolve absolute paths
- Resolve ~ paths
- Handle @ai_context/ shorthand

**Context Schema:**
- Validate context entries
- Require content XOR file
- Validate type enum
- YAML parsing

### Integration Tests

**End-to-End:**
- Create session with inline context
- Create session with file references
- Verify messages in context manager
- Test @bundled/ resolution
- Test relative path resolution
- Test profile with mixed inline + file refs

### User Testing

**Manual Scenarios:**

```bash
# Test 1: Inline context
cat > ~/.amplifier/profiles/test-inline.md << 'EOF'
---
profile:
  name: test-inline
context:
  - type: system
    content: |
      Test system instruction
---
EOF

amplifier run --profile test-inline "test"

# Test 2: File reference
mkdir -p ~/.amplifier/context
echo "Test context" > ~/.amplifier/context/test.md

cat > ~/.amplifier/profiles/test-file.md << 'EOF'
---
profile:
  name: test-file
context:
  - type: developer
    file: ~/. amplifier/context/test.md
---
EOF

amplifier run --profile test-file "test"

# Test 3: Bundled reference
amplifier run --profile dev "test"  # Uses @bundled/context/...
```

## Implementation Approach

### Phase 2: Documentation Retcon

1. **Create bundled context files** (`data/context/*.md`)
2. **Write `docs/CONTEXT_LOADING.md`** - Complete guide
3. **Update profile docs** with context examples
4. **Update existing profiles** to use context config
5. **Create example context files** for users

### Phase 4: Code Implementation

**Chunk 1: Context Schema** (foundation)
- Add `context` field to Profile model
- ContextEntry Pydantic model
- Validation (content XOR file)
- Unit tests

**Chunk 2: ContextResolver** (file resolution)
- Resolve @bundled/ references
- Resolve relative/absolute paths
- Handle missing files
- Unit tests

**Chunk 3: ContextLoader** (main logic)
- Load inline context
- Load from file references
- Map types to message roles
- Inject via context.add_message()
- Unit tests

**Chunk 4: Integration** (wire it up)
- Modify commands/run.py
- Call ContextLoader after session.initialize()
- Handle errors gracefully
- Integration tests

**Chunk 5: CLI Enhancement**
- `amplifier profile show` displays context config
- `amplifier profile validate` checks context refs
- Help text and examples

## Success Criteria

### Functional Requirements

✅ Inline context works (self-contained profiles)
✅ File references work (reusable context)
✅ @bundled/ references work (app-bundled context)
✅ Relative paths work (project context)
✅ Provider-specific message type mapping works
✅ Context loads in correct order (system → developer → user)
✅ Missing files fail gracefully with clear errors

### Distribution Requirements

✅ Bundled profiles work out of box (shipped with app)
✅ Simple profiles easy to share (single file)
✅ Project profiles work via git (natural bundling)
✅ Complex profiles have clear sharing instructions

### Quality Requirements

✅ All unit tests pass (>90% coverage)
✅ Integration tests verify end-to-end
✅ Manual testing confirms usability
✅ Documentation complete and accurate
✅ Examples work when copy-pasted
✅ Cold start impact <100ms

### Philosophy Requirements

✅ Kernel unchanged (pure mechanism/policy separation)
✅ App layer only (all new code at edges)
✅ Ruthless simplicity (start minimal, grow as needed)
✅ Clear contracts (well-defined interfaces)
✅ Regeneratable (isolated, well-specified)

## Open Questions

### 1. Should we support @mentions within context files?

**Option A**: Yes - context files can reference other files
```markdown
# system.md
Load shared guidelines:
@AGENTS.md
@DISCOVERIES.md

Then add: ...
```

**Option B**: No - only direct file references in YAML

**Recommendation**: **Option B** initially (simpler), add @mentions later if needed

**Rationale**: KISS - start with simplest that works

### 2. Should context loading be opt-in or opt-out?

**Option A**: Opt-out (enabled by default)
```yaml
context_loading: false  # Disable if needed
```

**Option B**: Opt-in (explicit config required)
```yaml
context:  # Must specify to enable
  - type: system
```

**Recommendation**: **Option B** (opt-in via explicit `context:` section)

**Rationale**: Backward compatible, no surprise behavior

### 3. How should we handle missing referenced files?

**Option A**: Fail session startup with clear error
**Option B**: Log warning and continue
**Option C**: Replace with placeholder message

**Recommendation**: **Option A** (fail fast)

**Rationale**: Missing context = wrong behavior, better to fail early

### 4. Should profile markdown body still be used?

**Earlier plan**: Use markdown body as readme/description
**Agents**: Use markdown body as system instruction

**Options**:
- **A**: Profile body = readme only (context goes in YAML)
- **B**: Profile body = system instruction (like agents) + YAML context for additional
- **C**: User choice (if context config missing, try markdown body)

**Recommendation**: **Option A** (body = readme)

**Rationale**:
- Clearer separation (config in YAML, description in markdown)
- Agents use body because they don't have markdown sections, profiles do
- Consistent with using markdown space for documentation

## Summary

This revised plan solves the distribution problem by supporting THREE patterns:

1. **Inline context** - Self-contained profiles (easy sharing)
2. **File references** - Reusable context (project context, bundled context)
3. **Hybrid** - Mix inline + references for flexibility

**Distribution solved**:
- ✅ Bundled profiles: Package context with app
- ✅ Simple sharing: Single file with inline context
- ✅ Project sharing: Git repo includes `.amplifier/` directory
- ✅ Complex sharing: Clear instructions or inline everything

**Key Design Decisions**:
- Inline content XOR file reference (not both)
- @bundled/ for app-packaged context
- Relative paths work naturally for projects
- No profile packages/archives (unnecessary complexity)
- No @mentions in context files initially (KISS)
- Context loading is opt-in (backward compatible)
- Profile markdown body = README (not system instruction)

**Philosophy aligned**:
- Kernel unchanged (pure app layer)
- Start simple (inline only), grow as needed (add file refs)
- Clear over clever (explicit inline vs file choice)
- Modular and regeneratable

**Ready for user review and feedback!**
