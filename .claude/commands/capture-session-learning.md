---
allowed-tools: Read, Write, Edit, Glob, mcp__api-supermemory-ai__addMemory, mcp__api-supermemory-ai__search
argument-hint: [capture-type] | --project-learnings | --implementation-corrections | --structure-insights | --workflow-improvements
description: Capture and document session learnings with automatic Supermemory integration
category: knowledge-management
model: sonnet
---

# Session Learning Capture

Capture and integrate session learnings into Supermemory for persistent knowledge across sessions: **$ARGUMENTS**

## Current Learning Context

- Session duration: Current Claude Code session learning opportunities
- Project: Assured workspace (hybrid PM + Engineering)
- Learning patterns: Identification of knowledge gaps and correction opportunities

## Task

Execute comprehensive learning capture with automatic Supermemory integration:

**Capture Type**: Use $ARGUMENTS to focus on project learnings, implementation corrections, structure insights, or workflow improvements

## Learning Capture Framework

### 0. Pre-Capture Search
**Avoid duplicates - search first:**
- Search Supermemory for similar knowledge using mcp__api-supermemory-ai__search
- Check DISCOVERIES.md (amplifier-specific) for existing entries
- If found: Decide whether to enhance existing or capture as new variation
- If new: Verify it's truly novel and has broader applicability

### 1. Learning Identification
**Detect valuable knowledge:**
- New project knowledge or patterns discovered
- Implementation corrections (bugs, gotchas, non-obvious solutions)
- Structural insights (architecture, organization patterns)
- Workflow discoveries (process optimizations)

**Filter out (DO NOT capture):**
- Temporary workarounds
- Session-specific context without broader applicability
- Knowledge already well-documented
- Minor preferences or one-off decisions
- Obvious/trivial information

### 2. Knowledge Classification
**Categorize for proper integration:**
- **Type**: project-learnings | implementation-corrections | structure-insights | workflow-improvements
- **Importance**: critical (blocks work) | useful (improves efficiency) | minor (nice to know)
- **Scope**: workspace-wide | project-specific | tool-specific
- **Reusability**: Will this help in future sessions?

### 3. Context Analysis
**Provide rich context for retrieval:**
- What triggered this learning? (problem, task, investigation)
- When is this relevant? (triggering conditions)
- Who/what needs this? (roles, tools, workflows)
- What's the impact? (time saved, errors prevented)

### 4. Supermemory Integration (MANDATORY)

**Memory Format Guidelines:**

**Structure each memory as:**
```
[Project] - [Type]: [One-sentence summary]. [Problem/situation encountered]. [Solution/insight discovered]. [When applicable/useful]. [Examples if helpful].
```

**Granularity Rules:**
- **Atomic learnings**: One focused insight per memory (preferred)
- **Related batches**: Group tightly coupled insights (max 2-3 per memory)
- **Avoid mega-memories**: Never dump entire session summaries

**Quality Standards:**
- Include context: What problem/situation triggered this?
- Include solution: What was discovered or corrected?
- Include applicability: When is this knowledge useful?
- Include examples: Concrete examples when helpful
- Keep focused: 2-4 sentences typical, 5-6 max

**Example Memories:**

```
Good ✅:
"Assured Workspace - Implementation Correction: Claude Code commands require YAML frontmatter to appear in / list. Commands in .claude/commands/*.md need frontmatter (description, category, allowed-tools) to show in command autocomplete. Without frontmatter, commands won't be discoverable. Applicable when adding new custom commands."

Good ✅:
"Assured Workspace - Structure Insight: Amplifier is single source of truth for AI tooling via symlinks. All agents/commands/tools live in amplifier/.claude/ and workspace/.claude/ symlinks to them. Changes in amplifier automatically propagate. This enables consistent AI tooling across all projects without duplication."

Bad ❌:
"Learned some stuff about commands and frontmatter and symlinks and how the workspace is organized."

Bad ❌:
"Today we set up the entire Assured workspace with 23 agents and 10 commands and created symlinks from amplifier to workspace and added frontmatter to 7 command files and documented everything and saved it all to Supermemory and created CLAUDE.md and README.md and SETUP_GUIDE.md and TROUBLESHOOTING.md..."
```

