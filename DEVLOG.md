# Development Log - cringelinter-agent

## About This Project

`cringelint` is a command-line tool that iteratively cleans AI-generated markdown drafts. It runs the `cringelinter` skill — a rules-based linter for AI slop — in a loop via Claude Code's headless mode, producing versioned files (`draft-v1.md`, `draft-v2.md`, ...) until the document is judged clean. It is meant to be installed once and used from any directory, so writers can run a single command on a draft instead of opening Claude Code each time.

**Status:** Active
**Started:** 2026-04-26
**Last Updated:** 2026-04-26 (prompt hardening)

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

## 2026-04-26 - Skill discovery: check more than one location

First real-world run surfaced an obvious gap: the preflight only checked `~/.claude/skills/cringelinter/SKILL.md`, but the user had the skill installed via the `john-claude-skills` plugin marketplace at `~/.claude/plugins/marketplaces/john-claude-skills/skills/cringelinter/SKILL.md`. The CLI told them the skill was missing and offered to install it — even though Claude Code would have happily found and used the marketplace copy.

The fix is to check every place Claude Code might discover a skill, not just the manual install path. The preflight now looks in three locations: the user-level `~/.claude/skills/`, project-local `./.claude/skills/`, and any marketplace under `~/.claude/plugins/marketplaces/*/skills/`. The marketplace name is globbed because it varies per user; today it's `john-claude-skills`, but someone else might install the skill from a fork or a different marketplace entirely.

The `--install-skill` path now also checks the discovery locations before downloading. If the skill is already discoverable somewhere, it warns and asks for confirmation before writing a duplicate copy to `~/.claude/skills/cringelinter/`. The destination for new installs stays at the user-level manual path, since that's the location least likely to get overwritten by a marketplace update.

This is a good reminder that skills aren't a single-location concept anymore. With plugin marketplaces in the picture, any tool that depends on a skill needs to treat "is the skill installed" as a discovery problem, not a path-existence check.

---

## 2026-04-26 - Prompt hardening for weaker models

A run with `claude-haiku-4-5` exposed a brittleness in the original Ralph prompt. Haiku responded with *"I've launched cringelinter. Let me wait for the analysis to complete..."* — describing intent in conversational prose — and the headless turn ended without ever calling the Write tool. The script then correctly errored out because the expected `legal-training-blog-v1.md` didn't exist on disk.

The diagnosis is that "Run your cringelinter skill" was ambiguous: a strong model (Sonnet) reads it as "apply the rules and produce the output," while a weaker model (Haiku) interprets it as "spawn this thing and wait for it." Skills aren't subprocesses, but the verb "run" invited that misread.

The new `lib/prompt.txt` is more directive without being more verbose where it doesn't need to be. It tells Claude the skill is a set of rules to apply inline (not a subprocess), enumerates the required steps for the current turn (apply rules, use the Write tool now, append to cringelog, emit the COMPLETE sentinel when clean), specifies the cringelog as structured JSON with named keys (`file`, `rule`, `before`, `after`) instead of free-form lines, and explicitly bans narration openers like "I'll" and "Let me". It closes with the practical stake: a script is reading the filesystem after this turn — no file on disk means the run fails.

The structured cringelog is a side benefit. The original prompt said "write a separate line in the log for each cringy identification" but didn't pin a format, so each iteration could drift. Named keys make the log queryable later if it's worth doing anything with it — joining iterations, counting which rules fire most, etc.

This should make Haiku viable as a cheaper option, and shouldn't change Sonnet's behavior — Sonnet was already doing all of this implicitly.

---
