#!/bin/bash
# Entry point. Source it from ~/.zshrc or ~/.bash_profile:
#   . ~/.dotfiles/bash/.profile
# Works in both zsh and bash.

DOTFILES_PATH="$HOME/.dotfiles"
BASH_SRC_PATH="$DOTFILES_PATH/bash"

# Secrets first (git-ignored; copy .secrets.example to .secrets)
[ -r "$BASH_SRC_PATH/.secrets" ] && . "$BASH_SRC_PATH/.secrets"

. "$BASH_SRC_PATH/.functions"
. "$BASH_SRC_PATH/.aliases"

# prompt only makes sense in interactive shells
[[ $- == *i* ]] && . "$BASH_SRC_PATH/.prompt"

# Homebrew first so later path_add entries sit in front of system paths
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

# System specific
[[ $OSTYPE == darwin* ]] && . "$BASH_SRC_PATH/.osx"

# bash-only: completion (zsh has its own)
if [ -n "$BASH_VERSION" ]; then
    for f in /opt/homebrew/etc/profile.d/bash_completion.sh /usr/local/etc/profile.d/bash_completion.sh; do
        # shellcheck source=/dev/null
        [ -r "$f" ] && . "$f" && break
    done
    . "$BASH_SRC_PATH/.git-completion.bash"
fi

# edit this folder
alias dot="cd ~/.dotfiles"
# reload
alias rl='. "$BASH_SRC_PATH/.profile"; echo "dotfiles reloaded."'

export PNPM_HOME="$HOME/Library/pnpm"
export GOPATH="$HOME/go"
export BUN_INSTALL="$HOME/.bun"
path_add "$HOME/apache-maven-3.9.3/bin"
path_add "$PNPM_HOME"
path_add "$BUN_INSTALL/bin"
path_add "$HOME/.local/bin"
path_add "$GOPATH/bin" after

# nvm, lazy: put the default node on PATH now (cheap), load nvm itself only when `nvm` is called.
# ponytail: default alias matched as a version prefix ("22" -> newest v22.x); aliases like "lts/*" won't resolve.
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    _nvm_default=$(cat "$NVM_DIR/alias/default" 2>/dev/null)
    _d=$(ls -d "$NVM_DIR"/versions/node/v"${_nvm_default#v}"* 2>/dev/null | sort -V | tail -1)
    [ -n "$_d" ] && path_add "$_d/bin"
    unset _nvm_default _d
    nvm() {
        unset -f nvm
        . "$NVM_DIR/nvm.sh"
        [ -n "$BASH_VERSION" ] && [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
        nvm "$@"
    }
fi
