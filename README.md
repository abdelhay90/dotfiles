# Dotfiles

Shell setup for macOS (zsh or bash): prompt with git info, aliases, functions, lazy-loaded nvm.

## Install

```bash
git clone https://github.com/abdelhay90/dotfiles ~/.dotfiles && ~/.dotfiles/bootstrap.sh
```

Or by hand: add `. ~/.dotfiles/bash/.profile` to `~/.zshrc` (or `~/.bash_profile`).

## Secrets

Tokens/API keys live in `bash/.secrets`, which is git-ignored and loaded first by `.profile`.

```bash
cp bash/.secrets.example bash/.secrets && chmod 600 bash/.secrets   # then fill in your values
```

A pre-commit hook (`git config core.hooksPath .githooks`, done by `bootstrap.sh`) blocks staged
secrets and runs shellcheck.

## Layout

| File | Purpose |
|------|---------|
| `bash/.profile` | entry point, PATH setup, nvm |
| `bash/.aliases`, `bash/.functions` | shortcuts and helpers (`path_add`, `gclean`, `clean`, ...) |
| `bash/.prompt` | prompt with branch + dirty marker |
| `bash/.osx` | macOS-only settings |
| `bash/.hints` | cheat sheet, run `hint` |

Also in the repo: iTerm2 colors, a font, and Finder helper apps under `tools/`.
