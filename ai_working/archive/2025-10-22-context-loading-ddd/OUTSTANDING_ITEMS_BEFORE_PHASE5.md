# Outstanding Items Before Phase 5

**Date**: 2025-10-22
**Status**: 2 items remain before Phase 5 testing

---

## Items from POST_COMMIT_HANDOFF.md

### ✅ COMPLETED

1. **Clean Up Debug Output** ✅
   - Status: DONE (just completed)
   - Fixed in commits: 5bab416, ad83b90, aa60ff4
   - All debug prints → logger calls

2. **Review Non-Code Files for DDD Compliance** ✅
   - Status: DONE (comprehensive audit complete)
   - Audited: 171 files across all submodules
   - Result: 100% clean, zero context poisoning
   - Report: `COMPLETE_CONTEXT_POISONING_AUDIT.md`

---

### 🔄 OUTSTANDING (Related to This Workstream)

#### 1. {{parent_instruction}} Loading Discussion

**Status**: ⏸️ PENDING DISCUSSION

**Current Behavior**:
Profile markdown can use `{{parent_instruction}}` variable that gets expanded.

**User Wants to Discuss**:
- How this mechanism currently works
- Possible improvements or changes
- Design considerations

**Questions to Explore**:
- Should it expand at load time or be part of message?
- Should it support other variables (like `{{project_root}}`, `{{session_id}}`)?
- Should it be more explicit/declarative?
- Is this the right approach or should we rethink it?

**Why Important**:
- Affects how profiles compose and reference content
- Architectural decision about template expansion
- May impact DDD compliance if design changes

**Time Needed**: 15-30 minutes discussion

**Blocker for Phase 5?**: NO (feature works, this is about potential improvements)

---

#### 2. Test With Bundled (GitHub) Versions

**Status**: ⏸️ PENDING

**Current Situation**:
Using `sources: local` in `~/.amplifier/settings.yaml`:
```yaml
sources:
  provider-azure-openai: local
  provider-anthropic: local
  provider-openai: local
  provider-ollama: local
  loop-streaming: local
  context-simple: local
  hooks-logging: local
```

**Why This Matters**:
- We've been testing with locally installed (editable) modules
- Users will get modules from GitHub
- Need to verify @mention system works with bundled versions
- Ensures feature works for non-developers

**What to Do**:
1. Remove or comment out `sources:` section in ~/.amplifier/settings.yaml
2. Test with a profile (will download from GitHub)
3. Verify @mention loading still works
4. Verify all 4 providers work with ChatRequest
5. Re-enable local sources for continued development

**Time Needed**: 10-15 minutes

**Blocker for Phase 5?**: **ARGUABLE**
- **Pro "Yes"**: Should test what users will actually get
- **Pro "No"**: Can test in Phase 5 as part of comprehensive testing

**Recommendation**: Include as part of Phase 5 testing step

---

### ℹ️ FOR LATER (Not Blocking This Workstream)

#### 3. Beads Issue Follow-Up (vnext-67)

**Status**: TRACKED FOR FUTURE

**Issue**: vnext-67 - Comprehensive timeout/retry strategy

**What**: Design and implement robust timeout/retry across all providers

**Why**: Current timeout is configurable (300s default) but retry logic could be better

**When**: After @mention feature is complete and pushed

**Blocker for Phase 5?**: NO (timeout works, this is future enhancement)

---

## Summary: What's Left

### Before Phase 5

**Option A: Discuss {{parent_instruction}} First** (15-30 min)
- Have design discussion
- Decide if changes needed
- Update docs if design changes
- Then proceed to Phase 5

**Option B: Include in Phase 5 Testing** (0 min now)
- Test bundled versions AS PART of Phase 5
- Discuss {{parent_instruction}} if it comes up
- Address any issues found during testing

### My Recommendation: Option B

**Why**:
1. **{{parent_instruction}} discussion is optional** - feature works, this is about possible improvements
2. **Bundled version testing fits naturally in Phase 5** - it's a test scenario
3. **Gets us to Phase 5 faster** - start comprehensive testing now
4. **Can still discuss {{parent_instruction}}** - bring it up during testing if relevant

**Phase 5 Plan**:
- Test with local sources first (verify current setup)
- Test with bundled sources (verify user experience)
- Discuss {{parent_instruction}} if design questions arise during testing
- Document all findings

---

## Detailed: {{parent_instruction}} Mechanism

### What It Is

From profile authoring, profiles can include:
```markdown
{{parent_instruction}}
```

This variable gets expanded/replaced at some point in the loading process.

### Current Questions

**1. How does it work currently?**
- Need to grep codebase to find implementation
- Where does expansion happen?
- What does it expand to?

**2. Design Considerations**:
- **Load-time expansion** (current?)
  - Pro: Simple, happens once
  - Con: Static, can't change during session

- **Runtime expansion** (alternative?)
  - Pro: Dynamic, can change
  - Con: More complex, when to expand?

