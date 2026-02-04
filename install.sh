#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

AI_SCRIPTS_PATH="${AI_SCRIPTS_PATH:-$HOME/.ai/scripts/generic}"

mkdir -p "$(dirname "$AI_SCRIPTS_PATH")"

GENERIC_SCRIPTS_DIR="$REPO_ROOT/scripts/generic"

mkdir -p "$GENERIC_SCRIPTS_DIR"
touch "$GENERIC_SCRIPTS_DIR/.keep"

if [ -e "$AI_SCRIPTS_PATH" ] && [ ! -L "$AI_SCRIPTS_PATH" ]; then
    echo "Error: $AI_SCRIPTS_PATH exists but is not a symlink" >&2
    exit 1
fi

if [ -L "$AI_SCRIPTS_PATH" ]; then
    existing_target="$(readlink "$AI_SCRIPTS_PATH")"
    if [ "$existing_target" = "$GENERIC_SCRIPTS_DIR" ]; then
        echo "Symlink already exists and points to correct location"
        exit 0
    fi
    rm "$AI_SCRIPTS_PATH"
fi

ln -s "$GENERIC_SCRIPTS_DIR" "$AI_SCRIPTS_PATH"

echo "Installation complete: $AI_SCRIPTS_PATH -> $GENERIC_SCRIPTS_DIR"
