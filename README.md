# mac-setup

One command to set up a nice terminal on a Mac:

- **Ghostty**: fast, native terminal app (high-contrast dark theme; reports `xterm-256color`, so prompts on SSH servers keep their colors)
- **zsh + oh-my-zsh + zsh-autosuggestions**: grey suggestions from your history
- **Starship** prompt: full path, rich git status, command time and exit code; old prompts shrink to `❯ cmd`
- **gitb** ([gitbasher](https://github.com/maxbolgarin/gitbasher)): short git commands, alias `g`
- **fzf** (Ctrl-R history search, Ctrl-T file picker), **zoxide** (`z <dir>`), **bat** (also colors man pages), **eza**, **fd**, **tree**, **htop**, **jq**

## Install

```bash
git clone https://github.com/maxbolgarin/mac-setup.git && cd mac-setup && ./install.sh
```

Or as one file: run `./build.sh`, send `dist/mac-setup.sh` to the other Mac, then:

```bash
bash ~/Downloads/mac-setup.sh
```

Add `--dry-run` to only print the steps.

It is safe to run again: installed things are skipped, and every config file it replaces is saved as `<file>.bak-<date>`. If you already have a `~/.zshrc`, it is saved as `~/.zshrc.bak-<date>` and not loaded again. Copy the lines you still need into `~/.zshrc.local`: the new `.zshrc` loads that file at the end, and the installer never touches it.

## What goes where

| File in the repo | Installed to |
|---|---|
| `Brewfile` | Homebrew packages |
| `home/.zshrc` | `~/.zshrc` |
| `home/.zprofile` | `~/.zprofile` (Homebrew on PATH) |
| `home/.config/starship.toml` | `~/.config/starship.toml` |
| `home/.config/ghostty/config` | `~/.config/ghostty/config` |

## Prompt

```
~/code/project  main [!2 ?1] +12 -3  4s ✘ 1
❯
```
Path · branch · git status (`⇡⇣` ahead/behind, `!` modified, `+` staged, `?` untracked, `$` stash) · lines added/removed · time (if > 2 s) · exit code (if it failed).

## Ghostty keys

| Keys | Action |
|---|---|
| `Cmd+T`, `Cmd+D`, `Cmd+Shift+D` | New tab, split right, split down |
| `Cmd+↑` / `Cmd+↓` | Jump to the previous / next command |
| `Cmd+F` | Search the scrollback |
| `Cmd+Shift+P` | Command palette |
| `Cmd+,` / `Cmd+Shift+,` | Open / reload the config |
