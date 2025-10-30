# DRY Instructions Solution Analysis

## The Use Case (REAL)

**User's Problem**: Copy-paste shared instructions across multiple agent definitions

**Evidence from User**:
- Has common/base instructions shared across multiple agents
- Currently copying & pasting into each agent definition
- Maintenance nightmare when updating shared content
- Classic DRY violation causing inconsistency risk

**Example Scenario**:
```markdown
# agent-a.md
---
meta:
  name: agent-a
---

[50 LINES OF COPY-PASTED BASE INSTRUCTIONS]

Agent A specific instructions...

# agent-b.md (and 10+ more agents)
---
meta:
  name: agent-b
---

[SAME 50 LINES COPY-PASTED AGAIN]

Agent B specific instructions...
```

**Pain Point**: Update base instructions → must update in 10+ places, easy to miss one.

---

## Solution A: @Mentions for Shared Files (ALREADY IMPLEMENTED!)

### Design

```markdown
# Step 1: Create shared file
shared/common-agent-instructions.md
---
Common instructions for all agents...
Standard error handling...
Philosophy alignment...
---

# Step 2: Reference in each agent (WORKS TODAY)
# agent-a.md
---
meta:
  name: agent-a
---

@shared/common-agent-instructions.md

Agent A specific instructions...

# agent-b.md
---
meta:
  name: agent-b
---

@shared/common-agent-instructions.md

Agent B specific instructions...
```

### Pros

1. **Zero implementation cost** - Already working today
2. **Solves user's DRY problem immediately** - Single source of truth
3. **Reuses existing, well-understood mechanism** - @mentions work everywhere
4. **Flexible** - Can reference ANY file, not just parent profiles
5. **Philosophy-aligned** - Ruthlessly simple, uses what exists
6. **Composable** - Can @mention multiple shared files if needed
7. **Clear intent** - Explicit about what's being included
8. **Works across directories** - Can organize shared files logically

### Cons

1. **Requires explicit @mention in each agent** - Not automatic with `extends:`
2. **Manual coordination** - User must remember to include @mention
3. **No enforcement** - Nothing prevents forgetting the @mention

### Solves User's Problem?

**YES** - Completely and immediately.

User can:
1. Create `shared/common-agent-base.md` with base instructions
2. Add `@shared/common-agent-base.md` to each agent definition
3. Update base instructions in ONE place
4. Changes propagate automatically when agents are loaded

**User workflow example**:
```bash
# Create shared base
echo "Common agent instructions..." > shared/common-agent-base.md

# Update existing agents (one-time)
# Add @mention to top of each agent definition

# Future updates - edit ONE file
vim shared/common-agent-base.md
# Done! All agents get updates automatically
```

---

## Solution B: {{parent_instruction}} Template

### Design

```markdown
# base-agent.md (parent profile)
---
meta:
  name: base-agent
---

Common instructions for all agents...

# specialized-agent.md (child profile)
---
meta:
  name: specialized-agent
  extends: base-agent
---

{{parent_instruction}}

Additional specialized instructions...
```

### Pros

1. **Automatic with inheritance** - `extends:` relationship implies inclusion
2. **Semantic connection** - Makes parent-child relationship explicit
3. **No manual coordination** - Can't forget to include parent instructions
4. **Template variable pattern** - Could enable other variables later

### Cons

1. **New implementation required** - 20-30 lines of template processing
2. **Adds complexity** - New concept, new parsing, new edge cases
3. **Less flexible** - Only works with `extends:` hierarchy
4. **Implicit magic** - Parent instructions appear without explicit @mention
5. **Harder to trace** - Where do these instructions come from?
6. **Single parent only** - Can't compose multiple shared instruction sets
7. **Couples markdown body to YAML extends** - Different concerns?

### Solves User's Problem?

**YES, but with more complexity** - Solves DRY but requires implementation.

**Implementation needed**:
- Profile/agent loader must parse `{{parent_instruction}}`
- Must resolve parent from `extends:` relationship
- Must substitute parent's markdown body
- Must handle edge cases (no parent, circular references, etc.)

---

## Solution C: Both @Mentions AND {{parent_instruction}}?

### When to Use Which?

**@Mentions for**:
- Arbitrary shared content (not parent-child)
- Composing multiple shared files
- Cross-cutting concerns (philosophy, error handling)
- Explicit, clear inclusion

**{{parent_instruction}} for**:
- Parent-child inheritance (when `extends:` exists)
- Automatic inclusion of parent's full context
- Enforced consistency in inheritance chains

### Why Both?

**NOT NEEDED** - This violates ruthless simplicity.

Two ways to include shared content creates confusion:
- When should I use @mention vs {{parent_instruction}}?
- What if I use both?
- Does {{parent_instruction}} expand before or after @mentions?

---

## Comparison for User's Use Case

