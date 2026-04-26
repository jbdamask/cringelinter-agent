#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/jbdamask/cringelinter-agent.git"
SHARE_DIR="$HOME/.local/share/cringelinter-agent"

pick_bindir() {
    if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
        echo "$HOME/.local/bin"; return
    fi
    if [[ ":$PATH:" == *":/usr/local/bin:"* ]]; then
        echo "/usr/local/bin"; return
    fi
    echo "$HOME/.local/bin"
}

BINDIR=$(pick_bindir)
mkdir -p "$BINDIR"

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/bin/cringelint" ]; then
    SOURCE_DIR="$SCRIPT_DIR"
else
    command -v git >/dev/null 2>&1 || { echo "git is required to install via curl|bash" >&2; exit 1; }
    if [ -d "$SHARE_DIR/.git" ]; then
        echo "Updating existing install at $SHARE_DIR..."
        git -C "$SHARE_DIR" pull --ff-only
    else
        echo "Cloning $REPO_URL to $SHARE_DIR..."
        mkdir -p "$(dirname "$SHARE_DIR")"
        git clone "$REPO_URL" "$SHARE_DIR"
    fi
    SOURCE_DIR="$SHARE_DIR"
fi

chmod +x "$SOURCE_DIR/bin/cringelint"

LINK="$BINDIR/cringelint"
ln -sf "$SOURCE_DIR/bin/cringelint" "$LINK"

echo ""
echo "Installed: $LINK -> $SOURCE_DIR/bin/cringelint"

if [[ ":$PATH:" != *":$BINDIR:"* ]]; then
    echo ""
    echo "Note: $BINDIR is not on your PATH. Add it to your shell rc:"
    echo "  export PATH=\"$BINDIR:\$PATH\""
fi

echo ""
echo "Try: cringelint --help"