- **Explicit references** (alternative?)
  - Pro: Clear, no magic
  - Con: More verbose

**3. Should we extend it?**
- Support more variables?
- Template system?
- Or keep it minimal?

### To Explore

```bash
# Find implementation
grep -r "parent_instruction" . --exclude-dir=.git --exclude-dir=.venv

# Find usage in profiles
grep -r "{{parent_instruction}}" amplifier-app-cli/data/profiles/
```

### Decision Needed

- Keep current design?
- Enhance with more variables?
- Replace with different approach?
- Remove entirely?

---

## Detailed: Bundled Version Testing

### What to Test

**Setup**:
```bash
# 1. Backup current settings
cp ~/.amplifier/settings.yaml ~/.amplifier/settings.yaml.backup

# 2. Remove local sources
sed -i '/^sources:/,/^[^ ]/d' ~/.amplifier/settings.yaml
# Or just comment out the sources: section

# 3. Clear module cache (if any)
rm -rf ~/.amplifier/modules/cache/*
```

**Test Scenarios**:
```bash
# Test 1: Profile @mentions with bundled modules
amplifier run --profile dev "What context files are loaded?"

# Expected: Should load @AGENTS.md, @DISCOVERIES.md from bundled data

# Test 2: Runtime @mentions with bundled modules
amplifier run "Summarize @docs/AMPLIFIER_AS_LINUX_KERNEL.md"

# Expected: Should load file and process it

# Test 3: All 4 providers work
# Try with each provider in turn
amplifier run --profile test-anthropic "test"
# Should work with ChatRequest from bundled module

# Test 4: DEBUG logging works
# Use profile with debug: true
# Check events.jsonl has llm:request:debug events
```

**Restore**:
```bash
# Re-enable local sources for development
mv ~/.amplifier/settings.yaml.backup ~/.amplifier/settings.yaml
```

### Why This Matters

**Problem**: We might have dependencies on editable installs
**Risk**: Bundled versions might behave differently
**Need**: Verify feature works for actual users

---

## Recommendation

### Skip Discussion for Now, Test in Phase 5

**Reasoning**:
1. {{parent_instruction}} works, discussion is optional
2. Bundled testing fits naturally in Phase 5
3. Can address any issues found during testing
4. Faster path to validation

**Phase 5 Plan**:
```
Step 1: Test with local sources (current setup)
  - Verify everything works
  - Document baseline behavior

Step 2: Test with bundled sources
  - Remove sources: local
  - Test same scenarios
  - Verify identical behavior
  - Note any differences

Step 3: Discuss {{parent_instruction}} if needed
  - If testing reveals issues
  - If design questions arise
  - Otherwise defer to later

Step 4: Create comprehensive test report
  - What worked
  - What didn't
  - Recommendations
```

---

## Current Status Summary

### ✅ COMPLETED
- Clean up debug prints
- Review non-code files (DDD compliance audit)
- Fix documentation gaps (DEBUG logging)
- Fix file references (ARCHITECTURE.md)

### ⏸️ OUTSTANDING
- {{parent_instruction}} mechanism discussion (optional)
- Test with bundled GitHub versions (Phase 5 task)

### 📋 FOR LATER
- Beads issue vnext-67 (timeout/retry design)

---

## Next Steps

### Option A: Discuss {{parent_instruction}} Now (15-30 min)
1. Grep for implementation
2. Discuss design
3. Decide on changes (if any)
4. Update docs if needed
5. Then Phase 5

### Option B: Proceed to Phase 5 (Recommended)
1. Start Phase 5 testing immediately
2. Include bundled version testing
3. Discuss {{parent_instruction}} if it comes up
4. Address any issues found

**My Recommendation**: Option B - test first, discuss if needed during testing.

---

## The Actual Question

**You asked**: "what are the outstanding issues we wanted to address before fully going after phase 5? We had the placeholder issue, what else related to this particular workstream?"

**Answer**:

**"Placeholder issue"** - I'm not sure which specific issue you mean by "placeholder issue". Could you clarify?

**Outstanding items from POST_COMMIT_HANDOFF.md**:
1. ✅ Debug print cleanup - DONE
2. ⏸️ {{parent_instruction}} discussion - PENDING (optional)
3. ✅ DDD compliance review - DONE (171 files audited)
4. ⏸️ Test bundled versions - PENDING (can do in Phase 5)
5. ℹ️ Beads vnext-67 - FOR LATER (not blocking)

**Strictly blocking Phase 5**: NOTHING (we're ready!)

**Nice to address**: {{parent_instruction}} discussion (but can defer)

---

## Question for You

**Which "placeholder issue" did you mean?**

1. The debug print statements? ✅ (fixed)
2. The {{parent_instruction}} mechanism? ⏸️ (pending discussion)
3. Something else I'm missing?

And **should we**:
- **A**: Discuss {{parent_instruction}} now before Phase 5?
- **B**: Proceed to Phase 5 and discuss if needed?
- **C**: Something else you had in mind?

I'm ready for whichever direction you prefer!
