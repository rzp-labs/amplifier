# Git Workflow Scripts Architecture

## Overview

This document outlines the architecture for git workflow automation scripts across the multi-repository Amplifier project.

## Script Locations

### Location 1: ai_working/amplifier-v2/ (Parent Perspective)

**Purpose:** Manage the amplifier-dev submodule from the parent repository perspective

**Scripts:**
1. `freshen-parent.sh` - Update parent and amplifier-dev submodule
2. `push-parent.sh` - Push parent changes and update submodule pointer

### Location 2: amplifier-dev/scripts/ (Submodule Perspective)

**Purpose:** Manage all submodules within amplifier-dev

**Scripts:**
1. `freshen-all.sh` - Update all 21 submodules to latest
2. `push-all.sh` - Push committed changes and update submodule pointers
3. `promote-to-repo.sh` - Move directory to new repo and add as submodule

## Common Design Patterns

### Command-Line Interface

All scripts follow this interface pattern:

```bash
./script-name.sh [OPTIONS]

OPTIONS:
  -h, --help       Show help message
  -d, --dry-run    Show what would be done without making changes
  -v, --verbose    Show detailed output
  -q, --quiet      Minimal output (errors only)
```

### Exit Codes

- `0` - Success
- `1` - General error
- `2` - Invalid arguments
- `3` - Git operation failed
- `4` - GitHub CLI operation failed
- `5` - Precondition not met (e.g., uncommitted changes)

### Output Format

Scripts use colored output for clarity:

```bash
# Success messages (green)
echo -e "\033[0;32m✓\033[0m Operation successful"

# Info messages (blue)
echo -e "\033[0;34m→\033[0m Processing..."

# Warning messages (yellow)
echo -e "\033[0;33m⚠\033[0m Warning: ..."

# Error messages (red)
echo -e "\033[0;31m✗\033[0m Error: ..."
```

### Error Handling

All scripts implement robust error handling:

```bash
set -euo pipefail  # Exit on error, undefined variables, pipe failures

# Error trap
trap 'error_exit "Script failed at line $LINENO"' ERR

error_exit() {
    echo -e "\033[0;31m✗\033[0m Error: $1" >&2
    exit ${2:-1}
}
```

## Script Specifications

### 1. freshen-parent.sh

**Location:** `/workspaces/amplifier/ai_working/amplifier-v2/freshen-parent.sh`

**Purpose:** Update parent repository and amplifier-dev submodule pointer

**Workflow:**
1. Check for uncommitted changes in parent (warn if present)
2. Fetch latest from parent remote
3. Pull latest for current branch (fast-forward only)
4. Enter amplifier-dev submodule
5. Fetch and pull latest (main branch)
6. Return to parent
7. Update submodule pointer if amplifier-dev changed
8. Show summary of what was updated

**Options:**
- `--dry-run` - Show what would be updated
- `--force-pull` - Allow non-fast-forward pulls (use cautiously)

**Example Usage:**
```bash
cd /workspaces/amplifier
./ai_working/amplifier-v2/freshen-parent.sh
./ai_working/amplifier-v2/freshen-parent.sh --dry-run
```

**Output:**
```
→ Freshening parent repository (microsoft/amplifier)
  ✓ Parent repository is clean
  ✓ Fetched latest from origin
  ✓ Pulled latest changes (0 commits)

→ Freshening amplifier-dev submodule
  ✓ Fetched latest from origin (main)
  ✓ Pulled latest changes (3 commits)

→ Updating submodule pointer
  ✓ amplifier-dev pointer updated

✓ Fresh completed successfully
```

### 2. push-parent.sh

**Location:** `/workspaces/amplifier/ai_working/amplifier-v2/push-parent.sh`

**Purpose:** Push committed parent changes and update submodule pointer

**Workflow:**
1. Check that changes are committed (error if dirty)
2. Check if amplifier-dev submodule has changed
3. If changed, add and commit submodule pointer update
4. Push parent branch to origin
5. Show summary

**Options:**
- `--dry-run` - Show what would be pushed
- `--no-submodule-update` - Skip submodule pointer update

**Example Usage:**
```bash
cd /workspaces/amplifier
# Make changes, git add, git commit manually
./ai_working/amplifier-v2/push-parent.sh
```

**Output:**
```
→ Checking repository status
  ✓ No uncommitted changes
  ✓ amplifier-dev submodule has updates

→ Updating submodule pointer
  ✓ Added submodule pointer change
  ✓ Committed: "chore: update amplifier-dev submodule"

→ Pushing to origin
  ✓ Pushed 2 commits to origin/brkrabac/amplifier-v2-codespace

✓ Push completed successfully
```

### 3. freshen-all.sh

**Location:** `/workspaces/amplifier/amplifier-dev/scripts/freshen-all.sh`

**Purpose:** Update all 21 submodules in amplifier-dev to their latest versions

**Workflow:**
1. Check we're in amplifier-dev root
2. Check for uncommitted changes (warn if present)
3. Fetch and pull amplifier-dev itself (main branch)
4. Initialize all submodules if needed
5. For each submodule:
   - Fetch from remote
   - Determine target branch (next for amplifier/, main for others)
   - Pull latest (fast-forward only)
   - Show summary
