# Parent Instruction Inheritance: Design Options

**Date**: 2025-10-22
**Status**: Analysis Phase
**Context**: Profile markdown body inheritance feature design

---

## Current Situation

### What's Documented

**Files mentioning this feature:**
- `profiles/README.md` - Documents `{{parent_instruction}}` variable
- Profile files (base.md, dev.md, test.md, full.md, production.md) - USE `{{parent_instruction}}` in markdown body

**Documentation approach:**
```markdown
# profiles/base.md
---
profile:
  extends: foundation
---

{{parent_instruction}}

Additional base-specific instructions...
```

The `{{parent_instruction}}` variable would be replaced with the parent profile's markdown body at load time.

### What's Implemented

**NOTHING** - No code currently expands this variable.

**What DOES work:**
- YAML config inheritance via `extends:` field
- YAML merging (providers, tools, hooks, session config)
- Profile overlay system (precedence-based loading)

### The Gap

5 bundled profiles reference `{{parent_instruction}}` in their markdown body, but:
- No template expansion logic exists
- No loader code handles this variable
- Profiles currently fail silently (the literal text "{{parent_instruction}}" appears)

### Why This Matters

**Current YAML inheritance handles:**
- Session configuration (orchestrator, context, max_tokens)
- Provider lists (merged with child additions)
- Tool lists (merged with child additions)
- Hook lists (merged with child additions)
- Agent configuration (merged)

**What's missing:**
- Markdown body content inheritance
- Parent instruction text inclusion
- Control over WHERE parent content appears

---

## Option 1: Template Variable (Current Documentation)

### Design

**Mechanism**: String replacement at profile load time
```python
# During profile loading
child_body = child_profile.markdown_body
if "{{parent_instruction}}" in child_body:
    parent_body = parent_profile.markdown_body
    child_body = child_body.replace("{{parent_instruction}}", parent_body)
```

**User experience:**
```markdown
---
profile:
  extends: base
---

{{parent_instruction}}

Additional dev-specific instructions:
- Use extended thinking
- Delegate to zen-architect for complex design
```

### Pros

1. **Explicit placement control**: User chooses WHERE parent content appears
2. **Consistent with existing @mention syntax**: Uses `{{}}` template markers familiar from @mentions
3. **Simple to understand**: Clear what's happening when you see the variable
4. **No config needed**: Works by convention, no YAML required
5. **Visible in source**: Reading the profile shows parent content is included

### Cons

1. **Special-case template logic**: Introduces one-off variable expansion just for this
2. **Different from YAML inheritance**: YAML merges automatically, this requires explicit placement
3. **Only handles single parent**: No multi-parent or selective inheritance
4. **Hard to debug**: Template expansion errors might be cryptic
5. **Maintenance overhead**: New mechanism to document and support

### Implementation

**Complexity**: Low (20-30 lines)
```python
def _expand_parent_instruction(child_body: str, parent_body: str) -> str:
    """Replace {{parent_instruction}} with parent markdown body."""
    return child_body.replace("{{parent_instruction}}", parent_body)
```

**Code changes:**
- Modify profile loader to detect and expand variable
- Add to profile resolution pipeline
- Update error handling for missing parent

**Extensibility**: Limited - designed for single variable only

### Philosophy Check

**Ruthless simplicity**: ⚠️ Mixed
- Simple implementation (✅)
- But adds new template system (❌)

**Mechanism vs policy**: ✅ Mechanism
- Provides capability to include parent
- User decides whether to use it

**Start minimal, grow as needed**: ⚠️ Questionable
- Do we need this RIGHT NOW?
- Is lack of parent instruction blocking anyone?

**Avoid future-proofing**: ✅ Good
- Solves immediate need only
- Doesn't try to anticipate other uses

### Future Implications

**Extension paths:**
- Could add `{{parent_config}}`, `{{parent_tools}}`, etc.
- Could add `{{grandparent_instruction}}` for multi-level
- Could add template functions like `{{parent_instruction | indent:2}}`

