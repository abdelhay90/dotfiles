#!/bin/bash

DOTFILES_PATH=~/.dotfiles
BASH_SRC_PATH=$DOTFILES_PATH/bash

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

PNPM_HOME="/Users/ahmed_abdulhay/Library/pnpm"
PATH="$PNPM_HOME:$PATH"
GOPATH=$HOME/go
PATH="/Users/ahmed_abdulhay/apache-maven-3.9.3/bin:$PATH"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
eval "$(/opt/homebrew/bin/brew shellenv)"
export BUN_INSTALL="$HOME/.bun" 
export PATH="$BUN_INSTALL/bin:$PATH" 
export PATH="$HOME/.local/bin:$PATH"
export ANTHROPIC_AUTH=ollama
export ANTHROPIC_BASE_URL=http://localhost:11434