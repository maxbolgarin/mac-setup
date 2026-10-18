# mac-setup

One command to set up a Mac for development. The installer asks about each part (Enter takes the default), then installs only what you said yes to.

**Terminal** (each part is its own question):
- **Ghostty**: fast, native terminal app (high-contrast dark theme; reports `xterm-256color`, so prompts on SSH servers keep their colors)
- **zsh + oh-my-zsh + zsh-autosuggestions**: grey suggestions from your history
- **Starship** prompt: full path, rich git status, command time and exit code; old prompts shrink to `❯ cmd`
- **gitb** ([gitbasher](https://github.com/maxbolgarin/gitbasher)): short git commands, alias `g`
- **fzf** (Ctrl-R history search, Ctrl-T file picker), **zoxide** (`z <dir>`), **bat** (also colors man pages), **eza**, **fd**, **tree**, **htop**, **jq**

**Dev** (each one is its own question; skipped with `--terminal`):
- **Git**: `git`, `gh` (GitHub CLI), `shellcheck`
- **Go** + `golangci-lint`
- **Node** via **nvm** (latest LTS as default) + **pnpm**
- **Python** via **uv** (projects, tools and Python versions)
- **just** (command runner), **httpie**
- **VS Code**, and separately its settings + keybindings, the extensions (Go, Python + Ruff, ESLint, Prettier, YAML, TOML, Docker, GitHub Actions, Remote SSH, Error Lens, Claude Code, …) and optional extensions (Terraform, Ansible, Astro, Caddyfile, Go templates, Makefile, PDF; off by default)
- **Docker Desktop**

## Install

```bash
git clone https://github.com/maxbolgarin/mac-setup.git && cd mac-setup && ./install.sh
```

It asks, for example:

```
  Terminal apps and tools (Ghostty, Starship, fzf, zoxide, bat, eza, fd, …)? [Y/n]
  VS Code app? [Y/n]
  VS Code settings and keybindings (yours are backed up)? [Y/n]
  Optional extensions (Terraform, Ansible, Astro, Caddyfile, …)? [y/N]
  Start? [Y/n]
```

| Option | Does |
|---|---|
| `--yes` | No questions, install the defaults |
| `--terminal` | Terminal part only, no dev questions |
| `--dry-run` | Ask, then only print the steps |

Without a terminal (for example in CI) it uses the defaults.

Or as one file: run `./build.sh`, send `dist/mac-setup.sh` (full) or `dist/mac-setup-terminal.sh` to the other Mac, then:

```bash
bash ~/Downloads/mac-setup.sh
```

It is safe to run again: installed things are skipped, and every config file it replaces is saved as `<file>.bak-<date>`. If you already have a `~/.zshrc`, it is saved as `~/.zshrc.bak-<date>` and not loaded again. Copy the lines you still need into `~/.zshrc.local`: the new `.zshrc` loads that file at the end, and the installer never touches it.

After the install, sign in where needed: `gh auth login`, Docker Desktop, VS Code (GitHub / Settings Sync).

## What goes where

| File in the repo | Installed to | Kit |
|---|---|---|
| `Brewfile.terminal` | Homebrew packages | both |
| `Brewfile` | Homebrew dev tools (optional ones are commented out: terraform, kubectl, awscli, postgres, …) | full |
| `home/.zshrc` | `~/.zshrc` | both |
| `home/.zprofile` | `~/.zprofile` (Homebrew on PATH) | both |
| `home/.zshrc.local.example` | `~/.zshrc.local`, only if you say yes and the file does not exist yet | both |
| `home/.config/starship.toml` | `~/.config/starship.toml` | both |
| `home/.config/ghostty/config` | `~/.config/ghostty/config` | both |
| `vscode/settings.json`, `vscode/keybindings.json` | `~/Library/Application Support/Code/User/` | full |
| `vscode/extensions.txt` | VS Code extensions | full |
| `vscode/extensions-optional.txt` | Optional VS Code extensions (asked, off by default) | full |

## Shell

- **Fast start** (about 0.2 s): nvm is not loaded at startup. The default Node goes straight onto `PATH`, and `nvm` itself loads the first time you type it (`nvm use 22`, `nvm install --lts`).
- `PATH` also gets `~/.local/bin` (uv tools, gitb), `~/go/bin` (`go install`), `~/Library/pnpm` (`pnpm add -g`) and the VS Code `code` command.
- `~/.zshrc.local` is yours: loaded last, never overwritten. The example adds aliases (`k`, `d`, `dc`) and two Claude Code helpers: `ask <question>` gives a short answer, `how <task>` prints just the shell command and copies it.
- oh-my-zsh plugins: `git`, `sudo` (Esc Esc), `dirhistory` (Alt+←/→), `aliases` (`als`), `colored-man-pages`, `safe-paste`, `zsh-autosuggestions`, plus `docker` and `golang` when those tools are installed.
- `ls`/`ll`/`la`/`lt` use eza; `z <dir>` jumps with zoxide.

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
