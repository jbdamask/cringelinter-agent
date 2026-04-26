# Development Log - cringelinter-agent

## About This Project

`cringelint` is a command-line tool that iteratively cleans AI-generated markdown drafts. It runs the `cringelinter` skill — a rules-based linter for AI slop — in a loop via Claude Code's headless mode, producing versioned files (`draft-v1.md`, `draft-v2.md`, ...) until the document is judged clean. It is meant to be installed once and used from any directory, so writers can run a single command on a draft instead of opening Claude Code each time.

**Status:** Active
**Started:** 2026-04-26
**Last Updated:** 2026-04-26

---

## 2026-04-26 - Project Inception

The two pieces this project glues together already existed: the `cringelinter` skill in `john-claude-skills`, which encodes a long set of rules for catching AI tells (fingerprint vocabulary, bro-speak declaratives, empty summary sentences, etc.), and `cringelinter-ralph` in the `scratch` repo, which was a small bash loop that piped a markdown file plus a prompt into `claude -p` until the model emitted `<promise>COMPLETE</promise>`. Ralph worked, but it required cloning the scratch repo into whatever directory held the draft, copying two files in, and running it locally. The friction made it feel like a one-off rather than a tool.

The goal of this project was to make that loop a real, installed CLI: `cringelint draft.md` from anywhere on the filesystem.

### Design decisions

The form factor took some thought. A Claude Code plugin or subagent was tempting, but both require the user to be inside Claude Code to invoke them. The whole appeal of Ralph is that it's a shell loop driving headless Claude — you can run it from any terminal. So the design landed on: a standalone bash CLI in its own repo, distributed via `curl | bash`, with the existing skill referenced rather than bundled. The user must have Claude Code installed and authenticated; the skill must live at `~/.claude/skills/cringelinter/`. If the skill is missing, the CLI auto-prompts to fetch `SKILL.md` from `john-claude-skills` rather than hard-failing — the explicit `--install-skill` subcommand was the cleaner option, but auto-prompt won out for ergonomics.

Configuration precedence is CLI flag → `./.cringelint.conf` → `~/.config/cringelint/config` → built-in default. This came up because `claude-sonnet-4-6` is the right default for linting (cheap, fast, plenty smart for the task), but a user might want to test Opus on a specific draft, or set a global preference. The config files are plain `KEY=VALUE` shell-readable text; they're parsed with `awk` rather than sourced, so a malformed file can't execute arbitrary code.

The other small fork was the cringelog format. The original Ralph `prompt.txt` said `cringelog.jsonl` but the README said `cringelog.txt`. Standardized on `jsonl` — append-only, machine-readable, matches what the prompt actually instructs Claude to write.

### Implementation notes

`bin/cringelint` resolves its own path via `BASH_SOURCE` and `readlink` so it can find the bundled `lib/prompt.txt` no matter where the symlink lives. Preflight checks fail fast with actionable messages (the install URL for Claude Code, the `--install-skill` hint for the skill). Output files and the cringelog are always written to the user's current working directory, not the install location — running `cringelint` is supposed to feel like running `wc` or `grep`, where artifacts land where you are.

The installer (`install.sh`) handles both modes: `./install.sh` from a clone, and `curl -fsSL .../install.sh | bash`. In the curl-piped case it clones the repo to `~/.local/share/cringelinter-agent` and symlinks `bin/cringelint` into the first writable bin dir on `PATH` (preferring `~/.local/bin`, falling back to `/usr/local/bin`). Uninstall reverses both, but deliberately leaves the cringelinter skill in `~/.claude/skills/` alone — the user might be using it independently.

### References
- Source skill: https://github.com/jbdamask/john-claude-skills/tree/main/skills/cringelinter
- Predecessor: https://github.com/jbdamask/scratch/tree/main/TOOLS/cringelinter-ralph
- Initial commit: 5bd7c08

---
