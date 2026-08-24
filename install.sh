#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="$HOME/.shell-suite"
SOURCES_FILE="$INSTALL_DIR/sources.list"
NAME="${1:-}"

list_sources() {
    while IFS='|' read -r name url desc; do
        case "$name" in
            ''|'#'*) continue ;;   # skip blank lines and comments
        esac
        printf '  %s - %s\n' "$name" "$desc"
    done < "$SOURCES_FILE"
}

if [ -z "$NAME" ]; then
    echo "Usage: shell-suite install <name>"
    echo
    echo "Available components:"
    list_sources
    exit 0
fi

while IFS='|' read -r name url desc; do
    case "$name" in
        ''|'#'*) continue ;;
    esac
    if [ "$name" = "$NAME" ]; then
        if [ -d "$INSTALL_DIR/$name" ]; then
            echo "$name is already installed at $INSTALL_DIR/$name" >&2
            exit 0
        fi
        git clone "$url" "$INSTALL_DIR/$name"
        echo "Installed $name."
        exit 0
    fi
done < "$SOURCES_FILE"

echo "Unknown component: $NAME" >&2
echo "Run 'shell-suite install' with no arguments to see available components." >&2
exit 1
