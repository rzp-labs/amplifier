# Codespace Setup Scripts

This directory contains automation scripts for setting up development environments in GitHub Codespaces.

## 🎉 Most Setup is Now Automatic!

When you create a fresh Codespace, `.devcontainer/post-create.sh` runs automatically and handles universal setup. You only need to:
1. Run `gh auth login` (authentication)
2. Run `./ai_working/amplifier-v2/setup-amplifier-dev.sh` (branch-specific setup)

## Scripts Overview

### Automatic: `.devcontainer/post-create.sh`

**Runs automatically** when Codespace is created. Handles universal setup.

**What it does:**
1. Configures Git settings
2. Sets up and updates pnpm
3. Installs project dependencies (`make install`)
4. Creates Python virtual environment
5. **Configures .bashrc to automatically unset GITHUB_TOKEN in new terminals**
6. **Configures .bashrc to auto-activate Python venv in new terminals**
7. Creates POST_SETUP_README.md guide

**When to manually run:**
```bash
./.devcontainer/post-create.sh
```

Only if post-create didn't run or you need to reset your environment.

---

### `setup-amplifier-dev.sh` - Branch-Specific Setup

Handles amplifier-v2 branch-specific configuration.

```bash
./ai_working/amplifier-v2/setup-amplifier-dev.sh
```

**Prerequisites:**
- Universal setup completed (automatic via post-create.sh)
- Authenticated with `gh auth login`

**What it does:**
1. Unsets GITHUB_TOKEN for current session (if still set)
2. **Verifies proper `gh auth login` authentication** (not just GITHUB_TOKEN)
3. Fetches all remote branches (`git fetch --all -p`)
4. Updates parent submodules
5. Configures amplifier-dev as safe directory
6. Updates all amplifier-dev submodules recursively

**Safe to run multiple times:** Yes (idempotent)

---

### `setup-all.sh` - Complete Setup Helper

Convenience script that ensures universal setup ran, then runs amplifier-dev setup.

```bash
./ai_working/amplifier-v2/setup-all.sh
```

**What it does:**
1. Checks if `.venv` exists (universal setup completed)
2. Runs `.devcontainer/post-create.sh` if needed
3. Activates virtual environment
4. Prompts for GitHub CLI authentication if needed
5. Runs `setup-amplifier-dev.sh`

**When to use:**
- Want a single command to ensure everything is set up
- Unsure if post-create ran successfully
- After checking out the amplifier-v2 branch

---

### `bootstrap-codespace.sh` - DEPRECATED

**Location:** `/workspaces/amplifier/bootstrap-codespace.sh`

**Status:** ⚠️ DEPRECATED - Functionality moved to `.devcontainer/post-create.sh`

This script now shows a deprecation notice and redirects to the new location. Kept for backwards compatibility.

**Use instead:** `./.devcontainer/post-create.sh`

---

## Usage Examples

### Fresh Codespace (Recommended Workflow)

```bash
# Step 1: Post-create runs automatically when Codespace starts
# (You don't need to do anything - it happens in the background)

# Step 2: Authenticate with GitHub
gh auth login

# Step 3: Run branch-specific setup
./ai_working/amplifier-v2/setup-amplifier-dev.sh

# Step 4: Start working
claude
```

### Using setup-all.sh (All-in-One)

```bash
# Ensures everything is set up, then runs amplifier-dev setup
./ai_working/amplifier-v2/setup-all.sh

# Prompts for gh auth login if needed
# Then start working
claude
```

### Re-running Setup

If you need to re-run setup:

```bash
# Re-run universal setup (if post-create failed or you need a reset)
./.devcontainer/post-create.sh

# Re-initialize submodules only
./ai_working/amplifier-v2/setup-amplifier-dev.sh
```

---

## Key Features

### Automatic GITHUB_TOKEN Management

**Problem:** Codespaces set GITHUB_TOKEN automatically in every new terminal, which conflicts with `gh auth login`.

**Solution:** Post-create.sh adds to `.bashrc`:
```bash
unset GITHUB_TOKEN 2>/dev/null || true
```

**Result:** Every new terminal automatically unsets GITHUB_TOKEN, allowing `gh auth login` to work properly.

### Auto-Activation of Python venv

**Problem:** Having to manually activate virtual environment in every new terminal.

