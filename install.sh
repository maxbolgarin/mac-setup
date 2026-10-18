#!/usr/bin/env bash
# Set up a Mac for development.
#   terminal: Ghostty, zsh + oh-my-zsh + zsh-autosuggestions, Starship prompt, gitb,
#             fzf / zoxide / bat / eza / fd / tree / htop / jq
#   full:     terminal + Git tools, Go, Node (nvm) + pnpm, Python (uv), just,
#             VS Code with settings and extensions, Docker Desktop
#
# Usage:  ./install.sh              full
#         ./install.sh --terminal   terminal part only
#         ./install.sh --dry-run    only print what would happen
#
# Safe to run again: installed things are skipped, and every config file it
# replaces is first saved as <file>.bak-<date>.
set -euo pipefail

KIT="$(cd "$(dirname "$0")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DRY=0
FULL=1
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --terminal) FULL=0 ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

NVM_VERSION="v0.40.8"

step() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
run() {
  if (( DRY )); then printf '    [dry-run] %s\n' "$*"; else "$@"; fi
}

# Copy one file from the kit into place, saving what was there before.
put() {
  local src="$KIT/$1" dst="$2"
  if [[ -e "$dst" ]] && cmp -s "$src" "$dst"; then
    echo "    same: $dst"; return
  fi
  run mkdir -p "$(dirname "$dst")"
  if [[ -e "$dst" ]]; then
    run cp "$dst" "$dst.bak-$STAMP"
    echo "    backup: $dst.bak-$STAMP"
  fi
  run cp "$src" "$dst"
  echo "    wrote: $dst"
}

[[ "$(uname)" == Darwin ]] || { echo "This kit is for macOS." >&2; exit 1; }

step "Xcode command line tools (git, compilers)"
if xcode-select -p >/dev/null 2>&1; then
  echo "    already installed"
else
  run xcode-select --install
  echo "    Finish the installer window, then run this again."
  exit 0
fi

step "Homebrew"
if ! command -v brew >/dev/null 2>&1 && [[ ! -x /opt/homebrew/bin/brew ]]; then
  # Official one-liner; the outer bash -c keeps --dry-run from downloading it
  run /bin/bash -c '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
fi
if [[ -x /opt/homebrew/bin/brew ]]; then eval "$(/opt/homebrew/bin/brew shellenv)"; fi
command -v brew >/dev/null 2>&1 || (( DRY )) || { echo "brew not found after install" >&2; exit 1; }

step "Terminal packages (Brewfile.terminal)"
run brew bundle --file "$KIT/Brewfile.terminal"

if (( FULL )); then
  step "Dev tools and apps (Brewfile)"
  run brew bundle --file "$KIT/Brewfile"
fi

step "oh-my-zsh + zsh-autosuggestions"
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  echo "    oh-my-zsh already installed"
else
  run env RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
fi
AS="$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
if [[ -d "$AS" ]]; then
  echo "    zsh-autosuggestions already installed"
else
  run git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "$AS"
fi

step "gitb (gitbasher)"
if command -v gitb >/dev/null 2>&1 || [[ -x "$HOME/.local/bin/gitb" ]]; then
  echo "    already installed"
else
  # Official installer: puts gitb into ~/.local/bin (no sudo) and checks its SHA-256
  run bash -c "curl -fsSL https://raw.githubusercontent.com/maxbolgarin/gitbasher/main/install.sh | bash"
fi

if (( FULL )); then
  step "Node (nvm $NVM_VERSION + latest LTS)"
  export NVM_DIR="$HOME/.nvm"
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    echo "    nvm already installed"
  else
    # PROFILE=/dev/null: the nvm installer must not edit .zshrc (the kit's .zshrc handles nvm)
    run env PROFILE=/dev/null bash -c \
      "curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh | bash"
  fi
  if (( DRY )); then
    echo "    [dry-run] nvm install --lts; nvm alias default <LTS major>"
  else
    set +u; . "$NVM_DIR/nvm.sh"
    if [[ -s "$NVM_DIR/alias/default" ]]; then
      echo "    default Node already set: $(nvm version default)"
    else
      nvm install --lts >/dev/null
      # Default = the LTS major number (e.g. "24"): the .zshrc fast path reads it.
      nvm alias default "$(nvm version 'lts/*' | sed 's/^v//; s/\..*//')" >/dev/null
      echo "    node $(nvm version default)"
    fi
    set -u
  fi
fi

step "Config files"
# An existing ~/.zshrc is saved before it is replaced. It is not loaded again:
# copy the lines you still want into ~/.zshrc.local (the new .zshrc loads that file).
ZSHRC_BACKUP=""
if [[ -f "$HOME/.zshrc" ]] && ! cmp -s "$KIT/home/.zshrc" "$HOME/.zshrc"; then
  ZSHRC_BACKUP="$HOME/.zshrc.bak-$STAMP"
  echo "    found an existing ~/.zshrc"
fi
put home/.zshrc                   "$HOME/.zshrc"
put home/.zprofile                "$HOME/.zprofile"
put home/.config/starship.toml    "$HOME/.config/starship.toml"
put home/.config/ghostty/config   "$HOME/.config/ghostty/config"

if (( FULL )); then
  step "VS Code settings and extensions"
  VSC="$HOME/Library/Application Support/Code/User"
  put vscode/settings.json    "$VSC/settings.json"
  put vscode/keybindings.json "$VSC/keybindings.json"
  CODE="$(command -v code || echo "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code")"
  if [[ -x "$CODE" ]]; then
    installed="$("$CODE" --list-extensions 2>/dev/null || true)"
    while read -r ext; do
      ext="${ext%%#*}"; ext="${ext//[[:space:]]/}"   # allow comments and blank lines
      [[ -z "$ext" ]] && continue
      if grep -qix "$ext" <<<"$installed"; then
        echo "    have: $ext"
      elif (( DRY )); then
        echo "    [dry-run] code --install-extension $ext"
      else
        "$CODE" --install-extension "$ext" >/dev/null && echo "    installed: $ext"
      fi
    done < "$KIT/vscode/extensions.txt"
  else
    echo "    VS Code not found: open it once, then run this again for the extensions"
  fi
fi

step "Done"
echo "    Open Ghostty (Applications). The new prompt loads in every new terminal window."
if (( FULL )); then
  echo "    Sign in where needed: gh auth login, Docker Desktop, VS Code (GitHub / Settings Sync)."
fi
if [[ -n "$ZSHRC_BACKUP" ]]; then
  echo "    Your old .zshrc is saved as $ZSHRC_BACKUP"
  echo "    Copy the lines you still need (aliases, PATH, exports) into ~/.zshrc.local"
fi
