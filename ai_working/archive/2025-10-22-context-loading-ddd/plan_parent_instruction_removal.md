# DDD Plan: Remove {{parent_instruction}}, Use @Mentions for DRY

**Date**: 2025-10-22
**Status**: Ready for Execution
**Phase**: Planning Complete → Ready for Phase 2 (Docs)

---

## Problem Statement

### What We're Solving

**Problem**: Copy-paste pain across agent and profile definitions

**Current State**:
- ✅ @mention system implemented and working
- ❌ `{{parent_instruction}}` documented but NOT implemented
- ❌ 5 bundled profiles contain literal text "{{parent_instruction}}"
- ❌ Agent definitions copy-paste shared instructions (DRY violation)

**User's Use Case**:
> "we have common/base instructions across subagents, currently copy & paste into each one - wanted to avoid that"

**Evidence**: User experiences copy-paste pain, wants single source of truth

### Why It Matters

**User Value**:
- ✅ **DRY achieved**: Update shared instructions in ONE place
- ✅ **Consistency**: All agents/profiles use same base instructions
- ✅ **Maintainability**: Change once, affects all
- ✅ **Clarity**: Explicit @mentions show what's included

---

## Proposed Solution

### Use @Mentions for Shared Instructions (ALREADY WORKS!)

**Pattern**:
```markdown
# 1. Create shared base instruction file
amplifier-dev/shared/common-agent-base.md

# 2. Reference in each agent/profile
@shared/common-agent-base.md

# 3. Update once, affects all
```

**Why This Wins**:
- ✅ **Zero implementation** - @mentions already work
- ✅ **Solves DRY completely** - Single source of truth
- ✅ **More flexible** - Can compose multiple shared files
- ✅ **Philosophy-aligned** - Ruthless simplicity (reuse > add)
- ✅ **Explicit** - Clear what's being included
- ✅ **Available TODAY** - User can start immediately

### Remove {{parent_instruction}} (Cleanup Documented-But-Unimplemented Feature)

**Current situation**:
- Documented in: CONTEXT_LOADING.md, PROFILE_AUTHORING.md
- Used in 5 bundled profiles: base.md, dev.md, test.md, full.md, production.md
- **Implementation**: NONE - literal text remains in files

**Action**: Remove and rewrite profiles to use @mentions

---

## Architecture & Design

### Shared Instruction Pattern

**Directory structure**:
```
amplifier-dev/
├── shared/
│   ├── common-agent-base.md       # Core instructions for all agents
│   ├── common-profile-base.md     # Core instructions for profiles
│   └── README.md                  # Documents shared instruction library
├── amplifier-app-cli/
│   └── data/
│       ├── agents/
│       │   ├── zen-architect.md   # Uses @shared/common-agent-base.md
│       │   ├── bug-hunter.md      # Uses @shared/common-agent-base.md
│       │   └── ...
│       └── profiles/
│           ├── base.md            # Removes {{parent_instruction}}
│           ├── dev.md             # Uses @shared/common-profile-base.md
│           └── ...
```

### Resolution Path

**@mentions resolve from**:
1. Current working directory
2. Bundled context (`amplifier-app-cli/data/context/`)
3. Project context (`.amplifier/context/`)
4. User context (`~/.amplifier/context/`)

**Shared files location options**:
- **Option A**: `amplifier-dev/shared/` (project root)
- **Option B**: `amplifier-app-cli/data/shared/` (bundled with package)
- **Option C**: `amplifier-app-cli/data/context/shared/` (in existing context dir)

**Recommendation**: Option C - keeps shared files with other bundled context

### Content from AGENT_PROMPT_INCLUDE.md

**User request**: "consider the contents of the AGENT_PROMPT_INCLUDE.md in @.claude/ for use as that shared base"

**File location**: `/home/brkrabac/repos/amplifier.amplifier-v2-codespace/.claude/AGENT_PROMPT_INCLUDE.md`

**Content**: Claude Code-specific agent instructions (tone, style, proactiveness, task management)

**Action**:
- Review content for Amplifier applicability
- Extract relevant shared instructions
- Create `shared/common-agent-base.md` with adapted content
- Remove Claude Code-specific parts

---

## Files to Change

### Phase 2: Documentation Updates

#### New Files

