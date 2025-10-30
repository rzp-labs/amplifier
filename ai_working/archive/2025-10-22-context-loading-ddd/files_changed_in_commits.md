# Files Changed in Unpushed Commits

## Commit 1: amplifier-core (57e8fab)
**Purpose**: REQUEST_ENVELOPE_V1 Pydantic models

### Code Files
- amplifier_core/__init__.py
- amplifier_core/message_models.py
- amplifier_core/utils/__init__.py
- tests/test_message_models.py

## Commit 2: amplifier-app-cli (6a1b5fe)
**Purpose**: @mention loading system

### Non-Code Files
- amplifier_app_cli/data/context/AGENTS.md
- amplifier_app_cli/data/context/DISCOVERIES.md
- amplifier_app_cli/data/context/README.md
- amplifier_app_cli/data/profiles/base.md
- amplifier_app_cli/data/profiles/dev.md
- amplifier_app_cli/data/profiles/foundation.md
- amplifier_app_cli/data/profiles/full.md
- amplifier_app_cli/data/profiles/production.md
- amplifier_app_cli/data/profiles/test-mentions.md
- amplifier_app_cli/data/profiles/test.md
- pyproject.toml
- uv.lock

### Code Files
- amplifier_app_cli/lib/__init__.py
- amplifier_app_cli/lib/mention_loading/__init__.py
- amplifier_app_cli/lib/mention_loading/deduplicator.py
- amplifier_app_cli/lib/mention_loading/loader.py
- amplifier_app_cli/lib/mention_loading/models.py
- amplifier_app_cli/lib/mention_loading/resolver.py
- amplifier_app_cli/main.py
- amplifier_app_cli/utils/__init__.py
- amplifier_app_cli/utils/mentions.py
- tests/lib/mention_loading/__init__.py
- tests/lib/mention_loading/test_deduplicator.py
- tests/lib/mention_loading/test_loader.py
- tests/lib/mention_loading/test_models.py
- tests/lib/mention_loading/test_resolver.py
- tests/test_mentions.py

## Commit 3: amplifier-module-provider-anthropic (ada38ad)
**Purpose**: ChatRequest + debug logging

### Code Files
- amplifier_module_provider_anthropic/__init__.py

## Commit 4: amplifier-module-provider-openai (a3ecd5a)
**Purpose**: ChatRequest + debug logging

### Code Files
- amplifier_module_provider_openai/__init__.py

## Commit 5: amplifier-module-provider-azure-openai (69d545c)
**Purpose**: ChatRequest + debug logging

### Code Files
- amplifier_module_provider_azure_openai/__init__.py

## Commit 6: amplifier-module-provider-ollama (1818179)
**Purpose**: ChatRequest + debug logging

### Code Files
- amplifier_module_provider_ollama/__init__.py

## Commit 7: amplifier-module-loop-basic (599a155)
**Purpose**: ChatRequest construction

### Code Files
- amplifier_module_loop_basic/__init__.py

## Commit 8: amplifier-module-hooks-logging (ef9e112)
**Purpose**: DEBUG event support

### Code Files
- amplifier_module_hooks_logging/__init__.py

## Commit 9: amplifier-dev (bd46778)
**Purpose**: Documentation

### Non-Code Files
- .beads/amplifier-dev.jsonl
- AGENTS.md
- docs/AMPLIFIER_CONTEXT_GUIDE.md
- docs/CONTEXT_LOADING.md
- docs/PROFILE_AUTHORING.md
- docs/README.md
- docs/REQUEST_ENVELOPE_MODELS.md
- docs/USER_ONBOARDING.md
- docs/specs/provider/PROVIDER_MODULE_PROTOCOL.md
- docs/specs/provider/REQUEST_ENVELOPE_V1.md

## Summary

**Total Files Changed**: 52 files across 9 repositories

**Key Changes**:
1. **Core**: Added ChatRequest/ChatResponse models (REQUEST_ENVELOPE_V1)
2. **App CLI**: Added @mention loading system + updated bundled profiles/context
3. **4 Providers**: Added ChatRequest support + debug logging
4. **Orchestrator**: Added ChatRequest construction
5. **Hooks**: Added DEBUG event support
6. **Docs**: Comprehensive documentation for @mention and REQUEST_ENVELOPE_V1

**Non-Code Files Touched**: 24 files
- Profiles (10 files in app-cli/data/profiles/)
- Context files (3 files in app-cli/data/context/)
- Documentation (10 files in amplifier-dev/docs/)
- Config files (2 files: pyproject.toml, uv.lock)
