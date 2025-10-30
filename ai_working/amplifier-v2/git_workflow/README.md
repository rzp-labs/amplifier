# Git Workflow Context

This directory contains context documentation for managing the git workflow across the multi-repository Amplifier project structure.

## Contents

- [SUBMODULE_WORKFLOW.md](SUBMODULE_WORKFLOW.md) - Complete workflow documentation for managing the amplifier-dev submodule

## Overview

The parent Amplifier repository (the one you're currently in) uses the private `amplifier-dev` repository as a submodule. This setup allows:

1. Using the current Amplifier tooling to develop the next-generation Amplifier v2
2. Maintaining a clean separation between production code and development environment
3. Managing multiple public repositories through a private development workspace

## Quick Reference

### Update Everything
```bash
# From parent repository root
./ai_working/amplifier-v2/freshen-parent.sh
cd amplifier-dev
./scripts/freshen-all.sh
```

### Push Changes
```bash
# Commit changes in submodules first (manually)
cd amplifier-dev
./scripts/push-all.sh
cd ..
./ai_working/amplifier-v2/push-parent.sh
```

## Key Concepts

**Parent Repository** (`microsoft/amplifier`)
- Current/legacy Amplifier project
- Public repository
- Contains `amplifier-dev` as a submodule
- Scripts: `ai_working/amplifier-v2/*.sh`

**Development Environment** (`microsoft/amplifier-dev`)
- Private development repository
- Submodule of parent
- Contains 21 submodules (future public repos)
- Scripts: `amplifier-dev/scripts/*.sh`

**Public Repositories**
- `amplifier/` (next branch), `amplifier-core/`, `amplifier-app-cli/`, etc.
- Submodules within amplifier-dev
- Will be made public when ready
- Should have no references to amplifier-dev

## Documentation

See [SUBMODULE_WORKFLOW.md](SUBMODULE_WORKFLOW.md) for complete workflow documentation.
