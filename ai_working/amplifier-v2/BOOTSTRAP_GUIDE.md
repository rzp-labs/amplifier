# New Developer Bootstrap Guide for Amplifier v2

**Last Updated:** 2025-10-10

## Welcome!

This guide will help you quickly understand the Amplifier project structure and get you contributing immediately. Whether you're working on the core, modules, or documentation, this is your starting point.

## Quick Start: Automatic Setup

**New to Codespaces? Great news - most setup is automatic!**

When you create a fresh Codespace, `.devcontainer/post-create.sh` runs automatically and handles:

✅ Git configuration
✅ pnpm setup and update
✅ Dependency installation (`make install`)
✅ Python venv creation
✅ **Automatic GITHUB_TOKEN unsetting** (prevents conflicts)
✅ **Auto-activation of Python venv** (new terminals)

### What You Need To Do

#### 1. Authenticate with GitHub

After the Codespace starts, authenticate via `gh auth login`:

```bash
gh auth login
```

**Why:** Codespaces provide GITHUB_TOKEN automatically, but for private repository access and submodules, you need proper `gh auth login` authentication.

**Important:** New terminals automatically unset GITHUB_TOKEN (configured during post-create), so `gh auth login` will work correctly.

#### 2. Setup Amplifier-dev (Branch-Specific)

If working on the amplifier-v2 branch:

```bash
./ai_working/amplifier-v2/setup-amplifier-dev.sh
```

This handles:
- Verifies gh authentication (checks for `gh auth login`, not just GITHUB_TOKEN)
- Git remote updates
- Submodule initialization
- Safe directory configuration

**Or run complete setup:**

```bash
./ai_working/amplifier-v2/setup-all.sh
```

This checks if universal setup ran, handles authentication, then runs amplifier-dev setup.

#### 3. Start Developing

```bash
claude
```

### Manual Setup (If Needed)

If post-create.sh didn't run or you need to re-run setup:

```bash
# Re-run universal setup
./.devcontainer/post-create.sh

# Then amplifier-dev setup
./ai_working/amplifier-v2/setup-amplifier-dev.sh
```

### What's Automatic in New Terminals

Every new terminal automatically:
- ✅ Unsets GITHUB_TOKEN (prevents gh CLI conflicts)
- ✅ Activates Python virtual environment
- ✅ Has pnpm in PATH

**No manual environment setup needed!**

---

## The Big Picture: Two Amplifiers

There are **two Amplifier projects** you need to understand:

### 1. Current Amplifier (This Repo - Public)
- **Location:** `/workspaces/amplifier` (the repo root where you're reading this)
- **Purpose:** Current/production Amplifier implementation
- **Status:** Active, being used to develop Amplifier v2
- **Visibility:** Public repository

### 2. Next Amplifier (amplifier-dev - Private)
- **Location:** `/workspaces/amplifier/amplifier-dev` (submodule)
- **Purpose:** Next-generation Amplifier v2 development workspace
- **Status:** Under active development, will become the future
- **Visibility:** Private repository (for now)
- **Structure:** Contains 21 submodules that will become public repos

### Why This Structure?

We're **using the current Amplifier to build the next Amplifier**. This approach:
- Leverages existing tooling and capabilities
- Maintains clean separation between production and development
- Enables coordinated release of all new components
- Allows gradual migration to new architecture

**Future Transition:** Once v2 is mature, we'll invert this pattern and work directly in amplifier-dev.

## Repository Structure Overview

```
microsoft/amplifier (THIS REPOSITORY - Public)
│
├── ai_working/amplifier-v2/          # Scripts for managing amplifier-dev submodule
│   ├── freshen-parent.sh             # Update parent + amplifier-dev
│   ├── push-parent.sh                # Push parent changes
│   └── git_workflow/                 # Workflow documentation
│
└── amplifier-dev/                    # Submodule → microsoft/amplifier-dev (Private)
    │
    ├── docs/                         # Core v2 documentation
    │   ├── KERNEL_PHILOSOPHY.md      # ⭐ READ THIS - Core design principles
    │   ├── GIT_WORKFLOW.md           # Managing 21 submodules
    │   ├── ARCHITECTURE.md           # System architecture
    │   └── DEVELOPER_GUIDE.md        # Detailed dev guide
    │
    ├── scripts/                      # Scripts for managing internal submodules
    │   ├── freshen-all.sh            # Update all 21 submodules
    │   ├── push-all.sh               # Push all submodule changes
    │   └── promote-to-repo.sh        # Convert directory to submodule
    │
    ├── amplifier/                    # Submodule → microsoft/amplifier#next
    ├── amplifier-core/               # Submodule → Ultra-thin kernel (~1000 lines)
    ├── amplifier-app-cli/            # Submodule → CLI application
    │
    └── amplifier-module-*/           # 18 module submodules:
        ├── *-provider-*              # LLM providers (anthropic, openai, etc.)
        ├── *-tool-*                  # Tools (filesystem, bash, web, etc.)
        ├── *-loop-*                  # Agent loop orchestrators
        ├── *-context-*               # Context managers
        ├── *-hooks-*                 # Lifecycle hooks
        └── *-agent-*                 # Specialized agents
```

## Core Philosophy: The Kernel Model

⭐ **CRITICAL:** Read `amplifier-dev/docs/KERNEL_PHILOSOPHY.md` before making any changes.

📋 **ROADMAP:** See `amplifier-dev/docs/KERNEL_ARCHITECTURE_ROADMAP.md` for implementation status and timeline.

Amplifier v2 follows a **Linux kernel-inspired architecture**:

### The Kernel (amplifier-core)
- **Ultra-thin:** ~1000 lines max, single maintainer
- **Mechanism, not policy:** Provides capabilities, not decisions
- **Stable contracts:** Never break existing modules
- **Rarely changes:** High bar for modifications
- **No business logic:** Pure coordination

### The Modules (Everything Else)
- **Independent:** Own repo, versioning, releases
- **Focused:** Do one thing well
- **Composable:** Work together via interfaces
- **Replaceable:** Multiple implementations can compete
- **Fast iteration:** Modules can evolve rapidly

### Key Principles
1. **Ruthless Simplicity** - Every line must justify its existence
2. **Small & Stable Center** - Kernel stays still so edges can move fast
3. **Policies at Edges** - Decisions belong in modules, not core
4. **Backward Compatibility** - Never break existing modules
5. **Extensibility Through Composition** - Plug in different modules, not flags

## Getting Started: Where Do You Work?

Your work location depends on your task:

### Working in amplifier-dev (Development Environment)
**Location:** `/workspaces/amplifier/amplifier-dev`

**You work here when:**
- Making changes to any v2 component
- Creating new modules
- Modifying core, CLI, or existing modules
- Most v2 development happens here

**Git workflow:**
```bash
cd /workspaces/amplifier/amplifier-dev

# Update everything
./scripts/freshen-all.sh

# Make changes in specific submodules
cd amplifier-core
# ... edit files ...
git add .
git commit -m "feat: your changes"
cd ..

# Push all changes
./scripts/push-all.sh
```

### Working in Specific Submodules (Modules/Core)
**Location:** `/workspaces/amplifier/amplifier-dev/<specific-submodule>/`

**You work here when:**
- Your task is scoped to a single component
- Implementing a feature in one module
- Fixing a bug in core or a specific module

**Examples:**
```bash
# Work in core
cd /workspaces/amplifier/amplifier-dev/amplifier-core
# ... make changes ...

# Work in a provider module
cd /workspaces/amplifier/amplifier-dev/amplifier-module-provider-anthropic
# ... make changes ...

# Work in a tool module
cd /workspaces/amplifier/amplifier-dev/amplifier-module-tool-filesystem
# ... make changes ...
```

### Working in Parent Repository (Current Amplifier)
**Location:** `/workspaces/amplifier`

**You work here when:**
- Making changes to current/legacy Amplifier
- Updating documentation in the parent
- Managing the amplifier-dev submodule itself

## Essential Daily Workflows

### 1. Start Your Day (Freshen Everything)

```bash
cd /workspaces/amplifier

# Update parent and amplifier-dev submodule
./ai_working/amplifier-v2/freshen-parent.sh

# Update all 21 submodules within amplifier-dev
cd amplifier-dev
./scripts/freshen-all.sh
cd ..
```

**When to freshen:**
- Start of your workday
- Before making changes
- After team members merge changes
- Before merging your branch

### 2. Make Changes Workflow

**Scenario A: Changes in a single module**

```bash
cd /workspaces/amplifier/amplifier-dev/amplifier-core

# Make changes
# ... edit files ...

# Commit in the module
git add .
git commit -m "feat: your changes"

# Return to amplifier-dev
cd ..

# Push all changes (handles submodule pointers automatically)
./scripts/push-all.sh

# Return to parent and update its pointer to amplifier-dev
cd ..
./ai_working/amplifier-v2/push-parent.sh
```

**Scenario B: Changes across multiple modules**

```bash
cd /workspaces/amplifier/amplifier-dev

# Make changes in multiple places
cd amplifier-core
# ... edit, commit ...
cd ../amplifier-module-provider-anthropic
# ... edit, commit ...
cd ..

# Push all changes at once
./scripts/push-all.sh

# Return to parent and update pointer
cd ..
./ai_working/amplifier-v2/push-parent.sh
```

**Scenario C: Changes in amplifier-dev itself (not submodules)**

```bash
cd /workspaces/amplifier/amplifier-dev

# Make changes in amplifier-dev
# ... edit files ...

# Commit in amplifier-dev
git add .
git commit -m "feat: your changes"

# Push amplifier-dev
git push origin main

# Return to parent and update pointer
cd ..
./ai_working/amplifier-v2/push-parent.sh
```

### 3. Before Merging Your Branch

```bash
cd /workspaces/amplifier

# Update everything
./ai_working/amplifier-v2/freshen-parent.sh
cd amplifier-dev
./scripts/freshen-all.sh
cd ..

# Run quality checks
make check

# Run tests
make test

# If everything passes, push
./ai_working/amplifier-v2/push-parent.sh
```

## Key Concepts for Amplifier v2

### Architecture Components

#### Kernel (amplifier-core)
- **Module Discovery:** Finds and loads modules via entry points
- **Hook System:** Lifecycle events for extensibility
- **Session Management:** Coordinates agent execution
- **Context Management:** Handles conversation history
- **Stable APIs:** Interfaces that never break

#### Modules (amplifier-module-*)

**Providers** - Connect to LLM services
- `provider-anthropic` - Claude models
- `provider-openai` - GPT models
- `provider-azure-openai` - Azure OpenAI
- `provider-ollama` - Local models
- `provider-mock` - Testing/development

**Tools** - Agent capabilities
- `tool-filesystem` - Read, write, edit files
- `tool-bash` - Execute commands
- `tool-web` - Web search and fetch
- `tool-search` - Code search
- `tool-task` - Sub-agent delegation

**Loops** - Agent orchestration
- `loop-basic` - Sequential execution
- `loop-streaming` - Token streaming
- `loop-events` - Event-driven

**Context Managers** - Memory handling
- `context-simple` - Basic message list
- `context-persistent` - Session persistence

**Hooks** - Lifecycle extensions
- `hooks-approval` - Tool approval gates
- `hooks-backup` - Transcript preservation
- `hooks-logging` - Audit logging
- `hooks-scheduler-*` - Provider selection strategies

**Agents** - Specialized workers
- `agent-architect` - System design

#### CLI (amplifier-app-cli)
- Command-line interface to core
- Module management
- Configuration handling
- One of many possible UIs (web, desktop, network could be built)

### Module Development

Each module:
- Lives in its own repository (will be public)
- Has independent versioning and releases
- Implements standard interfaces from core
- Is independently installable
- Can be developed in parallel

**Module Structure:**
```
amplifier-module-my-tool/
├── amplifier_mod_my_tool/        # Python package
│   ├── __init__.py               # Entry point (mount function)
│   └── implementation.py         # Tool implementation
├── tests/                        # Tests
├── README.md                     # Documentation
└── pyproject.toml                # Dependencies and metadata
```

**Entry Point Pattern:**
```python
# amplifier_mod_my_tool/__init__.py
async def mount(coordinator, config):
    """Called by core to load this module."""
    tool = MyCustomTool(config)
    await coordinator.mount('tools', tool)
```

## Understanding Submodule Pointers

**What is a submodule pointer?**
A git reference tracking which specific commit of a submodule the parent repository uses.

**When pointers need updating:**
1. You pull latest changes in a submodule
2. You commit changes in a submodule
3. Someone else updates the submodule

**Scripts handle pointers automatically:**
- `freshen-parent.sh` - Updates pointer after pulling amplifier-dev
- `push-parent.sh` - Updates pointer if amplifier-dev changed
- `amplifier-dev/scripts/push-all.sh` - Updates pointers for all 21 submodules

**Manual pointer update (if needed):**
```bash
cd /workspaces/amplifier

# Check if submodule changed
git status
# Should show: modified:   amplifier-dev (new commits)

# Update pointer
git add amplifier-dev
git commit -m "chore: update amplifier-dev submodule"
git push origin your-branch
```

## Special Branch Handling

⚠️ **IMPORTANT:** The `amplifier/` submodule tracks the **`next`** branch, not `main`.

All other submodules track `main` branch.

```bash
cd amplifier-dev/amplifier

# Always work on next branch
git checkout next

# Make changes
# ... edit ...

# Commit and push to next (not main!)
git add .
git commit -m "feat: your changes"
git push origin next

cd ../..
./scripts/push-all.sh
```

## Scripts Reference

### Parent Repository Scripts
**Location:** `/workspaces/amplifier/ai_working/amplifier-v2/`

- **`freshen-parent.sh`** - Update parent + amplifier-dev submodule
- **`push-parent.sh`** - Push parent changes + update amplifier-dev pointer

**Options:**
- `--dry-run` - Preview without making changes
- `--verbose` - Detailed output
- `--no-submodule-update` - Skip pointer update (push-parent only)

### amplifier-dev Scripts
**Location:** `/workspaces/amplifier/amplifier-dev/scripts/`

- **`freshen-all.sh`** - Update all 21 submodules to latest
- **`push-all.sh`** - Push changes from all submodules + update pointers
- **`promote-to-repo.sh`** - Convert local directory to its own repository/submodule

**Options:**
- `--dry-run` - Preview changes
- `--verbose` - Detailed output
- `--submodule <name>` - Target only one submodule
- `--skip <name>` - Skip one submodule

## Troubleshooting Common Issues

### Detached HEAD in Submodule

**Problem:** Submodule shows "HEAD detached at abc1234"

**Solution:**
```bash
cd amplifier-dev
git checkout main
git pull origin main
cd ..
git add amplifier-dev
git commit -m "chore: update amplifier-dev to track main"
```

### Merge Conflicts in Submodule Pointer

**Problem:** Git shows "both modified: amplifier-dev"

**Solution:**
```bash
cd amplifier-dev
git fetch origin
git checkout main
git pull origin main
cd ..
git add amplifier-dev
git commit -m "chore: resolve amplifier-dev submodule conflict"
```

### Submodule Not Initialized

**Problem:** amplifier-dev directory is empty

**Solution:**
```bash
git submodule update --init --recursive
```

### Push Rejected (Not Fast-Forward)

**Problem:** Push fails with "non-fast-forward"

**Solution:**
```bash
git fetch origin
git rebase origin/your-branch
# Or: git merge origin/your-branch
git push origin your-branch
```

## Essential Documentation

### Must-Read First
1. **`amplifier-dev/docs/KERNEL_PHILOSOPHY.md`** - Core design principles ⭐
2. **`amplifier-dev/docs/KERNEL_ARCHITECTURE_ROADMAP.md`** - Implementation roadmap & status 📋
3. **`amplifier-dev/docs/ARCHITECTURE.md`** - System architecture
4. **`amplifier-dev/docs/GIT_WORKFLOW.md`** - Managing 21 submodules

### For Specific Tasks
- **Module Development:** `amplifier-dev/docs/DEVELOPER_GUIDE.md`
- **Git Workflows:** `ai_working/amplifier-v2/git_workflow/SUBMODULE_WORKFLOW.md`
- **Configuration:** `amplifier-dev/docs/PROFILES.md`
- **Usage Examples:** `amplifier-dev/docs/USAGE_GUIDE.md`

### Current Amplifier Context
- **`CLAUDE.md`** - AI assistant instructions
- **`AGENTS.md`** - Shared project guidelines
- **`DISCOVERIES.md`** - Non-obvious problems and solutions
- **`ai_context/IMPLEMENTATION_PHILOSOPHY.md`** - Development philosophy
- **`ai_context/MODULAR_DESIGN_PHILOSOPHY.md`** - Modular design principles
- **`ai_context/AMPLIFIER_CLAUDE_CODE_LEVERAGE.md`** - How current Amplifier works

## Quick Command Reference

```bash
# ============================================
# DAILY WORKFLOW
# ============================================

# Update everything (start of day)
cd /workspaces/amplifier
./ai_working/amplifier-v2/freshen-parent.sh
cd amplifier-dev && ./scripts/freshen-all.sh && cd ..

# Make changes in a module
cd amplifier-dev/amplifier-core
# ... edit files ...
git add . && git commit -m "feat: your changes"

# Push everything
cd ..
./scripts/push-all.sh
cd ..
./ai_working/amplifier-v2/push-parent.sh

# ============================================
# QUALITY CHECKS
# ============================================

# Run linting, formatting, type checking
make check

# Run tests
make test

# ============================================
# INSPECTION
# ============================================

# Check what's changed
git status
cd amplifier-dev && git status && cd ..

# See recent commits
git log --oneline -10
cd amplifier-dev && git log --oneline -10 && cd ..

# List all submodules
cd amplifier-dev && git submodule foreach 'echo $path' && cd ..

# ============================================
# DRY-RUN MODE (SAFE PREVIEW)
# ============================================

# Preview parent updates
./ai_working/amplifier-v2/freshen-parent.sh --dry-run

# Preview parent push
./ai_working/amplifier-v2/push-parent.sh --dry-run

# Preview submodule updates
cd amplifier-dev
./scripts/freshen-all.sh --dry-run
./scripts/push-all.sh --dry-run
cd ..
```

## Best Practices

### 1. Always Check Status Before Committing
```bash
git status
```
Ensure you're committing in the right repository.

### 2. Use Descriptive Commit Messages
Follow conventional commits format:
- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation only
- `chore:` - Maintenance tasks
- `refactor:` - Code refactoring

```bash
# Good
git commit -m "feat: add streaming support to anthropic provider"

# Bad
git commit -m "updates"
```

### 3. Pull Before Push
```bash
./ai_working/amplifier-v2/freshen-parent.sh
# ... make changes ...
./ai_working/amplifier-v2/push-parent.sh
```

### 4. Test Before Pushing
```bash
make check  # Linting, type checking
make test   # Run tests
```

### 5. Use Scripts Over Manual Commands
Scripts handle edge cases and ensure consistency:
```bash
# Preferred
./ai_working/amplifier-v2/freshen-parent.sh

# Instead of
git fetch && git pull && cd amplifier-dev && git pull && cd ..
```

### 6. Dry-Run for Uncertainty
```bash
./ai_working/amplifier-v2/push-parent.sh --dry-run
```
See what would happen without actually doing it.

### 7. Read the Philosophy First
Before changing core or creating modules, understand the kernel philosophy:
```bash
cat amplifier-dev/docs/KERNEL_PHILOSOPHY.md
```

## Development Timeline

### Current Phase (Now)
- Working in parent amplifier repository
- amplifier-dev is a submodule (private)
- Using current tooling to develop v2
- All v2 components are submodules within amplifier-dev

### Transition Phase (Soon)
- Amplifier v2 becomes mature
- All public repos released
- Begin working primarily in amplifier-dev

### Future Phase (Later)
- Working directly in amplifier-dev
- Current amplifier becomes reference/submodule
- Pull ideas from old to new as needed

## Getting Help

If you encounter issues:

1. **Check this documentation** - Start here
2. **Try dry-run mode:** `--dry-run`
3. **Check git status:** `git status`
4. **Look at recent commits:** `git log --oneline -10`
5. **Check the workflow docs:** `amplifier-dev/docs/GIT_WORKFLOW.md`
6. **Ask the team** - Don't stay stuck!

## Next Steps

### For Brand New Developers

If you're setting up a fresh Codespace:

1. **Run automated setup:** `./ai_working/amplifier-v2/setup-all.sh` (see "Quick Start" above)
2. **Start Claude Code:** `claude`
3. **Read the kernel philosophy:** `amplifier-dev/docs/KERNEL_PHILOSOPHY.md`
4. **Understand the architecture:** `amplifier-dev/docs/ARCHITECTURE.md`
5. **Review your assigned task** - Identify which repository/module you'll work in

### For Existing Developers

If your environment is already set up:

1. **Freshen everything** - Get the latest code
2. **Make your changes** - Follow the workflows above
3. **Test your changes** - Run `make check` and `make test`
4. **Push your changes** - Use the appropriate scripts

## Summary: The Mental Model

Think of the structure like this:

```
┌─────────────────────────────────────────────────────┐
│ Current Amplifier (Public Repository)              │
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │ amplifier-dev (Private Development Workspace) │ │
│  │                                               │ │
│  │  ┌────────────────────────────────────────┐  │ │
│  │  │ amplifier-core (Ultra-thin Kernel)     │  │ │
│  │  │ - Stable contracts                     │  │ │
│  │  │ - Module discovery                     │  │ │
│  │  │ - Hook system                          │  │ │
│  │  └────────────────────────────────────────┘  │ │
│  │                                               │ │
│  │  ┌────────────────────────────────────────┐  │ │
│  │  │ 21 Module Submodules                   │  │ │
│  │  │ - Providers (LLM connections)          │  │ │
│  │  │ - Tools (capabilities)                 │  │ │
│  │  │ - Loops (orchestrators)                │  │ │
│  │  │ - Context (memory)                     │  │ │
│  │  │ - Hooks (lifecycle)                    │  │ │
│  │  │ - Agents (specialized)                 │  │ │
│  │  └────────────────────────────────────────┘  │ │
│  │                                               │ │
│  │  ┌────────────────────────────────────────┐  │ │
│  │  │ amplifier-app-cli (CLI Interface)      │  │ │
│  │  └────────────────────────────────────────┘  │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  Scripts: ai_working/amplifier-v2/                 │
│  - freshen-parent.sh                               │
│  - push-parent.sh                                  │
└─────────────────────────────────────────────────────┘
```

**Key Insight:** We're building v2 (amplifier-dev) using the capabilities of v1 (current Amplifier). The submodule structure allows coordinated development across 21+ repositories while maintaining a single development environment.

---

**Welcome to Amplifier v2 development! 🚀**

Remember: When in doubt, read the kernel philosophy, use dry-run mode, and ask questions. The team is here to help you succeed!