- [ ] `amplifier-app-cli/data/context/shared/common-agent-base.md` - Shared agent instructions (adapted from AGENT_PROMPT_INCLUDE.md)
- [ ] `amplifier-app-cli/data/context/shared/README.md` - Documents shared instruction library

#### Files to Update - Remove {{parent_instruction}}

- [ ] `amplifier-app-cli/data/profiles/base.md` - Remove {{parent_instruction}}, rewrite with complete instructions or @mention
- [ ] `amplifier-app-cli/data/profiles/dev.md` - Remove {{parent_instruction}}, use @shared pattern
- [ ] `amplifier-app-cli/data/profiles/test.md` - Remove {{parent_instruction}}, rewrite
- [ ] `amplifier-app-cli/data/profiles/full.md` - Remove {{parent_instruction}}, rewrite
- [ ] `amplifier-app-cli/data/profiles/production.md` - Remove {{parent_instruction}}, rewrite

#### Files to Update - Documentation

- [ ] `docs/CONTEXT_LOADING.md` - Remove {{parent_instruction}} documentation, add @mention DRY pattern
- [ ] `docs/PROFILE_AUTHORING.md` - Remove {{parent_instruction}}, document @mention for shared instructions
- [ ] `docs/PROFILES.md` - Clarify that YAML extends, not markdown body inheritance
- [ ] `amplifier-app-cli/data/profiles/README.md` - Remove {{parent_instruction}} reference

#### Files to Update - Agent Definitions (Optional Enhancement)

- [ ] `amplifier-app-cli/data/agents/zen-architect.md` - Add @shared/common-agent-base.md
- [ ] `amplifier-app-cli/data/agents/bug-hunter.md` - Add @shared/common-agent-base.md
- [ ] `amplifier-app-cli/data/agents/modular-builder.md` - Add @shared/common-agent-base.md
- [ ] `amplifier-app-cli/data/agents/researcher.md` - Add @shared/common-agent-base.md

### Phase 4: No Code Changes Needed! ✅

**@mention system already works** - No implementation required!

---

## Detailed Changeplan

### Step 1: Create Shared Instruction Files

**File**: `amplifier-app-cli/data/context/shared/common-agent-base.md`

**Content** (adapted from AGENT_PROMPT_INCLUDE.md):
```markdown
# Common Agent Base Instructions

## Task Management

Use TodoWrite tools to track all tasks. Mark todos complete immediately.

## Code Conventions

- Follow existing patterns
- Check for libraries before assuming
- Mimic code style
- Never add comments unless asked
- Security best practices always

## Proactiveness

- Balance doing right thing vs. surprising user
- Answer questions before taking action
- Be helpful, not presumptuous

## Documentation

- Keep responses concise
- Output tokens matter
- Direct answers preferred
```

**File**: `amplifier-app-cli/data/context/shared/README.md`

**Content**:
```markdown
# Shared Instruction Library

This directory contains shared instruction files referenced by agents and profiles.

## Files

- `common-agent-base.md` - Core instructions for all agents
- `common-profile-base.md` - Core instructions for profiles (if needed)

## Usage

Reference shared files with @mentions:

```markdown
# In agent definition
@shared/common-agent-base.md

Agent-specific instructions...
```

## Maintenance

Update shared files in this directory.
Changes propagate to all agents/profiles that @mention them.
```

### Step 2: Remove {{parent_instruction}} from Profiles

**For each profile** (base.md, dev.md, test.md, full.md, production.md):

**Current**:
```markdown
---
profile:
  extends: foundation
---

{{parent_instruction}}

[Profile-specific content]
```

**New**:
```markdown
---
profile:
  extends: foundation  # YAML config inheritance only
---

[Complete, independent instructions for this profile]
[Optional: @shared/common-profile-base.md if DRY needed]
```

### Step 3: Update Agent Definitions (Optional)

**For each agent** (zen-architect.md, bug-hunter.md, etc.):

**Add to beginning of markdown body**:
```markdown
@shared/common-agent-base.md
```

### Step 4: Update Documentation

**CONTEXT_LOADING.md**:
- Remove {{parent_instruction}} sections
- Add section: "DRY with Shared Instructions"
- Show @mention pattern for shared content

**PROFILE_AUTHORING.md**:
- Remove {{parent_instruction}} documentation
- Add section: "Sharing Instructions with @Mentions"
- Example: Creating and using shared instruction files

**PROFILES.md**:
- Clarify: "`extends:` inherits YAML config, not markdown body"
- Document: "Use @mentions for shared markdown content"