**Save each memory:**
Use mcp__api-supermemory-ai__addMemory for each atomic learning

### 5. DISCOVERIES.md Updates (Amplifier-Specific Only)

**Only update DISCOVERIES.md for amplifier-specific learnings:**
- Non-obvious problems and solutions in amplifier codebase
- Tool generation patterns and failures
- LLM response handling discoveries
- Framework-specific limitations or conflicts

**Format for DISCOVERIES.md:**
```markdown
## [Title] (YYYY-MM-DD)

### Issue
[What was the problem?]

### Root Cause
[Why did it happen?]

### Solution
[How was it fixed?]

### Prevention
[How to avoid in future?]
```

**Skip DISCOVERIES.md for:**
- Workspace-level knowledge (goes to Supermemory only)
- Project management learnings
- Configuration discoveries
- General workflow improvements

### 6. Validation Process

**Before finalizing, verify:**
- ✅ Accuracy: Is the learning correct and complete?
- ✅ Accessibility: Can it be found with relevant search terms?
- ✅ Usefulness: Will future sessions actually benefit?
- ✅ Clarity: Is it understandable without session context?
- ✅ Format: Does it follow memory structure guidelines?

## Capture Type Examples

### --project-learnings
Focus on workspace structure, project organization, cross-project patterns:
```
"Assured Workspace - Project Learning: Context boundaries strategy uses workspace level for cross-project work and project level for focused work. Workspace level (/Users/stephen/Projects/assured/) provides full context across assured-dev, service-assignment, towing but larger context window. Project level (service-assignment/, towing/, amplifier/) provides tighter boundaries, reduced context pollution. Use workspace for investigations, project level for focused PM or development work."
```

### --implementation-corrections
Focus on bugs fixed, gotchas discovered, non-obvious solutions:
```
"Amplifier - Implementation Correction: parse_llm_json() eliminates JSON parsing failures from LLM responses. LLMs don't reliably return pure JSON - they wrap in markdown, add explanations, include preambles. parse_llm_json() extracts JSON from any format. Use for all LLM JSON responses instead of raw json.loads(). Located in amplifier/ccsdk_toolkit/defensive/."
```

### --structure-insights
Focus on architecture patterns, organization discoveries, design decisions:
```
"Assured Workspace - Structure Insight: Symlink architecture enables single source of truth for AI tooling. Pattern: amplifier/.claude/ contains source → workspace/.claude/ symlinks agents/commands/tools. Benefits: zero duplication, automatic change propagation, clear ownership. Apply when distributing shared configuration across multiple projects."
```

### --workflow-improvements
Focus on process optimizations, tool usage patterns, efficiency gains:
```
"Claude Code - Workflow Improvement: Parallel tool execution dramatically improves efficiency. Send ONE message with MULTIPLE tool calls instead of sequential messages. Example: Read multiple files in parallel vs. one-by-one. Applies to independent operations: file reads, parallel searches, multiple agent launches. Sequential only when true dependencies exist."
```

## Output Summary

After capture, provide:
1. **Count**: Number of learnings captured to Supermemory
2. **Types**: Breakdown by learning type
3. **Key Insights**: Top 2-3 most impactful learnings
4. **Retrieval Terms**: Key search terms for finding these learnings later
5. **DISCOVERIES.md**: Whether any amplifier-specific entries were added

## Quality Metrics

Good session learning capture achieves:
- **Atomic**: Each memory is focused and retrievable
- **Contextual**: Includes triggering conditions and applicability
- **Actionable**: Provides concrete examples and solutions
- **Searchable**: Uses clear, discoverable terminology
- **Durable**: Useful across multiple future sessions