**Solution:** Post-create.sh adds to `.bashrc`:
```bash
if [ -f /workspaces/amplifier/.venv/bin/activate ] && [ -z "$VIRTUAL_ENV" ]; then
    source /workspaces/amplifier/.venv/bin/activate
fi
```

**Result:** Every new terminal automatically activates the Python virtual environment.

### Smart gh Authentication Detection

**Problem:** Need to distinguish between GITHUB_TOKEN authentication and `gh auth login` authentication.

**Solution:** setup-amplifier-dev.sh checks for `~/.config/gh/hosts.yml` with `oauth_token:` entry, not just `gh auth status` exit code.

**Result:** Script properly detects if you've run `gh auth login` vs just having GITHUB_TOKEN set.

## Troubleshooting

### "gh auth login required"

The setup script specifically checks for `gh auth login` authentication. If you see this message:

```bash
gh auth login
```

Follow the prompts to authenticate via web browser. The script distinguishes between:
- ✅ Authenticated via `gh auth login` (has `~/.config/gh/hosts.yml`)
- ❌ Authenticated only via GITHUB_TOKEN (not sufficient)

### GITHUB_TOKEN still appearing in new terminals

If GITHUB_TOKEN is still set after opening a new terminal:

1. Check if `.bashrc` was modified:
```bash
grep "Amplifier: Unset GITHUB_TOKEN" ~/.bashrc
```

2. If not present, run:
```bash
./.devcontainer/post-create.sh
```

3. Open a new terminal to test

### "Virtual environment not found"

If setup-all.sh says virtual environment not found:

```bash
# Run post-create.sh to create it
./.devcontainer/post-create.sh

# Then continue with amplifier-dev setup
./ai_working/amplifier-v2/setup-amplifier-dev.sh
```

### "Permission denied" on scripts

Scripts should be executable, but if you get permission errors:

```bash
chmod +x .devcontainer/post-create.sh
chmod +x ai_working/amplifier-v2/setup-amplifier-dev.sh
chmod +x ai_working/amplifier-v2/setup-all.sh
```

### "Submodule not initialized"

If submodules are empty after setup:

```bash
git submodule update --init --recursive
cd amplifier-dev
git submodule update --init --recursive
```

---

## Script Features

All scripts are designed with these principles:

### Idempotent
Safe to run multiple times without causing issues. Scripts check if steps are already completed and skip them.

### Informative
Clear progress indicators and status messages. You always know what's happening.

### Error-Tolerant
Continues when safe, fails fast on critical errors. Won't leave your environment in a broken state.

### Documented
Each major step explains what it's doing and why.

---

## Manual Setup Reference

If you need to set up manually or understand what the scripts do:

### Universal Steps (All Branches)

```bash
# 1. Configure pnpm
pnpm setup
source ~/.bashrc

# 2. Update pnpm
pnpm self-update

# 3. Install dependencies
make install

# 4. Activate virtual environment
source .venv/bin/activate
```

### Branch-Specific Steps (amplifier-v2)

```bash
# 5. Clear GitHub token
unset GITHUB_TOKEN

# 6. Authenticate with GitHub
gh auth login

# 7. Update git remotes
git fetch --all -p

# 8. Update parent submodules
git submodule sync && git submodule update --init

# 9. Configure safe directory
git config --global --add safe.directory /workspaces/amplifier/amplifier-dev

# 10. Update amplifier-dev submodules
cd amplifier-dev
git submodule sync && git submodule update --init --recursive
cd ..

# 11. Start working
claude
```

---

## Related Documentation

- **Bootstrap Guide:** `BOOTSTRAP_GUIDE.md` - Complete developer onboarding
- **Git Workflow:** `git_workflow/SUBMODULE_WORKFLOW.md` - Submodule management
- **Daily Workflows:** See BOOTSTRAP_GUIDE.md "Essential Daily Workflows"

---

## Script Maintenance

If you need to modify these scripts:

1. **Test thoroughly** - Run on a fresh Codespace
2. **Maintain idempotency** - Ensure safe to run multiple times
3. **Update documentation** - Keep this README and BOOTSTRAP_GUIDE.md in sync
4. **Preserve error handling** - Don't remove safety checks

---

**Last Updated:** 2025-10-10