**Slippery slope risks:**
- Becomes a mini-template language
- Conflicts with real templating needs
- Hard to deprecate once documented

---

## Option 2: Config-Based Control

### Design

**Mechanism**: YAML field controls inheritance behavior
```yaml
profile:
  extends: base
  inherit_instruction: true  # Default if omitted
  instruction_placement: prepend  # prepend, append, replace
```

**Generated result:**
```
[parent instruction]

[child instruction]
```

**User experience:**
```markdown
---
profile:
  extends: base
  inherit_instruction: false  # Don't include parent
---

Completely replace parent instructions with this.
```

### Pros

1. **Consistent with YAML system**: Uses same config-driven approach as other inheritance
2. **Declarative control**: Clear intent in frontmatter
3. **No special variables**: Markdown body stays pure markdown
4. **Default behavior**: Can inherit by default without explicit code
5. **Extensible pattern**: Easy to add other `inherit_*` fields

### Cons

1. **Loss of placement control**: Can't put parent in middle of child
2. **Less explicit**: Reading child doesn't show parent content is included
3. **Magic behavior**: Inheritance happens invisibly
4. **Placement options complicate**: `prepend/append/replace` adds complexity
5. **Breaks "inspect what you get"**: Final instruction not visible in source

### Implementation

**Complexity**: Medium (40-60 lines)
```python
def _merge_instructions(
    child_body: str,
    parent_body: str,
    placement: str = "prepend"
) -> str:
    if placement == "prepend":
        return f"{parent_body}\n\n{child_body}"
    elif placement == "append":
        return f"{child_body}\n\n{parent_body}"
    elif placement == "replace":
        return child_body
```

**Code changes:**
- Add YAML schema fields
- Implement merging logic
- Handle edge cases (empty parent, empty child)
- Validate placement values

**Extensibility**: Good - pattern applies to other sections

### Philosophy Check

**Ruthless simplicity**: ❌ Poor
- Adds abstraction (YAML control fields)
- Adds options (placement modes)
- Less explicit about what happens

**Mechanism vs policy**: ⚠️ Borderline
- Mechanism: provides inheritance capability
- Policy: decides placement (prepend/append/replace)

**Start minimal, grow as needed**: ❌ Poor
- Adds complexity upfront
- Anticipates multiple placement modes
- Over-engineers for hypothetical needs

**Avoid future-proofing**: ❌ Poor
- `placement` field anticipates future requirements
- Multiple modes without clear use case

### Future Implications

**Extension paths:**
- Add `inherit_providers: true/false`
- Add `inherit_tools: true/false`
- But YAML already merges these automatically...

**Slippery slope risks:**
- Duplicates YAML merging with different mechanism
- Creates confusion about when to use which approach
- Becomes "inheritance control layer" with many knobs

---

## Option 3: General Inherit Config

### Design

**Mechanism**: Unified inheritance control for all sections
```yaml
profile:
  extends: base
  inherit:
    instruction: true
    tools: true
    hooks: false
    providers: append  # prepend, append, replace
```

**Behavior:**
- `instruction: true/false` - Include parent markdown body
- `tools: true/false` - Include parent tools or start fresh
- `hooks: false` - Don't inherit parent hooks
- `providers: append` - Control merge strategy

### Pros

1. **Comprehensive inheritance model**: Handles all profile sections uniformly
2. **Granular control**: Choose what to inherit section by section
3. **Consistent pattern**: One approach for all inheritance
4. **Powerful**: Enables complex override scenarios
5. **Extensible**: Easy to add new sections

### Cons

1. **High complexity**: Many options create cognitive load
2. **Duplicates existing YAML merging**: YAML already handles tools/hooks/providers
3. **Conflicts with YAML semantics**: Lists already merge, now we override that?
4. **Over-engineered**: Solving problems we don't have
5. **Hard to understand**: What's the mental model for inheritance now?

### Implementation

