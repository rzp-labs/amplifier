---
description: Load implementation philosophy documents before starting work
category: setup
allowed-tools: Read, Bash
argument-hint: Optional additional guidance or context for the session
---

## Usage

`/prime <ADDITIONAL_GUIDANCE>`

## Process

Perform all actions below.

Instructions assume you are in the repo root directory, change there if needed before running.

READ (or RE-READ if already READ):
@ai_context/IMPLEMENTATION_PHILOSOPHY.md
@ai_context/MODULAR_DESIGN_PHILOSOPHY.md

RUN:
make install
source .venv/bin/activate
make check
make test

## Additional Guidance

$ARGUMENTS
