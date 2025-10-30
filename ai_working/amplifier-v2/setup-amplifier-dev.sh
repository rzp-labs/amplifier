#!/bin/bash
# Amplifier-dev Branch Setup Script
# Automates amplifier-dev submodule initialization
# Run this AFTER .devcontainer/post-create.sh
# Safe to run multiple times (idempotent)

set -e  # Exit on error

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Amplifier-dev Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Verify we're in the right place
if [ ! -d ".git" ]; then
    echo "✗ Error: Not in a git repository"
    echo "  Are you in the project root? ($(pwd))"
    exit 1
fi

# Step 1: Configure authentication
echo "→ Step 1/6: Configuring authentication..."

# Clear any git credential configurations that might use tokens
# Export empty GITHUB_TOKEN so git uses gh CLI credentials instead
echo "  Clearing GITHUB_TOKEN to ensure gh CLI is used for authentication..."
unset GITHUB_TOKEN

# Check gh CLI authentication status (explicitly without GITHUB_TOKEN)
echo "  Checking GitHub CLI authentication..."
if ! gh auth status &> /dev/null; then
    echo "  GitHub CLI not authenticated, initiating login..."

    # Run gh auth login with minimal prompts
    if ! gh auth login --web --hostname github.com --git-protocol https; then
        echo ""
        echo "  ✗ GitHub authentication failed"
        echo "  Please try running manually: gh auth login"
        echo ""
        exit 1
    fi

    # Verify authentication succeeded
    if ! gh auth status &> /dev/null; then
        echo ""
        echo "  ✗ GitHub authentication verification failed"
        echo "  Please try running manually: gh auth login"
        echo ""
        exit 1
    fi

    echo "  ✓ GitHub CLI authentication successful"
else
    echo "  ✓ GitHub CLI already authenticated"
fi

# Export empty GITHUB_TOKEN so git uses gh CLI credentials instead
export GITHUB_TOKEN=
echo "  ✓ GitHub CLI authenticated (credentials will be used for git operations)"

# Step 2: Configure Git settings
echo ""
echo "→ Step 2/6: Configuring Git..."

# Mark parent repository as safe directory
echo "  Marking repository as safe directory..."
git config --global --add safe.directory /workspaces/amplifier
echo "  ✓ Git configured"

# Step 3: Initialize parent submodule (amplifier-dev)
echo ""
echo "→ Step 3/6: Initializing parent submodule (amplifier-dev)..."
git submodule update --init amplifier-dev

# Mark amplifier-dev as safe
echo "  Marking amplifier-dev as safe directory..."
git config --global --add safe.directory /workspaces/amplifier/amplifier-dev
echo "  ✓ amplifier-dev submodule initialized"

# Step 4: Git fetch all remotes
echo ""
echo "→ Step 4/6: Fetching latest from all remotes..."
git fetch --all -p
echo "  ✓ Remotes updated"

# Step 5: Enter amplifier-dev and initialize nested submodules
echo ""
echo "→ Step 5/6: Entering amplifier-dev and updating nested submodules..."
cd amplifier-dev

# Sync and update all nested submodules
echo "  Syncing submodule configurations..."
git submodule sync

echo "  Updating submodules (this may take a moment)..."
git submodule update --init --recursive

# Mark all nested submodules as safe
echo "  Marking all nested submodules as safe directories..."
git submodule foreach --recursive 'git config --global --add safe.directory "$toplevel/$sm_path"'

echo "  ✓ Nested submodules updated and marked as safe"

# Return to root
cd ..

# Step 6: Verify setup
echo ""
echo "→ Step 6/6: Verifying setup..."
echo "  Parent repository: $(pwd)"
echo "  Submodule status:"
git submodule status | head -5
if [ $(git submodule status | wc -l) -gt 5 ]; then
    echo "  ... and $(( $(git submodule status | wc -l) - 5 )) more"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   ✅ Amplifier-dev Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Your environment is ready!"
echo ""
echo "Start Claude Code:"
echo "  claude"
echo ""
echo "Useful commands:"
echo "  • Update everything:  ./ai_working/amplifier-v2/freshen-parent.sh"
echo "  • Push changes:       ./ai_working/amplifier-v2/push-parent.sh"
echo "  • Full workflow:      See ai_working/amplifier-v2/BOOTSTRAP_GUIDE.md"
echo ""
