# Dotfiles

Shell setup for macOS and Linux (zsh or bash): prompt with git info, aliases, functions, lazy-loaded nvm.

## Install

```bash
git clone https://github.com/abdelhay90/dotfiles ~/.dotfiles && ~/.dotfiles/bootstrap.sh
```

`bootstrap.sh` works on macOS (Homebrew) and Linux (apt, dnf, pacman) and is safe to re-run. It:

1. links the clone to `~/.dotfiles` if it lives elsewhere,
2. installs git, shellcheck (and Homebrew + GUI apps on macOS; `SKIP_APPS=1` skips the apps),
3. installs nvm (pinned) and a default Node LTS,
4. enables the pre-commit hook and creates `bash/.secrets` from the template,
5. copies the fonts in `fonts/` to your user font directory,
6. adds `. ~/.dotfiles/bash/.profile` to your shell's rc file (`~/.zshrc`, `~/.bash_profile` on macOS, `~/.bashrc` on Linux).

Tested on Ubuntu 24.04 and Fedora 41 containers and on macOS.

## Secrets

Tokens/API keys live in `bash/.secrets`, which is git-ignored and loaded first by `.profile`.

```bash
cp bash/.secrets.example bash/.secrets && chmod 600 bash/.secrets   # then fill in your values
```

Prefer scoping a secret to one command (see the `claude()` wrapper pattern in the template) over a
global `export`, so child processes don't inherit it. `.profile` warns if `.secrets` is readable by
others.

Note: the `claude()` wrapper only applies to interactive shells that sourced `.secrets`. Scripts, cron
and IDE-launched tools won't see the token; use a plain `export` in `.secrets` if you need that.

A pre-commit hook (`git config core.hooksPath .githooks`, done by `bootstrap.sh`) blocks staged
secrets (including `bash/.secrets` itself) and runs shellcheck on the staged shell files.

## Layout

| File | Purpose |
|------|---------|
| `bash/.profile` | entry point, PATH setup, nvm |
| `bash/.aliases`, `bash/.functions` | shortcuts and helpers (`path_add`, `gclean`, `clean`, ...) |
| `bash/.aliases.work` | Incorta aliases, loaded only if `~/Work/incorta` exists |
| `bash/.prompt` | prompt with branch + dirty marker |
| `bash/.osx`, `bash/.linux` | OS-specific settings, picked by `$OSTYPE` |
| `bash/.hints` | cheat sheet, run `hint` |

The iTerm2 color scheme in `iterm/` is imported by hand (bootstrap prints where).

## Credits

Started from [yyx990803/dotfiles](https://github.com/yyx990803/dotfiles). The `mark`/`j` functions come
from Jeroen Janssens, `extract` from nparikh.org. No license file: the upstream repo has none, so
check before reusing code from here.
