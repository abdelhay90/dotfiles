#!/bin/bash
# Bootstrap these dotfiles on macOS or Linux (apt, dnf, pacman). Safe to re-run.
#
#   git clone https://github.com/abdelhay90/dotfiles ~/.dotfiles && ~/.dotfiles/bootstrap.sh
#
# Env: SKIP_APPS=1 skips macOS GUI apps.
set -euo pipefail

REPO_URL=https://github.com/abdelhay90/dotfiles
DOTFILES="$HOME/.dotfiles"
NVM_VERSION=v0.40.3
OS=$(uname -s)

log() { printf '\n==> %s\n' "$*"; }

# ---- 1. locate the repo (the dir this script lives in), expose it as ~/.dotfiles
here=$(cd -P "$(dirname "${BASH_SOURCE[0]:-}")" 2>/dev/null && pwd -P || true)
if [ -n "$here" ] && [ -f "$here/bash/.profile" ]; then
    if [ ! -e "$DOTFILES" ]; then
        ln -s "$here" "$DOTFILES"
    elif [ "$(cd -P "$DOTFILES" && pwd -P)" != "$here" ]; then
        echo "$DOTFILES exists and is not this repo ($here). Move it and re-run." >&2
        exit 1
    fi
else  # piped from curl: no local repo yet
    [ -d "$DOTFILES/.git" ] || git clone "$REPO_URL" "$DOTFILES"
    here=$(cd -P "$DOTFILES" && pwd -P)
fi

# ---- 2. packages
log "Installing packages ($OS)"
case "$OS" in
    Darwin)
        if ! command -v brew >/dev/null; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
            [ -x "$b" ] && eval "$("$b" shellenv)" && break
        done
        brew install git shellcheck
        if [ -z "${SKIP_APPS:-}" ]; then
            apps=(iterm2 google-chrome)   # edit to taste
            brew install --cask "${apps[@]}"
        fi
        ;;
    Linux)
        SUDO=""
        if [ "$(id -u)" -ne 0 ]; then
            command -v sudo >/dev/null && SUDO=sudo || { echo "need root or sudo to install packages" >&2; exit 1; }
        fi
        if command -v apt-get >/dev/null; then
            export DEBIAN_FRONTEND=noninteractive
            $SUDO apt-get update -qq
            $SUDO apt-get install -y -qq git curl ca-certificates shellcheck ncurses-bin
        elif command -v dnf >/dev/null; then
            $SUDO dnf install -y git curl ShellCheck ncurses
        elif command -v pacman >/dev/null; then
            $SUDO pacman -Sy --noconfirm --needed git curl shellcheck ncurses
        else
            echo "unsupported package manager: install git, curl, shellcheck, ncurses yourself" >&2
        fi
        ;;
    *) echo "unsupported OS: $OS" >&2; exit 1 ;;
esac

# ---- 3. nvm (pinned) + a default node
log "nvm $NVM_VERSION"
export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | PROFILE=/dev/null bash
fi
if [ ! -d "$NVM_DIR/versions/node" ] || [ -z "$(ls -A "$NVM_DIR/versions/node" 2>/dev/null)" ]; then
    set +u; . "$NVM_DIR/nvm.sh"
    nvm install --lts
    # concrete version: ~/.dotfiles/bash/.profile resolves the default alias as a version prefix
    nvm alias default "$(ls "$NVM_DIR/versions/node" | sort -V | tail -1)"
    set -u
fi

# ---- 4. repo setup
log "Dotfiles"
git -C "$here" config core.hooksPath .githooks
if [ ! -e "$here/bash/.secrets" ]; then
    cp "$here/bash/.secrets.example" "$here/bash/.secrets"
    chmod 600 "$here/bash/.secrets"
    echo "Created bash/.secrets - fill in your tokens."
fi
mkdir -p "$HOME/Personal" "$HOME/Work"

# ---- 5. hook into the login shell's rc file
case "$(basename "${SHELL:-bash}")" in
    zsh)  rc="$HOME/.zshrc" ;;
    *)    if [ "$OS" = Darwin ]; then rc="$HOME/.bash_profile"; else rc="$HOME/.bashrc"; fi ;;
esac
line='. ~/.dotfiles/bash/.profile'
touch "$rc"
grep -qxF "$line" "$rc" || echo "$line" >> "$rc"
echo "Hooked into $rc. Open a new terminal."
