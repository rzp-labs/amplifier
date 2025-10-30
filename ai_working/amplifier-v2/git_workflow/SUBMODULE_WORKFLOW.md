# Submodule Workflow Guide

## Overview

This document explains how to work with the `amplifier-dev` submodule from the parent Amplifier repository perspective.

## Repository Structure

```
microsoft/amplifier (THIS REPOSITORY - Public)
└── amplifier-dev/ (submodule → microsoft/amplifier-dev - Private)
    ├── amplifier/ (submodule → microsoft/amplifier#next - Will be public)
    ├── amplifier-core/ (submodule → microsoft/amplifier-core - Will be public)
    ├── amplifier-app-cli/ (submodule → microsoft/amplifier-app-cli - Will be public)
    └── 18 amplifier-module-* submodules (all will be public)
```

### Key Points

1. **Parent (microsoft/amplifier)** - Current/legacy Amplifier, using it to develop v2
2. **amplifier-dev** - Private development environment (submodule of parent)
3. **Public repos** - Future public repositories (submodules of amplifier-dev)

## Development Approach

We're using the current Amplifier project to develop the next-generation Amplifier v2. The `amplifier-dev` submodule serves as a private development workspace containing all the next-gen components.

### Why This Approach?

- **Leverage existing tooling** - Use current Amplifier's capabilities
- **Clean separation** - Keep production and development isolated
- **Managed transition** - Gradual migration to new architecture
- **Coordinated releases** - All public repos released together when ready

### Future Transition

Once Amplifier v2 is mature enough, we'll invert this pattern:
- Work directly in amplifier-dev
- Add current amplifier as a submodule there
- Pull ideas from old to new as needed

## Available Scripts

### Parent Repository Scripts

Located in `ai_working/amplifier-v2/`:

#### `freshen-parent.sh`
Updates parent repository and amplifier-dev submodule to latest versions.

```bash
cd /workspaces/amplifier
./ai_working/amplifier-v2/freshen-parent.sh

# Options:
./ai_working/amplifier-v2/freshen-parent.sh --dry-run    # Preview
./ai_working/amplifier-v2/freshen-parent.sh --verbose    # Detailed output
```

**What it does:**
1. Fetches and pulls latest for parent repository
2. Enters amplifier-dev submodule
3. Fetches and pulls latest for amplifier-dev (main branch)
4. Updates submodule pointer if needed
5. Shows summary

#### `push-parent.sh`
Pushes committed parent changes and updates amplifier-dev submodule pointer.

```bash
cd /workspaces/amplifier
# Make changes, git add, git commit manually first
./ai_working/amplifier-v2/push-parent.sh

# Options:
./ai_working/amplifier-v2/push-parent.sh --dry-run              # Preview
./ai_working/amplifier-v2/push-parent.sh --no-submodule-update  # Skip pointer update
```

**What it does:**
1. Checks parent is clean (all changes committed)
2. Checks if amplifier-dev submodule pointer changed
3. If changed, commits submodule pointer update
4. Pushes parent repository to origin

## Common Workflows

### Daily "Freshen" Workflow

**Goal:** Start your day with everything up-to-date

```bash
# From parent repository root
cd /workspaces/amplifier

# Update parent and amplifier-dev submodule
./ai_working/amplifier-v2/freshen-parent.sh

# Optional: Update all submodules within amplifier-dev
cd amplifier-dev
./scripts/freshen-all.sh
```

**When to use:**
- Starting your workday
- Before making changes
- After other team members merge changes
- Before merging your branch

### Making Changes Workflow

**Scenario 1: Changes only in parent repository**

```bash
cd /workspaces/amplifier

# Make your changes
# ... edit files ...

# Commit as usual
git add .
git commit -m "feat: your changes"

# Push
./ai_working/amplifier-v2/push-parent.sh
```

**Scenario 2: Changes in amplifier-dev**

```bash
cd /workspaces/amplifier/amplifier-dev

# Make your changes
# ... edit files ...

# Commit in amplifier-dev
git add .
git commit -m "feat: your changes"

# Push amplifier-dev (this updates the submodule pointer too)
git push origin main

# Return to parent and update submodule pointer
cd ..
git add amplifier-dev
git commit -m "chore: update amplifier-dev submodule"

# Or use the script which handles this
./ai_working/amplifier-v2/push-parent.sh
```

**Scenario 3: Changes in submodules within amplifier-dev**

```bash
cd /workspaces/amplifier/amplifier-dev

# Work in submodules
cd amplifier-core
# ... make changes ...
git add .
git commit -m "feat: your changes"
cd ..

# Push all submodule changes and update pointers
./scripts/push-all.sh

# Return to parent and update amplifier-dev pointer
cd ..
./ai_working/amplifier-v2/push-parent.sh
```

### Before Merging Your Branch

```bash
# Ensure everything is up-to-date
./ai_working/amplifier-v2/freshen-parent.sh
cd amplifier-dev
./scripts/freshen-all.sh
cd ..

# Run tests
make check
make test

# If all passes, push
./ai_working/amplifier-v2/push-parent.sh
```

