---
description: Install Agent Communication Style — verify just, claude, herdr, jq, and pi, then confirm the compare loop is ready
---

# Install Agent Communication Style

## Purpose

Set up this repo for the system prompt compare loop. Everything here is a CLI tool check: there are no dependencies to build and no env files to create. This is an interactive, agentic process — ask the user when choices are needed.

## Variables

SOURCE_REPO: The directory this command is running from
SYSTEM_PROMPT: `communication_style.md`
BENCHMARK_DOC: `ai_docs/brooks-no-silver-bullet.md`

## Instructions

- Run every check via Bash — do not assume anything is installed.
- Show a status line immediately after each check (pass or fail).
- For auto-installable items (herdr, jq, pi), install them without asking.
- Never start claude, pi, or herdr sessions — only verify the binaries respond.
- Model access (Anthropic auth) is the user's own login; do not read or display any credentials.

## Workflow

### Step 1 — Check Prerequisites

Critical (gate — stop and guide the user if missing):

1. `command -v just` — task runner. Install: `brew install just`, or on Debian/Ubuntu `sudo apt install just` (or <https://github.com/casey/just>).
2. `command -v claude` — Claude Code CLI. Install: <https://docs.claude.com/cli>. Required for `just tuned-opus`, `just stock-opus`, `just compare`.

Standard (auto-install if missing):

1. `command -v herdr` — terminal agent multiplexer, required by `just compare` and `just pi-compare`. Install: `brew install herdr` (<https://herdr.dev>).
2. `command -v jq` — JSON parsing inside the compare recipes. Install: `brew install jq`, or on Debian/Ubuntu `sudo apt install jq`.
3. `command -v pi` — Pi coding agent, required only for the `just tuned-pi`, `just stock-pi`, and `just pi-compare` mirror recipes. Install: `npm install -g --ignore-scripts @earendil-works/pi-coding-agent`. If npm is unavailable, mark as skipped and note the pi recipes will not work.

### Step 2 — Verify Repo Files

1. Confirm `SYSTEM_PROMPT` exists and is non-empty — it is the entire product.
2. Confirm `BENCHMARK_DOC` exists — the compare recipes prompt against it.
3. Run `just --list` — confirms the justfile parses and shows all seven recipes.

### Step 3 — Report

Show a status table with pass/fail for every check above, then a ready count (e.g. `8/8 ready`).

Next steps (copy-pasteable):

```bash
just tuned-opus         # boot Opus 5 with the system prompt appended
just compare demo       # side-by-side: stock vs fixed Opus 5 in herdr
just pi-compare demo    # same comparison in the Pi coding agent
```
