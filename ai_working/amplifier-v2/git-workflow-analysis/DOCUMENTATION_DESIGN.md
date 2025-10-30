# Documentation Structure Design

## Overview

This document outlines the documentation structure for the multi-repository Amplifier project, respecting visibility boundaries and cross-reference rules.

## Documentation Locations

### 1. Parent Repo: microsoft/amplifier

**Location:** `/workspaces/amplifier/ai_context/git_workflow/`

**Files to create:**
- `SUBMODULE_WORKFLOW.md` - Main workflow documentation
- `README.md` - Directory index

**Target Audience:**
- Developers working in the parent repo
- AI assistants helping with development
- Internal team members who understand the full stack

**Can Reference:**
- amplifier-dev (private repo) - YES
- Explain the full nested structure - YES
- Mention temporary development approach - YES

**Content:**
- How amplifier-dev is used as a submodule
- Workflow for updating amplifier-dev
- Scripts in ai_working/amplifier-v2/
- Explanation of temporary dev approach
- Future transition plans

### 2. Middle Layer: microsoft/amplifier-dev

**Location:** `/workspaces/amplifier/amplifier-dev/docs/`

**Files to create:**
- `GIT_WORKFLOW.md` - Submodule management workflow
- `DEVELOPER_GUIDE.md` - Guide for developers
- Update `README.md` - Add references to new docs

**Target Audience:**
- Developers working directly in amplifier-dev
- Internal team managing the development environment
- AI assistants helping with amplifier-dev work

**Can Reference:**
- All submodules (public repos) - YES
- Explain submodule structure - YES
- Scripts in amplifier-dev/scripts/ - YES

**Cannot Reference:**
- Being a submodule of parent amplifier repo - Not needed

**Content:**
- Managing 21 submodules
- freshen-all workflow
- push-all workflow
- promote-to-repo workflow
- Special handling for amplifier/ "next" branch
- Module development process

### 3. Public Repos: amplifier/, amplifier-core/, amplifier-app-cli/

**Location:** Root of each repo

**Files to create/update:**
- `CONTRIBUTING.md` - Standard contribution guide
- Update `README.md` - Add development setup

**Target Audience:**
- Open source contributors
- External developers
- Anyone who will contribute once repos are public

**Cannot Reference:**
- amplifier-dev (private) - NO
- Parent amplifier repo development workflow - NO
- Internal development processes - NO

**Must Be:**
- Self-contained
- Standalone repos
- Standard open-source patterns

**Content:**
- How to clone and set up this specific repo
- How to run tests
- How to submit PRs
- Code style guidelines
- Standard OSS contribution guidelines

## Documentation Hierarchy

```
/workspaces/amplifier (parent)
├── ai_context/git_workflow/
│   ├── README.md                    [NEW] - Index
│   └── SUBMODULE_WORKFLOW.md        [NEW] - Parent perspective
│
└── amplifier-dev/ (submodule)
    ├── docs/
    │   ├── GIT_WORKFLOW.md          [NEW] - Submodule management
    │   └── DEVELOPER_GUIDE.md       [NEW] - Dev guide
    ├── README.md                    [UPDATE] - Add doc references
    │
    ├── amplifier/
    │   ├── CONTRIBUTING.md          [NEW] - Public contribution guide
    │   └── README.md                [UPDATE] - Development setup
    │
    ├── amplifier-core/
    │   ├── CONTRIBUTING.md          [NEW] - Public contribution guide
    │   └── README.md                [UPDATE] - Development setup
    │
    └── amplifier-app-cli/
        ├── CONTRIBUTING.md          [NEW] - Public contribution guide
        └── README.md                [UPDATE] - Development setup
```

## Content Templates

### Parent Repo: SUBMODULE_WORKFLOW.md

**Sections:**
1. Overview of Development Structure
2. amplifier-dev Submodule
3. Updating amplifier-dev Pointer
4. Scripts in ai_working/amplifier-v2/
5. Common Workflows
6. Future Transition Plan

### Middle Layer: GIT_WORKFLOW.md

**Sections:**
1. Repository Structure
2. Submodule Overview (list all 21)
3. Special Branch Handling (amplifier/ uses "next")
4. Freshening Workflow
5. Pushing Changes Workflow
6. Promoting Directories to Repos
7. Scripts Reference
8. Common Scenarios

### Middle Layer: DEVELOPER_GUIDE.md

**Sections:**
1. Getting Started
2. Development Environment Setup
3. Working with Submodules
4. Module Development Lifecycle
5. Testing Your Changes
6. Script Usage Guide
7. Troubleshooting

### Public Repos: CONTRIBUTING.md

**Sections:**
1. Welcome
2. Code of Conduct
3. How to Contribute
4. Development Setup
5. Running Tests
6. Submitting Pull Requests
7. Code Style
8. License

## Cross-Reference Matrix

| Document Location | Can Reference Parent | Can Reference amplifier-dev | Can Reference Public Repos |
|-------------------|---------------------|----------------------------|---------------------------|
| Parent /ai_context/ | ✅ | ✅ | ✅ |
| amplifier-dev /docs/ | ❌ | ✅ | ✅ |
| Public repos / | ❌ | ❌ | ✅ (same repo) |

## Implementation Notes

1. **Create directories first** - Ensure ai_context/git_workflow/ and amplifier-dev/docs/ exist
2. **Write documentation progressively** - Parent → Middle → Public
3. **Keep public docs generic** - No references to internal dev processes
4. **Use relative links** - Within same repo, use relative paths
5. **Version compatibility** - Docs should work regardless of which branch
6. **Scripts before docs** - Scripts should be implemented first so docs can reference them

## Success Criteria

- [ ] Parent repo has context documentation explaining amplifier-dev
- [ ] amplifier-dev has comprehensive developer guide
- [ ] Public repos have standard OSS contribution guides
- [ ] No cross-reference violations
- [ ] All documentation is discoverable from respective README files
- [ ] Scripts are documented in appropriate location
- [ ] Workflow examples are clear and actionable
