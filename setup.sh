#!/usr/bin/env bash
set -euo pipefail

REPO_URL="<shell-suite-repo-url>"  # Replace with the actual repository URL
INSTALL_DIR="$HOME/.shell-suite"

if [ -d "$INSTALL_DIR" ]; then
    echo "~/.shell-suite already exists — skipping clone" >&2
else
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

# Add the dispatcher to PATH in both rc files, regardless of which shell
# happens to be running this script right now (curl | bash always sets
# BASH_VERSION, even for a zsh user) — the shell this runs under tells you
# nothing about which shell the user actually uses day to day.
PATH_LINE='export PATH="$HOME/.shell-suite/bin:$PATH"'
for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
    touch "$rc"
    if ! grep -qF "$PATH_LINE" "$rc"; then
        printf '\n# Added by Shell-Suite setup\n%s\n' "$PATH_LINE" >> "$rc"
    fi
done

echo "Shell-Suite installed. Open a new terminal (or run 'source ~/.zshrc' / 'source ~/.bashrc') to start using it."
echo
echo "Usage examples:"
echo "  shell-suite install <command>  # Install a command from the suite"

exit 0