| Aspect | @Mentions | {{parent_instruction}} | Both |
|--------|-----------|----------------------|------|
| **Solves DRY problem** | ✅ Completely | ✅ Completely | ✅ Over-engineered |
| **Implementation cost** | ✅ Zero (done!) | ⚠️ 20-30 lines | ❌ 40+ lines |
| **Philosophy alignment** | ✅ Uses existing | ⚠️ Adds complexity | ❌ Doubles complexity |
| **Flexibility** | ✅ Any file, composable | ⚠️ Parents only | ⚠️ Confusing choice |
| **User experience** | ✅ Explicit, clear | ⚠️ Implicit magic | ❌ Two patterns |
| **Maintenance** | ✅ No new code | ⚠️ New feature | ❌ Two features |
| **Available today** | ✅ YES | ❌ NO | ❌ NO |
| **Traceability** | ✅ Visible @mention | ⚠️ Hidden in extends | ⚠️ Mixed |

---

## Recommendation

### Preferred: **@Mentions (Solution A)**

### Why It Solves the User's Problem

1. **Already works** - Zero implementation, user can use TODAY
2. **Perfectly solves DRY** - Single source of truth for shared content
3. **Philosophy-aligned** - Ruthlessly simple, reuses existing mechanism
4. **More flexible** - Can compose multiple shared files, not limited to parent
5. **Clear and explicit** - @mention makes inclusion obvious
6. **No magic** - Exactly what you see is what you get

### Implementation

**Already done!** @mention support exists and works in all profile/agent contexts.

### User Workflow

```markdown
# 1. Create shared base instructions (one-time)
# File: shared/common-agent-base.md

You are a specialized agent with the following base capabilities:

- Always consult @IMPLEMENTATION_PHILOSOPHY.md
- Follow ruthless simplicity principles
- Test your work before reporting completion
- Use defensive patterns from @DISCOVERIES.md

[... more shared instructions ...]

# 2. Update each agent definition (one-time)
# File: .claude/agents/specialized-agent.md
---
meta:
  name: specialized-agent
  extends: base-agent-config  # YAML config inheritance (separate concern)
---

@shared/common-agent-base.md

You are the specialized-agent with additional focus on:
- [Agent-specific instructions]

# 3. Future updates - edit ONE file
# Edit shared/common-agent-base.md
# All agents get updates automatically when loaded

# 4. Optional: Multiple shared files for composition
@shared/common-agent-base.md
@shared/error-handling-standards.md
@shared/testing-requirements.md

Agent-specific instructions...
```

### Philosophy Check

**Ruthless Simplicity**: ✅ Uses existing mechanism, zero new code

**Trust in Emergence**: ✅ Composition through @mentions emerges naturally

**YAGNI**: ✅ Don't build {{parent_instruction}} until proven necessary

**Wabi-sabi**: ✅ Embraces the essential - including shared content explicitly

**Occam's Razor**: ✅ Simplest solution that solves the problem

---

## Key Insight: Separate Concerns

The `extends:` relationship in YAML frontmatter serves a DIFFERENT purpose than markdown body inheritance:

**YAML `extends:`** (already implemented):
- Config inheritance (model, temperature, tools)
- Profile/agent metadata
- System settings

**Markdown body**:
- Instructions and context
- Philosophy and guidelines
- Tool usage patterns

**These are orthogonal concerns** - no need to couple them.

An agent can:
- Extend parent's config (`extends: base-config`)
- Include shared instructions (`@shared/common-base.md`)
- Include parent's instructions if desired (`@parent-agent-instructions.md`)

This gives maximum flexibility without magic.

---

## Questions for User

1. **Does @mention support solve your DRY problem?**
   - You can create `shared/common-agent-base.md` TODAY
   - Reference with `@shared/common-agent-base.md` in each agent
   - Updates propagate automatically
   - Is this sufficient?

2. **Is your need for parent instruction inheritance specific, or just DRY?**
   - If DRY → @mentions solve it NOW
   - If semantic parent inheritance → still prefer @mentions for clarity

3. **Would you prefer**:
   - **Option A**: Explicit `@shared/common-base.md` in each agent (clear, flexible)
   - **Option B**: Automatic `{{parent_instruction}}` expansion (implicit, constrained)
   - **Option C**: Both (complexity)

4. **Composition scenario**: Do you need to include MULTIPLE shared instruction sets?
   - Example: `@shared/base.md` + `@shared/error-handling.md` + `@shared/testing.md`
   - @mentions support this, {{parent_instruction}} doesn't

---

## Final Verdict

**Recommendation**: Use @mentions (Solution A)

**Rationale**:
1. Solves user's DRY problem completely
2. Already implemented and working
3. More flexible (any file, multiple includes)
4. Philosophy-aligned (ruthless simplicity)
5. Clear and explicit (no magic)
6. Zero implementation cost

**Action for User**:
- Create `shared/common-agent-base.md` with shared instructions
- Add `@shared/common-agent-base.md` to each agent definition
- Done! Update ONE file, all agents benefit

**Don't implement {{parent_instruction}} unless**:
- User explicitly requests it after trying @mentions
- Clear use case where @mentions are insufficient
- Benefits justify the added complexity