---

## Philosophy Alignment

### Ruthless Simplicity ✅

**Start minimal**: ✅ Use what exists (@mentions)
**Avoid future-proofing**: ✅ Don't build {{parent_instruction}} template system
**Clear over clever**: ✅ Explicit @mentions > implicit template expansion
**Question everything**: ✅ "Do we need {{parent_instruction}}?" → NO

### Decision Framework ✅

1. **Necessity**: "Do we need this?" → NO (@mentions solve it)
2. **Simplicity**: "Simplest solution?" → @mentions (already exists)
3. **Directness**: "More direct?" → @mentions (explicit reference)
4. **Value**: "Complexity worth it?" → NO (0 code > 30 lines)
5. **Maintenance**: "Easy to understand?" → YES (@mentions clear)

### Two-Implementation Rule ✅

**From KERNEL_PHILOSOPHY.md**:
> "Do not promote a new concept until at least two independent modules have converged on the need."

**Current**: ZERO modules need {{parent_instruction}} - it's not even implemented!

**Verdict**: Don't build it

---

## Test Strategy

### No New Tests Needed ✅

**Why**: @mention system already tested

**Existing tests verify**:
- @mention parsing
- File resolution
- Recursive loading
- Deduplication

**Manual verification**:
1. Update one profile to use @shared pattern
2. Verify profile loads correctly
3. Verify shared content appears
4. Verify updates to shared file propagate

---

## Implementation Approach

### Phase 2: Documentation (Retcon)

**Time**: ~2-3 hours

**Tasks**:
1. Create shared instruction files (30 min)
   - `shared/common-agent-base.md` (adapt from AGENT_PROMPT_INCLUDE.md)
   - `shared/README.md`

2. Remove {{parent_instruction}} from profiles (1 hour)
   - base.md, dev.md, test.md, full.md, production.md
   - Rewrite each with complete instructions

3. Update documentation (1 hour)
   - CONTEXT_LOADING.md: Remove {{parent_instruction}}, add @mention DRY pattern
   - PROFILE_AUTHORING.md: Document @mention sharing pattern
   - PROFILES.md: Clarify extends scope

4. Optional: Update agent definitions (30 min)
   - Add @shared/common-agent-base.md to existing agents

### Phase 4: Code Changes

**NONE NEEDED!** ✅

@mention system already implements everything required.

---

## Success Criteria

### Functional

- ✅ {{parent_instruction}} removed from all profiles
- ✅ Shared instruction files created
- ✅ Profiles load correctly without {{parent_instruction}}
- ✅ @mention pattern works for DRY
- ✅ Documentation accurate (no unimplemented features)

### User Experience

- ✅ User can create shared/common-base.md
- ✅ User can @mention it from agents/profiles
- ✅ Updates to shared file propagate automatically
- ✅ DRY problem solved

### Philosophy

- ✅ No new code (uses existing @mentions)
- ✅ Ruthlessly simple
- ✅ No unimplemented documented features
- ✅ Clear and explicit

---

## Detailed File Changes

### 1. Create: `shared/common-agent-base.md`

**Content** (adapted from AGENT_PROMPT_INCLUDE.md):
```markdown
# Common Agent Base Instructions

Core instructions shared across all Amplifier agents.

## Task Management

- Use TodoWrite tools to track all tasks
- Mark todos complete immediately after finishing
- Break down complex tasks into smaller steps
- Give user visibility into progress

## Code Conventions

When making changes:
- First understand file's code conventions
- Mimic code style
- Use existing libraries and utilities
- Follow existing patterns
- Never assume libraries - check first
- Study existing components before creating new ones
- Always follow security best practices

## Code Style

- DO NOT add comments unless asked
- Keep code clean and self-documenting

## Proactiveness

- Be proactive when user asks you to do something
- Answer questions before taking action (if user is asking how)
- Strike balance between helpful and surprising

## Tool Usage

- Use TodoWrite frequently for planning
- Use specialized agents when appropriate
- Search extensively to understand codebase
- Verify solutions with tests when possible
- Run lint and typecheck before finishing

## Quality Standards

- Test your work
- Follow project philosophies
- Consult @IMPLEMENTATION_PHILOSOPHY.md
- Check @DISCOVERIES.md for patterns
- Document decisions when significant

## Remember

- Output tokens matter - be concise when appropriate
- Direct answers for direct questions
- Detailed explanations when needed
- User experience first
```

