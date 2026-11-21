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
# Live `brew shellenv` on purpose (~50ms): it is shell-specific and sets the zsh fpath array per
# shell instance, so its output can't be cached. Its unconditional PATH/INFOPATH prepends are
# stripped and redone idempotently, so re-sourcing (rl) doesn't duplicate entries.
for _brew in /opt/homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
    if [ -x "$_brew" ]; then
        eval "$("$_brew" shellenv | grep -vE '^export (PATH|INFOPATH)=')"
        path_add "$HOMEBREW_PREFIX/sbin"
        path_add "$HOMEBREW_PREFIX/bin"
        case ":${INFOPATH:-}:" in
            *":$HOMEBREW_PREFIX/share/info:"*) ;;
            *) export INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH:-}" ;;
        esac
        break
    fi
done
unset _brew

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
path_add "$HOME/.cargo/bin"
path_add "$HOME/.jbang/bin"
path_add "$HOME/.juliaup/bin"
path_add "$GOPATH/bin" after

# nvm, lazy: put the default node on PATH now (cheap), load nvm itself only when `nvm` is called.
# ponytail: default alias matched as a version prefix ("22" -> newest v22.x); anything else (lts/*, node) -> newest installed.
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    _nvm_default=$(cat "$NVM_DIR/alias/default" 2>/dev/null)
    _d=$(find "$NVM_DIR/versions/node" -maxdepth 1 -name "v${_nvm_default#v}*" 2>/dev/null | sort -V | tail -1)
    # alias like "lts/*" or "node" matches no directory: fall back to the newest installed version
    [ -n "$_d" ] || _d=$(find "$NVM_DIR/versions/node" -maxdepth 1 -name 'v*' 2>/dev/null | sort -V | tail -1)
    [ -n "$_d" ] && path_add "$_d/bin"
    unset _nvm_default _d
    nvm() {
        unset -f nvm
        . "$NVM_DIR/nvm.sh"
        [ -n "$BASH_VERSION" ] && [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
        nvm "$@"
    }
fi

# Claude Code
export ENABLE_LSP_TOOL=1