## Submodule Pointer Management

### What is a Submodule Pointer?

A submodule pointer is a git reference that tracks which specific commit of a submodule the parent repository uses. When you update code in a submodule, you must also update the pointer in the parent.

### When Pointers Need Updating

Submodule pointers need updating when:
1. You pull latest changes in a submodule
2. You commit changes in a submodule
3. Someone else updates the submodule

### Automatic Pointer Updates

Our scripts automatically handle pointer updates:

- `freshen-parent.sh` - Updates pointer after pulling amplifier-dev
- `push-parent.sh` - Updates pointer if amplifier-dev changed

### Manual Pointer Updates

If you need to manually update:

```bash
cd /workspaces/amplifier

# Check if submodule changed
git status

# Should show:
# modified:   amplifier-dev (new commits)

# Update pointer
git add amplifier-dev
git commit -m "chore: update amplifier-dev submodule"
git push origin your-branch
```

## Troubleshooting

### Detached HEAD in Submodule

**Problem:** Submodule is in "detached HEAD" state

```bash
cd amplifier-dev
git status
# HEAD detached at abc1234
```

**Solution:**

```bash
cd amplifier-dev
git checkout main  # Or appropriate branch
git pull origin main
cd ..
git add amplifier-dev
git commit -m "chore: update amplifier-dev to track main"
```

### Merge Conflicts in Submodule Pointer

**Problem:** Git shows conflict in submodule pointer

```bash
git status
# both modified:   amplifier-dev
```

**Solution:**

```bash
# Enter submodule
cd amplifier-dev

# Fetch latest
git fetch origin

# See which commits are involved
git log --oneline HEAD...origin/main

# Usually, you want the latest
git checkout origin/main
git checkout main
git pull origin main

# Return to parent
cd ..

# Mark as resolved
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

**Problem:** Push fails because remote has commits you don't have

```bash
git push origin your-branch
# ! [rejected]        your-branch -> your-branch (non-fast-forward)
```

**Solution:**

```bash
# Fetch latest
git fetch origin

# Rebase your changes
git rebase origin/your-branch

# Or merge (if you prefer)
git merge origin/your-branch

# Push again
git push origin your-branch
```

### Accidentally Committed Submodule Changes

**Problem:** You accidentally committed changes from within amplifier-dev to parent

This shouldn't happen as the .gitignore prevents it, but if it does:

```bash
# Reset the commit
git reset HEAD~1

# Or if pushed already
git revert <commit-hash>
```

## Best Practices

### 1. Always Check Status Before Committing

```bash
git status
```

Ensure you're committing in the right repository.

### 2. Use Descriptive Commit Messages

```bash
# Good
git commit -m "feat: add new provider module for OpenAI"

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

### 5. Keep Submodule Pointers Current

Don't let submodule pointers get stale. Update them regularly.

### 6. Use Scripts Over Manual Commands

Scripts handle edge cases and ensure consistency:

```bash
# Preferred
./ai_working/amplifier-v2/freshen-parent.sh

# Instead of
git fetch origin && git pull origin main && cd amplifier-dev && git pull origin main && cd ..
```

### 7. Dry-Run First for Uncertainty

```bash
./ai_working/amplifier-v2/push-parent.sh --dry-run
```

See what would happen without actually doing it.

## Understanding the Development Timeline

### Current Phase (Now)

- Working in parent amplifier repository
- amplifier-dev is a submodule (private)
- Using current tooling to develop v2

### Transition Phase (Soon)

- Amplifier v2 becomes mature
- All public repos released
- Begin working primarily in amplifier-dev

### Future Phase (Later)

- Working directly in amplifier-dev
- Current amplifier becomes submodule
- Pull ideas from old to new as needed

## Related Documentation

- **amplifier-dev perspective:** See `amplifier-dev/docs/GIT_WORKFLOW.md`
- **Developer guide:** See `amplifier-dev/docs/DEVELOPER_GUIDE.md`
- **Scripts architecture:** See `ai_working/amplifier-v2/git-workflow-analysis/SCRIPTS_ARCHITECTURE.md`

## Getting Help

If you encounter issues:

1. Check this documentation
2. Try the dry-run mode: `--dry-run`
3. Check git status: `git status`
4. Look at recent commits: `git log --oneline -10`
5. Ask the team in #amplifier-dev

## Quick Reference Card

```bash
# Update everything
./ai_working/amplifier-v2/freshen-parent.sh
cd amplifier-dev && ./scripts/freshen-all.sh && cd ..

# Push parent changes
./ai_working/amplifier-v2/push-parent.sh

# Push from amplifier-dev (includes all submodules)
cd amplifier-dev && ./scripts/push-all.sh && cd ..

# Check what's changed
git status
cd amplifier-dev && git status && cd ..

# See recent commits
git log --oneline -10
cd amplifier-dev && git log --oneline -10 && cd ..
```
