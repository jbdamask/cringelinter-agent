# cringelinter-agent

`cringelint` is a CLI that iteratively de-cringes a markdown document. It runs the [cringelinter skill](https://github.com/jbdamask/john-claude-skills/tree/main/skills/cringelinter) in a loop via Claude Code's headless mode (`claude -p`), producing versioned files until the document is clean.

## Requirements

- [Claude Code](https://claude.com/claude-code) installed and authenticated (`claude --version` should work).
- The `cringelinter` skill installed at `~/.claude/skills/cringelinter/`. The CLI will offer to install it on first run.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/jbdamask/cringelinter-agent/main/install.sh | bash
```

Or clone and run `./install.sh` from the repo.

The installer drops a symlink to `cringelint` in `~/.local/bin` (or `/usr/local/bin`) and clones the project source to `~/.local/share/cringelinter-agent`.

## Usage

```sh
cringelint draft.md            # default 5 iterations
cringelint draft.md 10         # up to 10 iterations
cringelint -m claude-opus-4-7 draft.md
cringelint --install-skill     # install / refresh the cringelinter skill
cringelint --help
```

The CLI writes `draft-v1.md`, `draft-v2.md`, ... and appends to `cringelog.jsonl` in the current directory. It exits early when Claude reports the document is clean (`<promise>COMPLETE</promise>`).

## Configuration

Override defaults via key=value config files. Precedence: CLI flag → local config → global config → built-in default.

- Local: `./.cringelint.conf` (in the directory you run from)
- Global: `~/.config/cringelint/config`

```sh
MODEL=claude-sonnet-4-6
ITERATIONS=5
```

## Uninstall

```sh
~/.local/share/cringelinter-agent/uninstall.sh
```

The cringelinter skill at `~/.claude/skills/cringelinter` is left in place.