**Purpose**: Single source of truth for shared agent instructions

### 2. Update: `base.md`

**Current**:
```markdown
---
profile:
  extends: foundation
---

{{parent_instruction}}

Base profile adds core tools and hooks.
```

**New**:
```markdown
---
profile:
  extends: foundation
---

Base configuration for Amplifier development.

Extends foundation with:
- Core development tools (filesystem, bash, web)
- Essential hooks (logging, backup)
- Comprehensive context loading

This profile provides a solid foundation for all development work.
```

### 3. Update: `dev.md`

**Current**:
```markdown
---
profile:
  extends: base
---

{{parent_instruction}}

Development profile with extended capabilities.
```

**New**:
```markdown
---
profile:
  extends: base
---

Development configuration with extended capabilities.

Core context files loaded:
- @AGENTS.md
- @DISCOVERIES.md
- @ai_context/IMPLEMENTATION_PHILOSOPHY.md
- @ai_context/MODULAR_DESIGN_PHILOSOPHY.md

This profile provides rich context for development work,
including project guidelines, learnings, and philosophy.
```

### 4. Update: `test.md`

**Current**:
```markdown
---
profile:
  extends: foundation
---

{{parent_instruction}}

Test profile with mock provider.
```

**New**:
```markdown
---
profile:
  extends: foundation
---

Testing configuration with predictable mock provider.

This profile uses mock provider for:
- Deterministic testing
- No API costs
- Offline development
- Quick iteration
```

### 5. Update: `full.md`

**Current**:
```markdown
---
profile:
  extends: base
---

{{parent_instruction}}

Full profile with all modules enabled.
```

**New**:
```markdown
---
profile:
  extends: base
---

Complete configuration with all modules and capabilities enabled.

Context files:
- @AGENTS.md
- @DISCOVERIES.md
- @ai_context/IMPLEMENTATION_PHILOSOPHY.md

This profile demonstrates the full power of Amplifier's modular system.
```

### 6. Update: `production.md`

**Current**:
```markdown
---
profile:
  extends: base
---

{{parent_instruction}}

Production profile with safety and observability.
```

**New**:
```markdown
---
profile:
  extends: base
---

Production configuration with enhanced safety and observability.

Safety features:
- Approval hooks for sensitive operations
- Comprehensive logging
- Error tracking
- Performance monitoring

This profile prioritizes reliability and auditability for production use.
```

### 7. Update: `CONTEXT_LOADING.md`

**Remove sections**:
- All {{parent_instruction}} examples
- Template variable documentation

**Add section**:
```markdown
## Sharing Instructions with @Mentions

Create reusable instruction files for DRY:

### Pattern

1. Create shared file:
```markdown
# shared/common-base.md
Shared instructions for multiple agents/profiles...
```

2. Reference in profiles/agents:
```markdown
@shared/common-base.md

Additional profile-specific instructions...
```

3. Update shared file once, all references benefit

### Example

```markdown
# Create shared agent base
amplifier-dev/shared/common-agent-base.md

# Use in agents
# .claude/agents/specialized.md
@shared/common-agent-base.md

Specialized agent instructions...
```

### Benefits

- Single source of truth
- Consistent across agents/profiles
- Easy maintenance
- Explicit and clear
```

### 8. Update: `PROFILE_AUTHORING.md`

**Remove**: {{parent_instruction}} section

**Add**:
```markdown
## Sharing Instructions with @Mentions

To avoid copy-pasting shared instructions:

1. **Create shared file**:
```markdown
# shared/common-instructions.md
Core instructions for all profiles...
```

2. **Reference in profile**:
```markdown
---
profile:
  name: my-profile
---

@shared/common-instructions.md

Profile-specific additions...
```

3. **Update once, affects all**

### When to Use

- Common instructions across multiple profiles
- Shared philosophy or guidelines
- Reusable context files

### Profile Inheritance Note

The `extends:` field in YAML frontmatter inherits:
- Session configuration
- Provider/tool/hook lists
- Module settings

It does NOT inherit markdown body. Use @mentions for shared markdown content.
```

### 9. Optional: Update Agent Definitions

**For each agent**, add to top of markdown body:
```markdown
@shared/common-agent-base.md
```

**Benefits**:
- Consistent base instructions
- Easy to update all agents
- Solves user's DRY problem