**Complexity**: High (100+ lines)
```python
@dataclass
class InheritConfig:
    instruction: bool = True
    tools: Union[bool, str] = True
    hooks: Union[bool, str] = True
    providers: Union[bool, str] = "append"

def merge_with_inherit(child, parent, config: InheritConfig):
    # Complex merging logic for each section
    # Handle bool vs string modes
    # Preserve YAML semantics where needed
    ...
```

**Code changes:**
- Add complex schema
- Reimplement YAML merging with new control layer
- Handle interactions between inherit config and YAML lists
- Extensive testing for all combinations

**Extensibility**: Excellent - but at what cost?

### Philosophy Check

**Ruthless simplicity**: ❌❌ Very Poor
- Massive abstraction layer
- Many options and modes
- Difficult to reason about

**Mechanism vs policy**: ❌ Policy-heavy
- Decides how sections merge
- Imposes inheritance model on users

**Start minimal, grow as needed**: ❌❌ Very Poor
- Builds entire inheritance framework upfront
- Anticipates every possible need
- Classic future-proofing anti-pattern

**Avoid future-proofing**: ❌❌ Very Poor
- The poster child of future-proofing
- Solves problems we don't have
- High maintenance burden forever

### Future Implications

**Extension paths:**
- Add more sections (agents, session, etc.)
- Add more merge strategies
- Add conditional inheritance
- Becomes an inheritance DSL

**Slippery slope risks:**
- Users expect this level of control everywhere
- Complexity sprawl to other systems
- Maintenance nightmare
- Impossible to simplify later

---

## Option 4: @-Based References

### Design

**Mechanism**: Use existing @mention system for parent references
```markdown
---
profile:
  extends: base
---

@base.md

Additional dev-specific instructions...
```

**Loader behavior:**
- Profile loading expands @mentions as usual
- `@base.md` resolves to parent profile
- Standard @mention precedence rules apply

### Pros

1. **Reuses existing system**: No new mechanism needed
2. **Consistent with @mentions**: Same syntax for all references
3. **Explicit in source**: Clear what's being referenced
4. **Flexible placement**: Put @mention anywhere in markdown
5. **Already implemented**: @mention system exists and works

### Cons

1. **Profiles aren't documents**: @mentions load file content, but parent profile needs special handling
2. **Circular reference risk**: Parent could @mention child
3. **Resolution complexity**: How to find "base.md" from profile context?
4. **Namespace confusion**: Profile names vs file paths
5. **Not obviously about inheritance**: `@base.md` doesn't scream "inherit from parent"

### Implementation

**Complexity**: Low if @mention system is leveraged (10-20 lines)
```python
# During profile loading, resolve special @parent-profile mentions
# Map profile name to file path
# Let existing @mention system handle loading
```

**But:** Requires teaching @mention system about profile resolution

**Code changes:**
- Add profile name → file path mapping
- Register profiles as @mention-able resources
- Handle circular reference detection
- Document profile @mention syntax

**Extensibility**: Limited to references, not control

### Philosophy Check

**Ruthless simplicity**: ✅ Good
- Reuses existing mechanism
- No new concepts
- Minimal new code

**Mechanism vs policy**: ✅ Excellent
- Pure reference mechanism
- No inheritance policy decisions

**Start minimal, grow as needed**: ✅ Excellent
- Leverages what exists
- Minimal addition
- Solves immediate need

**Avoid future-proofing**: ✅ Excellent
- Doesn't anticipate future features
- Simple reference system
- Easy to extend if needed

### Future Implications

**Extension paths:**
- `@profile:base` for explicit profile references
- `@parent` as syntactic sugar for extends target
- Works with any profile, not just parent

**Slippery slope risks:**
- Low - just adds profiles to @mention namespace
- Could reference ANY profile, not just parent (is that good or bad?)

---

## Option 5: Use Existing @Mention System (No Special Parent Handling)

### Design

**Mechanism**: No special parent instruction feature at all. Users who want parent content reference it explicitly.

