#!/usr/bin/env bash
# Set up a Mac terminal: Ghostty, zsh + oh-my-zsh + zsh-autosuggestions, the Starship
# prompt, and fzf / zoxide / bat / eza / fd.
#
# Usage:  ./install.sh            install
#         ./install.sh --dry-run  only print what would happen
#
# Safe to run again: installed things are skipped, and every config file it
# replaces is first saved as <file>.bak-<date>.
set -euo pipefail

KIT="$(cd "$(dirname "$0")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DRY=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

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
  run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
if [[ -x /opt/homebrew/bin/brew ]]; then eval "$(/opt/homebrew/bin/brew shellenv)"; fi
command -v brew >/dev/null 2>&1 || (( DRY )) || { echo "brew not found after install" >&2; exit 1; }

step "Packages (Brewfile)"
run brew bundle --file "$KIT/Brewfile"

step "oh-my-zsh + zsh-autosuggestions"
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  echo "    oh-my-zsh already installed"
else
  run env RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
AS="$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
if [[ -d "$AS" ]]; then
  echo "    zsh-autosuggestions already installed"
else
  run git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "$AS"
fi

step "Config files"
# Keep the old .zshrc's own lines: if there was a .zshrc and no .zshrc.local yet,
# the old one becomes .zshrc.local (the new .zshrc loads it at the end).
if [[ -f "$HOME/.zshrc" && ! -e "$HOME/.zshrc.local" ]] && ! cmp -s "$KIT/home/.zshrc" "$HOME/.zshrc"; then
  run cp "$HOME/.zshrc" "$HOME/.zshrc.local"
  echo "    old .zshrc kept as ~/.zshrc.local (check it, remove what you don't need)"
fi
put home/.zshrc                   "$HOME/.zshrc"
put home/.zprofile                "$HOME/.zprofile"
put home/.config/starship.toml    "$HOME/.config/starship.toml"
put home/.config/ghostty/config   "$HOME/.config/ghostty/config"

step "Done"
echo "    Open Ghostty (Applications). The new prompt loads in every new terminal window."