6. Update submodule pointers if any changed
7. Show final summary

**Options:**
- `--dry-run` - Show what would be updated
- `--submodule <name>` - Only update specific submodule(s)
- `--skip <name>` - Skip specific submodule(s)

**Example Usage:**
```bash
cd /workspaces/amplifier/amplifier-dev
./scripts/freshen-all.sh
./scripts/freshen-all.sh --dry-run
./scripts/freshen-all.sh --submodule amplifier-core
./scripts/freshen-all.sh --skip amplifier-module-provider-mock
```

**Output:**
```
→ Freshening amplifier-dev and all submodules
  ✓ amplifier-dev is clean
  ✓ Pulled latest changes for amplifier-dev

→ Updating 21 submodules:

[1/21] amplifier (next branch)
  ✓ Fetched from origin
  ✓ Pulled 2 commits

[2/21] amplifier-core (main branch)
  ✓ Fetched from origin
  ✓ Already up to date

[3/21] amplifier-app-cli (main branch)
  ✓ Fetched from origin
  ✓ Pulled 1 commit

... (continues for all 21)

→ Summary:
  ✓ 21 submodules processed
  ✓ 3 submodules updated (amplifier, amplifier-app-cli, amplifier-module-loop-basic)
  ✓ 18 submodules already up to date

✓ Freshen completed successfully
```

### 4. push-all.sh

**Location:** `/workspaces/amplifier/amplifier-dev/scripts/push-all.sh`

**Purpose:** Push committed changes in submodules and update submodule pointers

**Workflow:**
1. Check we're in amplifier-dev root
2. Check amplifier-dev itself is clean (committed)
3. For each submodule:
   - Check if there are commits ahead of remote
   - If yes, push to remote
   - Track which submodules were pushed
4. If any submodules pushed, update submodule pointers
5. Push amplifier-dev itself
6. Show summary

**Options:**
- `--dry-run` - Show what would be pushed
- `--submodule <name>` - Only push specific submodule(s)
- `--skip <name>` - Skip specific submodule(s)

**Example Usage:**
```bash
cd /workspaces/amplifier/amplifier-dev
# Changes in submodules already committed
./scripts/push-all.sh
./scripts/push-all.sh --dry-run
./scripts/push-all.sh --submodule amplifier-core
```

**Output:**
```
→ Pushing changes for amplifier-dev submodules
  ✓ amplifier-dev is clean

→ Checking submodules for unpushed commits:

[1/21] amplifier
  ✓ 2 commits ahead of origin/next
  ✓ Pushed to origin/next

[2/21] amplifier-core
  → No unpushed commits

[3/21] amplifier-app-cli
  ✓ 1 commit ahead of origin/main
  ✓ Pushed to origin/main

... (continues for all 21)

→ Updating submodule pointers
  ✓ Added pointer changes for 2 submodules
  ✓ Committed: "chore: update submodule pointers"

→ Pushing amplifier-dev
  ✓ Pushed to origin/main

→ Summary:
  ✓ 2 submodules pushed (amplifier, amplifier-app-cli)
  ✓ 19 submodules had no changes

✓ Push completed successfully
```

### 5. promote-to-repo.sh

**Location:** `/workspaces/amplifier/amplifier-dev/scripts/promote-to-repo.sh`

**Purpose:** Move a local directory to its own repository and add as submodule

**Prerequisites:** Target repository must already exist (created via internal tools)

**Workflow:**
1. Validate arguments (directory exists, repo URL valid)
2. Check directory is not already a submodule
3. Verify repository exists using `gh repo view`
4. Clone existing empty repo to temp location
5. Copy directory contents to repo
6. Commit and push to repo
7. Remove original directory from amplifier-dev
8. Add repo as submodule
9. Commit submodule addition in amplifier-dev
10. Update parent's amplifier-dev pointer
11. Show summary

**Options:**
- `--dry-run` - Show what would be done

**Arguments:**
- `DIRECTORY` - Directory to promote (required)
- `REPO_URL` - GitHub repository URL or org/repo (required)

**Example Usage:**
```bash
cd /workspaces/amplifier/amplifier-dev
# Create repository first using internal tools
./scripts/promote-to-repo.sh my-new-module microsoft/amplifier-module-my-new-module
./scripts/promote-to-repo.sh my-new-module microsoft/amplifier-module-my-new-module --dry-run
```

**Output:**
```
→ Promoting directory to repository
  Directory: my-new-module
  Target:    microsoft/amplifier-module-my-new-module

→ Verifying repository exists
  ✓ Repository exists: microsoft/amplifier-module-my-new-module

→ Initializing repository with contents
  ✓ Cloned empty repository
  ✓ Copied directory contents
  ✓ Committed initial content
  ✓ Pushed to origin/main

→ Updating amplifier-dev
  ✓ Removed my-new-module directory
  ✓ Added submodule: amplifier-module-my-new-module
  ✓ Committed: "feat: promote my-new-module to dedicated repo"
  ✓ Pushed to origin/main

→ Updating parent amplifier-dev pointer
  ✓ Updated submodule pointer in parent
  ✓ Committed: "chore: update amplifier-dev submodule"

✓ Promotion completed successfully
```