```markdown
---
profile:
  extends: base  # YAML config inheritance only
---

For context, see @profiles/base.md for parent instructions.

Additional dev-specific instructions...
```

**Or even simpler:**
```markdown
---
profile:
  extends: base
---

See base profile for core instructions.

Dev-specific additions:
- Extended thinking enabled
- Zen-architect available
```

### Pros

1. **Zero implementation**: Nothing to build
2. **Maximally simple**: No new mechanism
3. **Already works**: @mention system handles this
4. **Explicit**: User chooses what to reference
5. **Flexible**: Reference any profile, any file

### Cons

1. **Manual repetition**: No DRY if you want parent content
2. **Not automatic**: Users must know to reference parent
3. **Profile identity unclear**: Does child include parent instructions or not?
4. **Documentation burden**: Must explain this pattern
5. **Inconsistent with YAML**: YAML merges, markdown doesn't

### Implementation

**Complexity**: Zero (0 lines)
- Remove `{{parent_instruction}}` from profiles
- Update README to remove feature reference
- Document recommended patterns

**Code changes:**
- None
- Just documentation

**Extensibility**: N/A - no feature to extend

### Philosophy Check

**Ruthless simplicity**: ✅✅ Excellent
- No code
- No concepts
- No maintenance

**Mechanism vs policy**: ✅✅ Excellent
- No mechanism needed
- Users make their own policy

**Start minimal, grow as needed**: ✅✅ Excellent
- Start with nothing
- Add only if real need emerges

**Avoid future-proofing**: ✅✅ Excellent
- Doesn't anticipate anything
- Just uses what exists

**Question everything**: ✅✅ Excellent
- Challenges the premise: do we need this?

### Future Implications

**Extension paths:**
- If need emerges, implement Option 1 or 4
- Gather real use cases first
- Build from evidence, not speculation

**Slippery slope risks:**
- None - no feature to slope from

### Critical Question

**Do we actually need parent instruction inheritance?**

Current profiles use `{{parent_instruction}}`, but:
- Feature never implemented
- No user complaints
- YAML inheritance works fine
- Markdown body is custom per profile anyway

**Evidence needed:**
- User saying "I want my profile to include parent instructions"
- Use case where manual reference doesn't work
- Clear value add over current system

---

## Comparison Matrix

| Criteria | Option 1<br>Template | Option 2<br>Config | Option 3<br>General | Option 4<br>@Mention | Option 5<br>Nothing |
|----------|----------|----------|----------|----------|----------|
| **Simplicity** | ⚠️ Medium<br>New template | ❌ Low<br>Config fields | ❌❌ Very Low<br>Complex system | ✅ High<br>Reuses existing | ✅✅ Highest<br>No code |
| **Consistency** | ⚠️ Medium<br>Differs from YAML | ⚠️ Medium<br>YAML-like | ❌ Low<br>Conflicts with YAML | ✅ High<br>Uses @mentions | ✅ High<br>User choice |
| **Extensibility** | ⚠️ Limited<br>Template vars only | ✅ Good<br>More fields | ✅✅ Excellent<br>But expensive | ⚠️ Limited<br>References only | N/A<br>No feature |
| **User Experience** | ✅ Good<br>Explicit control | ⚠️ Medium<br>Invisible merge | ❌ Poor<br>Too complex | ✅ Good<br>Familiar syntax | ✅ Good<br>Straightforward |
| **Implementation** | ⚠️ 20-30 lines<br>Template engine | ⚠️ 40-60 lines<br>Merge logic | ❌ 100+ lines<br>Full framework | ✅ 10-20 lines<br>Reuse existing | ✅✅ 0 lines<br>Remove text |
| **Philosophy** | ⚠️ Medium<br>Adds abstraction | ❌ Poor<br>Future-proofing | ❌❌ Very Poor<br>Over-engineering | ✅ Good<br>Minimal addition | ✅✅ Excellent<br>Zero addition |
| **Maintenance** | ⚠️ Medium<br>New system | ❌ High<br>Config options | ❌❌ Very High<br>Complex merging | ✅ Low<br>Leverage existing | ✅✅ None<br>No code |
| **Future Risk** | ⚠️ Medium<br>Template sprawl | ❌ High<br>Config sprawl | ❌❌ Very High<br>Inheritance DSL | ✅ Low<br>Just references | ✅✅ None<br>No feature |

