#!/bin/bash
# Set up a macOS machine with these dotfiles. Safe to re-run.
set -euo pipefail

REPO=https://github.com/abdelhay90/dotfiles
DOTFILES="$HOME/.dotfiles"
NVM_VERSION=v0.40.3

# Homebrew
if ! command -v brew >/dev/null; then
    echo "Installing homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
brew update
brew install git shellcheck

# nvm (pinned version)
if [ ! -s "$HOME/.nvm/nvm.sh" ]; then
    echo "Installing nvm $NVM_VERSION..."
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | PROFILE=/dev/null bash
fi

# optional apps: edit to taste
apps=(iterm2 google-chrome)
brew install --cask "${apps[@]}"

# this repo
[ -d "$DOTFILES" ] || git clone "$REPO" "$DOTFILES"
git -C "$DOTFILES" config core.hooksPath .githooks

# secrets: create your own from the template (never committed)
if [ ! -e "$DOTFILES/bash/.secrets" ]; then
    cp "$DOTFILES/bash/.secrets.example" "$DOTFILES/bash/.secrets"
    chmod 600 "$DOTFILES/bash/.secrets"
    echo "Created bash/.secrets - fill in your tokens."
fi

mkdir -p ~/Personal ~/Work

# load dotfiles from zsh (macOS default shell)
line='. ~/.dotfiles/bash/.profile'
grep -qxF "$line" ~/.zshrc 2>/dev/null || echo "$line" >> ~/.zshrc
echo "Done. Open a new terminal."
