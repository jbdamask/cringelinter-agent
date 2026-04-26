#!/usr/bin/env bash
set -euo pipefail

SHARE_DIR="$HOME/.local/share/cringelinter-agent"

for d in "$HOME/.local/bin" "/usr/local/bin"; do
    link="$d/cringelint"
    if [ -L "$link" ]; then
        rm "$link"
        echo "Removed symlink: $link"
    fi
done

if [ -d "$SHARE_DIR" ]; then
    rm -rf "$SHARE_DIR"
    echo "Removed: $SHARE_DIR"
fi

echo ""
echo "Uninstalled. The cringelinter skill at ~/.claude/skills/cringelinter is preserved."