**Legend:**
- ✅✅ Excellent
- ✅ Good
- ⚠️ Medium/Mixed
- ❌ Poor
- ❌❌ Very Poor

---

## Recommendation

### Preferred Option: **Option 5 (Do Nothing)**

#### Why

**Ruthless Simplicity Wins**

Following our core philosophy:
1. **Necessity**: "Do we actually need this right now?"
   - **NO** - Feature was documented but never implemented
   - No user complaints or requests
   - YAML inheritance already works
   - Markdown bodies are profile-specific anyway

2. **Simplicity**: "What's the simplest way to solve this?"
   - **Don't build it** - Simplest possible solution
   - If users need parent context, they can reference with @mentions or summarize

3. **Directness**: "Can we solve this more directly?"
   - **Users write what they need** - Most direct
   - No magic, no hidden behavior

4. **Value**: "Does the complexity add proportional value?"
   - **NO** - Even smallest implementation (Option 1) adds complexity for unclear value

5. **Maintenance**: "How easy will this be to understand later?"
   - **Easiest** - Nothing to maintain or explain

**Evidence-Driven Decision**

The "two-implementation rule" from KERNEL_PHILOSOPHY.md:
> Do not promote a new concept into kernel until at least two independent modules have converged on the need.

**We have ZERO implementations requesting this feature.**

**Profiles as Independent Specifications**

Each profile is a complete specification:
- Foundation: Minimal baseline
- Base: Core development setup
- Dev: Development configuration
- Production: Production optimizations

Each profile's markdown body serves as its **complete instruction set** for that configuration. Inheritance of markdown body creates:
- Ambiguity: "What instructions actually apply?"
- Hidden behavior: "Where did this instruction come from?"
- Maintenance burden: "If I change parent, what breaks?"

**YAML Inheritance is Sufficient**

Current system handles what matters:
- Session configuration (orchestrator, context)
- Module lists (providers, tools, hooks)
- Configuration values (max_tokens, thresholds)

Markdown body is **documentation/instruction** - it SHOULD be profile-specific.

#### Trade-offs Accepted

**What we're giving up:**
- DRY for markdown body content
- Automatic parent instruction inclusion
- Central update of shared instructions

**What we're gaining:**
- Zero maintenance burden
- Maximum simplicity
- Clear, explicit profile definitions
- Freedom to rewrite without breaking children

**How users handle shared instructions:**
```markdown
---
profile:
  extends: base  # YAML config inheritance
---

Development configuration with extended capabilities.

Core instructions inherited via YAML config (orchestrator, tools, hooks).

Dev-specific instructions:
- Use extended thinking for complex analysis
- Delegate to specialized agents via task tool
- Reference @DISCOVERIES.md for known patterns
```

#### Implementation Plan

**Step 1: Remove documented feature (2 hours)**
1. Remove `{{parent_instruction}}` from all bundled profiles
2. Update profiles/README.md to remove mention of feature
3. Write clear markdown body for each profile independently

**Step 2: Document pattern (1 hour)**
1. Add section to README: "Why profiles don't inherit markdown body"
2. Explain YAML inheritance scope (config, lists)
3. Show pattern for referencing parent profile if needed

**Step 3: Monitor usage (ongoing)**
1. Watch for user requests for this feature
2. Gather real use cases if they emerge
3. Revisit decision if evidence accumulates

**Total effort: ~3 hours to remove vs. ~40-100 hours to implement and maintain**

### Alternative if Concerns Arise: **Option 4 (@-Based References)**

#### Fallback Reasoning

If after removal, users request parent instruction inclusion:

