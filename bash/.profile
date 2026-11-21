#!/bin/bash
# Entry point. Source it from ~/.zshrc or ~/.bash_profile:
#   . ~/.dotfiles/bash/.profile
# Works in both zsh and bash.

DOTFILES_PATH="$HOME/.dotfiles"
BASH_SRC_PATH="$DOTFILES_PATH/bash"

# Secrets first (git-ignored; copy .secrets.example to .secrets)
if [ -r "$BASH_SRC_PATH/.secrets" ]; then
    [ -n "$(find "$BASH_SRC_PATH/.secrets" -maxdepth 0 \( -perm -040 -o -perm -004 \) 2>/dev/null)" ] &&
        echo "warning: $BASH_SRC_PATH/.secrets is readable by others; run: chmod 600 $BASH_SRC_PATH/.secrets" >&2
    . "$BASH_SRC_PATH/.secrets"
fi

. "$BASH_SRC_PATH/.functions"
. "$BASH_SRC_PATH/.aliases"
[ -d "$HOME/Work/incorta" ] && . "$BASH_SRC_PATH/.aliases.work"

# prompt only makes sense in interactive shells
[[ $- == *i* ]] && . "$BASH_SRC_PATH/.prompt"

# Homebrew first so later path_add entries sit in front of system paths.
# `brew shellenv` is slow (~50ms), so cache its output; it is static for a given install.
for _brew in /opt/homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
    if [ -x "$_brew" ]; then
        _brew_env="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/brew-shellenv.sh"
        if [ ! -s "$_brew_env" ] || [ "$_brew" -nt "$_brew_env" ]; then
            mkdir -p "$(dirname "$_brew_env")" && "$_brew" shellenv > "$_brew_env"
        fi
        # shellcheck source=/dev/null
        . "$_brew_env"
        break
    fi
done
unset _brew _brew_env

# System specific
case $OSTYPE in
    darwin*) . "$BASH_SRC_PATH/.osx" ;;
    linux*)  . "$BASH_SRC_PATH/.linux" ;;
esac

# bash-only: completion (zsh has its own; git ships its own git completion)
if [ -n "$BASH_VERSION" ]; then
    for f in /opt/homebrew/etc/profile.d/bash_completion.sh /usr/local/etc/profile.d/bash_completion.sh /usr/share/bash-completion/bash_completion; do
        # shellcheck source=/dev/null
        [ -r "$f" ] && . "$f" && break
    done
    unset f
fi

# edit this folder
alias dot="cd ~/.dotfiles"
# reload
alias rl='. "$BASH_SRC_PATH/.profile"; echo "dotfiles reloaded."'

case $OSTYPE in
    darwin*) export PNPM_HOME="$HOME/Library/pnpm" ;;
    *)       export PNPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/pnpm" ;;
esac
export GOPATH="$HOME/go"
export BUN_INSTALL="$HOME/.bun"
_mvn=$(find "$HOME" -maxdepth 1 -name 'apache-maven-*' 2>/dev/null | sort -V | tail -1)
[ -n "$_mvn" ] && path_add "$_mvn/bin"
unset _mvn
path_add "$PNPM_HOME"
path_add "$BUN_INSTALL/bin"
path_add "$HOME/.local/bin"
path_add "$GOPATH/bin" after

# nvm, lazy: put the default node on PATH now (cheap), load nvm itself only when `nvm` is called.
# ponytail: default alias matched as a version prefix ("22" -> newest v22.x); aliases like "lts/*" won't resolve.
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    _nvm_default=$(cat "$NVM_DIR/alias/default" 2>/dev/null)
    _d=$(find "$NVM_DIR/versions/node" -maxdepth 1 -name "v${_nvm_default#v}*" 2>/dev/null | sort -V | tail -1)
    [ -n "$_d" ] && path_add "$_d/bin"
    unset _nvm_default _d
    nvm() {
        unset -f nvm
        . "$NVM_DIR/nvm.sh"
        [ -n "$BASH_VERSION" ] && [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
        nvm "$@"
    }
fi
