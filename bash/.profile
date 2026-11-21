#!/bin/bash

DOTFILES_PATH=~/.dotfiles
BASH_SRC_PATH=$DOTFILES_PATH/bash

# Secrets first (git-ignored; copy .secrets.example to .secrets)
[ -r "$BASH_SRC_PATH/.secrets" ] && . "$BASH_SRC_PATH/.secrets"

. "$BASH_SRC_PATH"/.prompt
. "$BASH_SRC_PATH"/.aliases
. "$BASH_SRC_PATH"/.functions

# System Specific
if [[ ! "$SSH_TTY" && "$OSTYPE" =~ ^darwin ]]; then
	. "$BASH_SRC_PATH"/.osx
else
	. "$BASH_SRC_PATH"/.ubuntu
fi

[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"

# edit this folder
alias dot="cd ~/.dotfiles"
# reload
alias rl="source ~/.profile; echo '~/.profile reloaded.'"

PNPM_HOME="$HOME/Library/pnpm"
PATH="$PNPM_HOME:$PATH"
export GOPATH=$HOME/go
[ -d "$HOME/apache-maven-3.9.3/bin" ] && PATH="$HOME/apache-maven-3.9.3/bin:$PATH"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
eval "$(/opt/homebrew/bin/brew shellenv)"
export BUN_INSTALL="$HOME/.bun" 
export PATH="$BUN_INSTALL/bin:$PATH" 
export PATH="$HOME/.local/bin:$PATH"
export PATH="$PATH:$GOPATH/bin"
# export ANTHROPIC_AUTH_TOKEN=ollama
# export ANTHROPIC_BASE_URL=http://localhost:11434
# export ANTHROPIC_API_KEY=ollama
export ENABLE_LSP_TOOL=1
