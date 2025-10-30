# Git Submodule Structure Analysis

**Date:** 2025-10-10

## Repository Hierarchy

```
microsoft/amplifier (parent)
└── amplifier-dev/ (submodule from microsoft/amplifier-dev - PRIVATE)
    ├── amplifier/ (submodule from microsoft/amplifier, "next" branch - WILL BE PUBLIC)
    ├── amplifier-core/ (submodule from microsoft/amplifier-core - WILL BE PUBLIC)
    ├── amplifier-app-cli/ (submodule from microsoft/amplifier-app-cli - WILL BE PUBLIC)
    └── amplifier-module-* (18 submodules - WILL BE PUBLIC)
```

## Current State

### Parent Repository: microsoft/amplifier
- **Location:** `/workspaces/amplifier`
- **Branch:** `brkrabac/amplifier-v2-codespace` (will merge to main)
- **Visibility:** Public
- **Purpose:** Current/legacy Amplifier project being used to develop v2
- **Submodules:** 1 (amplifier-dev)

### Middle Layer: microsoft/amplifier-dev
- **Location:** `/workspaces/amplifier/amplifier-dev`
- **Visibility:** Private (development only)
- **Purpose:** Development environment for next-gen Amplifier
- **Submodules:** 21 total
  - 3 core repos (amplifier, amplifier-core, amplifier-app-cli)
  - 18 module repos (amplifier-module-*)
- **Existing Scripts:**
  - `scripts/create-module.sh`
  - `scripts/init-project.sh`
  - `scripts/install-dev.sh`
  - `scripts/install-ollama.sh`
  - `scripts/run-cli.sh`
  - `scripts/test-all.sh`

### Submodules in amplifier-dev

#### Core Repos (Public-Facing)
1. **amplifier/** - Next version of main amplifier repo
   - Branch tracking: `next` (not main!)
   - Will become public main branch later

2. **amplifier-core/** - New coordinator platform
   - Branch tracking: `main`
   - Critical new component

3. **amplifier-app-cli/** - Reference implementation app
   - Branch tracking: `HEAD` (follows remote default)
   - Example/learning resource

#### Module Repos (18 total, all tracking `main`)
- amplifier-module-agent-architect
- amplifier-module-context-persistent
- amplifier-module-context-simple
- amplifier-module-hooks-approval
- amplifier-module-hooks-backup
- amplifier-module-hooks-logging
- amplifier-module-hooks-scheduler-cost-aware
- amplifier-module-hooks-scheduler-heuristic
- amplifier-module-loop-basic
- amplifier-module-loop-events
- amplifier-module-loop-streaming
- amplifier-module-provider-anthropic
- amplifier-module-provider-mock
- amplifier-module-provider-openai
- amplifier-module-tool-bash
- amplifier-module-tool-filesystem
- amplifier-module-tool-search
- amplifier-module-tool-task
- amplifier-module-tool-web

## Branch Tracking Rules

- **Parent (microsoft/amplifier):** Current working branch (will merge to main)
- **amplifier-dev:** Main branch (default)
- **amplifier-dev/amplifier/:** `next` branch (EXCEPTION)
- **All other submodules:** `main` branch

## Documentation Requirements

### Cross-Reference Rules

| Repository | Can Reference | Cannot Reference |
|------------|--------------|------------------|
| microsoft/amplifier (parent) | amplifier-dev (private) | - |
| amplifier-dev (private) | All its submodules | - |
| amplifier/ (public) | - | amplifier-dev |
| amplifier-core/ (public) | - | amplifier-dev |
| amplifier-app-cli/ (public) | - | amplifier-dev |
| amplifier-module-* (public) | - | amplifier-dev |

### Documentation Locations Needed

1. **Parent repo (microsoft/amplifier):**
   - Context doc explaining amplifier-dev submodule workflow
   - Location: `ai_context/git_workflow/` or similar
   - Can reference private amplifier-dev repo

2. **amplifier-dev repo:**
   - Context doc explaining its submodules
   - Workflow for developers working in this repo
   - Location: Root or docs/
   - Can reference all submodules
   - Private repo, won't be public

3. **Public repos (amplifier/, amplifier-core/, amplifier-app-cli/):**
   - Standard contribution guidelines
   - NO mention of amplifier-dev
   - Self-contained documentation
   - Location: Root CONTRIBUTING.md or similar

## Script Requirements

### Location 1: ai_working/amplifier-v2/ (Parent Perspective)
Scripts that manage the amplifier-dev submodule from parent repo perspective.

**Target location:** `/workspaces/amplifier/ai_working/amplifier-v2/`

**Scripts needed:**
1. `freshen-parent.sh` - Update parent and amplifier-dev submodule pointer
2. `push-parent.sh` - Push parent changes and update submodule pointer

### Location 2: amplifier-dev/scripts/ (Middle Layer Perspective)
Scripts that manage submodules within amplifier-dev.

**Target location:** `/workspaces/amplifier/amplifier-dev/scripts/`

**Scripts needed:**
1. `freshen-all.sh` - Update all submodules to latest (special handling for amplifier "next" branch)
2. `push-all.sh` - Push all committed changes and update submodule pointers
3. `promote-to-repo.sh` - Move directory to new repo and add as submodule

## Workflow Patterns

### Daily "Freshen" Workflow

**Goal:** Start day with everything up-to-date

**From parent perspective:**
```bash
cd /workspaces/amplifier
./ai_working/amplifier-v2/freshen-parent.sh
```

**From amplifier-dev perspective:**
```bash
cd /workspaces/amplifier/amplifier-dev
./scripts/freshen-all.sh
```

**Full stack (both):**
```bash
cd /workspaces/amplifier
./ai_working/amplifier-v2/freshen-parent.sh
cd amplifier-dev
./scripts/freshen-all.sh
```

### Push Changes Workflow

**Goal:** Push committed changes (commits done manually, scripts handle submodule pointers)

**From parent perspective:**
```bash
cd /workspaces/amplifier
# Make changes, git add, git commit manually
./ai_working/amplifier-v2/push-parent.sh
```

**From amplifier-dev perspective:**
```bash
cd /workspaces/amplifier/amplifier-dev
# Changes in submodules already committed
./scripts/push-all.sh
```

### Promote Directory to Repo Workflow

**Goal:** Move a directory in amplifier-dev to its own repo

**From amplifier-dev perspective:**
```bash
cd /workspaces/amplifier/amplifier-dev
./scripts/promote-to-repo.sh my-new-module microsoft/amplifier-module-my-new-module
```

**What it does:**
1. Create new repo (using gh cli)
2. Move directory contents to new repo
3. Commit and push to new repo
4. Remove directory from amplifier-dev
5. Add new repo as submodule
6. Commit submodule change in amplifier-dev
7. Update parent's amplifier-dev pointer

## Key Considerations

1. **amplifier/ uses "next" branch** - All freshening must use "next", not "main"
2. **Submodule pointers must be updated** - Parent must track when amplifier-dev changes
3. **Tools should be gh-cli first** - Use `gh` commands where possible, `git` as fallback
4. **Assume commits are manual** - Scripts don't do add/commit except for submodule pointers
5. **Progressive disclosure** - Scripts should show what they're doing
6. **Dry-run option** - Scripts should support --dry-run to preview actions
7. **Error handling** - Scripts must fail gracefully with clear error messages