**Option 4 is the fallback** because:
1. ✅ Reuses existing @mention system
2. ✅ Minimal new code (10-20 lines)
3. ✅ Explicit and visible
4. ✅ Aligns with philosophy

**Threshold for reconsidering:**
- 3+ users request parent instruction inclusion
- Clear use case that @mention references don't solve
- Evidence that rewriting instructions creates real burden

**Implementation path:**
1. Add profile name → path mapping to @mention resolver
2. Document `@profile:parent-name` syntax
3. Optional syntactic sugar: `@parent` for `extends` target

---

## Questions for User

### Critical Decision Points

1. **Is there a real user need for parent instruction inheritance?**
   - Have users requested this?
   - Is the lack of this feature blocking anyone?
   - What problem does it solve that manual reference doesn't?

2. **What's the actual use case?**
   - Example scenario where parent instructions should be inherited
   - Why can't the child profile just write what it needs?
   - Is this about DRY or about something else?

3. **Should profiles be self-contained specifications?**
   - Is inheriting markdown body actually desirable?
   - Does it make profiles harder to understand?
   - Should each profile be complete and explicit?

### Context Needed

1. **Why was `{{parent_instruction}}` originally documented?**
   - What was the thinking behind this feature?
   - Was it user-requested or preemptive?
   - Were there use cases in mind?

2. **How do users currently create profiles?**
   - Do they extend bundled profiles?
   - Do they copy and modify?
   - Do they start from scratch?

3. **What's the actual inheritance pattern?**
   - Foundation → Base → Dev/Prod/Test → Full
   - Do instructions really cascade this way?
   - Or is each profile actually independent?

### Validation

1. **Can we ship without this feature?**
   - Remove `{{parent_instruction}}` from profiles
   - Rewrite each profile with complete instructions
   - See if anyone notices or complains

2. **If we implement, which option?**
   - If evidence emerges for real need
   - Which option best fits that need?
   - Start minimal (Option 4) and grow?

---

## Appendix: Philosophy Alignment Summary

**From KERNEL_PHILOSOPHY.md:**

✅ **Mechanism, not policy** - Option 5 avoids imposing policy
✅ **Small, stable, boring** - Option 5 adds nothing to maintain
✅ **Rough consensus & running code first** - No implementation = prove need first
✅ **Complexity budgets** - Option 5 spends zero complexity
✅ **Two-implementation rule** - Zero implementations need this

**From IMPLEMENTATION_PHILOSOPHY.md:**

✅ **Ruthless simplicity** - Option 5 is maximally simple
✅ **Start minimal, grow as needed** - Option 5 starts with nothing
✅ **Avoid future-proofing** - Option 5 doesn't anticipate needs
✅ **Question everything** - Option 5 challenges the premise

**From MODULAR_DESIGN_PHILOSOPHY.md:**

✅ **Think "bricks & studs"** - Profiles are independent bricks
✅ **Regenerate, don't patch** - Each profile should be complete
✅ **Build in parallel** - Independent profiles enable experimentation

**Decision Framework:**

1. **Necessity**: NO - Not needed right now
2. **Simplicity**: Option 5 is simplest
3. **Directness**: Users write what they need
4. **Value**: Unclear value vs. clear complexity cost
5. **Maintenance**: Zero is best

---

## Conclusion

**Recommended action:**
1. Remove `{{parent_instruction}}` from bundled profiles
2. Rewrite each profile with complete, independent instructions
3. Document that YAML inheritance handles config, not markdown body
4. Monitor for user requests
5. Implement Option 4 if real need emerges

**Philosophy verdict:**
Our entire philosophy stack says **DON'T BUILD THIS** until real need is proven.

**Evidence required to change mind:**
- Multiple users requesting parent instruction inclusion
- Clear use case that current system can't handle
- Demonstrated burden of rewriting instructions per profile

**Path forward:**
Ship without this feature. If users miss it, we'll hear about it. Then implement the minimal solution (Option 4) that solves the actual problem.