## Common Utilities

### Shared Functions Library

Create a shared library: `amplifier-dev/scripts/lib/common.sh`

```bash
#!/bin/bash
# Common utilities for git workflow scripts

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_info() { echo -e "${BLUE}→${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1" >&2; }

# Error handling
error_exit() {
    log_error "$1"
    exit "${2:-1}"
}

# Check if we're in a git repository
check_git_repo() {
    git rev-parse --git-dir >/dev/null 2>&1 || \
        error_exit "Not in a git repository" 1
}

# Check if repository is clean
is_repo_clean() {
    [[ -z $(git status --porcelain) ]]
}

# Get current branch name
get_current_branch() {
    git rev-parse --abbrev-ref HEAD
}

# Fetch from remote
safe_fetch() {
    local remote="${1:-origin}"
    log_info "Fetching from $remote"
    git fetch "$remote" || error_exit "Failed to fetch from $remote" 3
}

# Pull with fast-forward only
safe_pull() {
    local branch="${1:-$(get_current_branch)}"
    log_info "Pulling $branch"
    git pull --ff-only origin "$branch" || \
        error_exit "Failed to pull $branch (may need merge)" 3
}

# Check if branch has unpushed commits
has_unpushed_commits() {
    local branch="${1:-$(get_current_branch)}"
    local remote="${2:-origin}"
    local ahead
    ahead=$(git rev-list --count "$remote/$branch..HEAD" 2>/dev/null || echo "0")
    [[ "$ahead" -gt 0 ]]
}

# Count unpushed commits
count_unpushed_commits() {
    local branch="${1:-$(get_current_branch)}"
    local remote="${2:-origin}"
    git rev-list --count "$remote/$branch..HEAD" 2>/dev/null || echo "0"
}
```

## Implementation Guidelines

### 1. Progressive Disclosure

Scripts should show appropriate level of detail:

```bash
# Default: Show important operations only
log_info "Updating submodules..."

# Verbose mode (-v): Show all operations
[[ $VERBOSE == true ]] && log_info "  → Fetching amplifier-core"

# Quiet mode (-q): Show errors only
[[ $QUIET != true ]] && log_success "Completed"
```

### 2. Dry-Run Mode

All scripts must support dry-run:

```bash
if [[ $DRY_RUN == true ]]; then
    log_info "[DRY-RUN] Would push to origin/main"
else
    git push origin main
    log_success "Pushed to origin/main"
fi
```

### 3. Atomicity

Scripts should be atomic where possible:

```bash
# Create temp branch for risky operations
git checkout -b temp/freshen-all

# Do work...

# If all succeeded, update main
if [[ $ALL_SUCCESS == true ]]; then
    git checkout main
    git merge --ff-only temp/freshen-all
    git branch -d temp/freshen-all
else
    error_exit "Some operations failed, check temp/freshen-all branch"
fi
```

### 4. Idempotency

Scripts should be safe to run multiple times:

```bash
# Check if already up to date
if git status --porcelain | grep -q "^.M"; then
    log_info "Submodule already updated"
    return 0
fi
```

## Testing Strategy

### Unit Testing

Each script should have a test companion:

```bash
# test-freshen-all.sh
./scripts/freshen-all.sh --dry-run
# Verify output
```

### Integration Testing

Test script interactions:

```bash
# Test full workflow
./ai_working/amplifier-v2/freshen-parent.sh
cd amplifier-dev
./scripts/freshen-all.sh
# Verify state
```

### Smoke Testing

Quick validation:

```bash
# Verify all scripts are executable
find . -name "*.sh" -exec test -x {} \; -print

# Verify all scripts have help
for script in ./scripts/*.sh; do
    "$script" --help >/dev/null || echo "FAIL: $script"
done
```

## Error Recovery

### Common Failure Scenarios

1. **Merge conflicts during pull**
   - Abort pull
   - Show conflict location
   - Guide user to manual resolution

2. **Push rejected (not fast-forward)**
   - Abort push
   - Suggest: fetch + rebase + retry

3. **Submodule in detached HEAD**
   - Warn user
   - Offer to checkout tracking branch

4. **GitHub CLI not authenticated**
   - Check with `gh auth status`
   - Guide user: `gh auth login`

## Documentation

Each script should have:

1. **Inline help** (--help flag)
2. **Header comment** with purpose, usage, examples
3. **Function documentation** for complex functions
4. **Exit codes** documented in header

## Future Enhancements

1. **Parallel submodule updates** - Use xargs -P for speed
2. **Smart conflict resolution** - Auto-resolve simple conflicts
3. **Progress bars** - For operations with many submodules
4. **Notification integration** - Desktop notifications for long operations
5. **Undo capability** - Save state before operations
6. **Configuration file** - `.amplifier-workflow.conf` for preferences