---

## Philosophy Alignment Check

### Ruthless Simplicity ✅

**Before**:
- Feature documented but not implemented
- Would require 20-30 lines of template code
- New concept to maintain

**After**:
- Use existing @mention system
- Zero new code
- No new concepts

**Verdict**: ✅ Much simpler

### YAGNI ✅

**Question**: "Do we need {{parent_instruction}}?"

**Answer**: NO - @mentions solve the problem

**Evidence**:
- Feature never implemented
- No user complaints
- @mentions work today

**Verdict**: ✅ Don't build it

### Separation of Concerns ✅

**YAML `extends:`** → Config inheritance (modules, settings)
**Markdown body** → Profile-specific instructions

**These are separate concerns** - no need to couple them

**Verdict**: ✅ Keep them separate

### Trust in Emergence ✅

**Pattern emerges naturally**:
1. User wants DRY
2. @mentions exist
3. User creates shared files
4. Composition emerges organically

**No forced coupling needed**

**Verdict**: ✅ Let pattern emerge

---

## Success Metrics

### Before

❌ 5 profiles with unimplemented {{parent_instruction}}
❌ Context poisoning risk (documented feature doesn't exist)
❌ User copy-pastes shared instructions

### After

✅ All profiles with clean, complete instructions
✅ Zero unimplemented features
✅ User has shared instruction pattern
✅ DRY achieved with @mentions
✅ No new code needed

---

## Risk Assessment

### Risks

**Risk 1**: Users might miss {{parent_instruction}} feature
**Mitigation**: It was never implemented, so nobody is using it
**Impact**: LOW - no current users affected

**Risk 2**: Profile rewrites might miss important content
**Mitigation**: Review each profile carefully, test after changes
**Impact**: MEDIUM - verify thoroughly during Phase 2

**Risk 3**: Shared file pattern might not be discovered
**Mitigation**: Document clearly in PROFILE_AUTHORING.md and CONTEXT_LOADING.md
**Impact**: LOW - documentation addresses this

### Unknowns

**Unknown 1**: Does AGENT_PROMPT_INCLUDE.md content all apply to Amplifier?
**Resolution**: Review during implementation, adapt as needed

**Unknown 2**: Where should shared files live?
**Options**:
- `amplifier-dev/shared/` (project root)
- `amplifier-app-cli/data/context/shared/` (bundled)
**Decision needed**: User preference?

---

## Next Steps

### Phase 1: Planning ✅ (This Document)

**Ready to proceed** with user approval

### Phase 2: Documentation (2-3 hours)

1. Create shared instruction files
2. Remove {{parent_instruction}} from profiles
3. Update documentation
4. Optional: Update agent definitions

### Phase 3: Testing (30 min)

1. Load each profile, verify works
2. Test @mention pattern works
3. Verify shared file updates propagate

### Phase 4: Code Implementation

**NONE NEEDED!** ✅

---

## Questions for User Approval

### 1. Shared File Location

Where should we put `common-agent-base.md`?

**Option A**: `amplifier-dev/shared/` (project root, easy to find)
**Option B**: `amplifier-app-cli/data/context/shared/` (bundled with package)

**Recommendation**: Option B (bundled, same as other context)

### 2. AGENT_PROMPT_INCLUDE.md Adaptation

Should we:
- **A**: Directly copy relevant sections
- **B**: Adapt significantly for Amplifier style
- **C**: Start minimal, grow as needed

**Recommendation**: C (start minimal, based on actual Amplifier needs)

### 3. Agent Definitions Update

Should we update existing agent definitions now or later?
- **A**: Update all agents now (thorough, consistent)
- **B**: Leave as future enhancement (minimal scope)

**Recommendation**: A (while we're doing profiles, do agents too - complete the pattern)

---

## Summary

**What we're doing**:
1. ✅ Remove {{parent_instruction}} (unimplemented feature)
2. ✅ Create shared instruction pattern with @mentions
3. ✅ Rewrite 5 bundled profiles
4. ✅ Update documentation
5. ✅ Optional: Update agent definitions

**Why**:
- Solves user's DRY problem TODAY
- Uses existing @mention system
- Philosophy-aligned (ruthless simplicity)
- No new code needed
- Cleaner, clearer profiles

**Time**: 2-3 hours (all documentation, no code)

**Ready to proceed?** Give the word and I'll execute Phase 2!
