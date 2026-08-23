#!/usr/bin/env bash

# Output list of install options from sources.list

while IFS='|' read -r name url desc; do
    case "$name" in
        ''|'#'*) continue ;;   # skip blank lines and comments
    esac
    printf '%s - %s\n' "$name" "$desc"
    # later: on selection, git clone "$url" ~/.shell-suite/"$name"
done < sources.list