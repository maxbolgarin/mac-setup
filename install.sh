#!/usr/bin/env bash
# Set up a Mac for development. Asks what to install, then does it.
#
#   terminal: Ghostty, zsh + oh-my-zsh + zsh-autosuggestions, Starship prompt, gitb,
#             fzf / zoxide / bat / eza / fd / tree / htop / jq
#   dev:      Git tools, Go, Node (nvm) + pnpm, Python (uv), just,
#             VS Code (+ settings, extensions), Docker Desktop
#
# Usage:  ./install.sh              ask for each part (Enter = the default in [Y/n])
#         ./install.sh --yes        no questions: install the defaults
#         ./install.sh --terminal   terminal part only (no dev questions)
#         ./install.sh --dry-run    only print what would happen
#
# Safe to run again: installed things are skipped, and every config file it
# replaces is first saved as <file>.bak-<date>.
# Works with macOS's own bash 3.2 (no bash 4 features).
set -euo pipefail

KIT="$(cd "$(dirname "$0")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DRY=0
YES=0
DEV=1
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    -y|--yes) YES=1 ;;
    --terminal) DEV=0 ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

NVM_VERSION="v0.40.8"
CODE_APP="/Applications/Visual Studio Code.app"
CODE_CLI="$CODE_APP/Contents/Resources/app/bin/code"

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

# ask VAR "question" Y|N — sets VAR to 1 or 0. No questions with --yes or without a terminal.
# Answers are read from the terminal, so this also works as `curl … | bash`.
# MAC_SETUP_TTY swaps the source (used to test the script with a file of answers).
TTY="${MAC_SETUP_TTY:-/dev/tty}"
CAN_ASK=0
if (( ! YES )) && { : <"$TTY"; } 2>/dev/null; then CAN_ASK=1; fi
TTY_IS_FILE=0; [[ -f "$TTY" ]] && TTY_IS_FILE=1
if (( CAN_ASK )); then exec 3<"$TTY"; fi
ask() {
  local var="$1" question="$2" def="$3" hint answer
  if [[ "$def" == Y ]]; then hint="[Y/n]"; else hint="[y/N]"; fi
  answer=""
  if (( CAN_ASK )); then
    read -r -p "  $question $hint " answer <&3 || answer=""
    (( TTY_IS_FILE )) && echo "$answer"
  fi
  [[ -z "$answer" ]] && answer="$def"
  case "$answer" in
    [Yy]*) printf -v "$var" 1 ;;
    *)     printf -v "$var" 0 ;;
  esac
}

# Install extensions listed in a file (one id per line, # comments allowed).
install_extensions() {
  local list="$1" installed ext
  installed="$("$CODE_CLI" --list-extensions 2>/dev/null || true)"
  while read -r ext; do
    ext="${ext%%#*}"; ext="${ext//[[:space:]]/}"
    [[ -z "$ext" ]] && continue
    if grep -qix "$ext" <<<"$installed"; then
      echo "    have: $ext"
    elif (( DRY )); then
      echo "    [dry-run] code --install-extension $ext"
    else
      "$CODE_CLI" --install-extension "$ext" >/dev/null && echo "    installed: $ext"
    fi
  done < "$list"
}

[[ "$(uname)" == Darwin ]] || { echo "This kit is for macOS." >&2; exit 1; }

# ---------------------------------------------------------------- questions
step "What to install"
(( CAN_ASK )) || echo "  (no questions: using the defaults)"
echo "  Terminal"
ask T_PKGS    "Terminal apps and tools (Ghostty, Starship, fzf, zoxide, bat, eza, fd, …)?" Y
ask T_SHELL   "Shell setup: oh-my-zsh + this kit's ~/.zshrc and Starship prompt?" Y
ask T_GHOSTTY "Ghostty config (dark theme, keys, SSH colors)?" Y
ask T_GITB    "gitb (short git commands)?" Y
D_TOOLS=0; D_NODE=0; D_CODE=0; D_CODE_SET=0; D_CODE_EXT=0; D_CODE_OPT=0; D_DOCKER=0
if (( DEV )); then
  echo "  Dev"
  ask D_TOOLS  "Dev tools (git, gh, Go, golangci-lint, pnpm, uv, just, …)?" Y
  ask D_NODE   "Node via nvm (latest LTS)?" Y
  ask D_CODE   "VS Code app?" Y
  if (( D_CODE )) || [[ -d "$CODE_APP" ]]; then
    ask D_CODE_SET "VS Code settings and keybindings (yours are backed up)?" Y
    ask D_CODE_EXT "VS Code extensions (Go, Python, ESLint, Prettier, YAML, Docker, …)?" Y
    ask D_CODE_OPT "Optional extensions (Terraform, Ansible, Astro, Caddyfile, …)?" N
  fi
  ask D_DOCKER "Docker Desktop?" Y
fi

if (( CAN_ASK )); then
  ask GO "Start?" Y
  (( GO )) || { echo "  Nothing done."; exit 0; }
fi

# ---------------------------------------------------------------- base
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
else
  echo "    already installed"
fi
if [[ -x /opt/homebrew/bin/brew ]]; then eval "$(/opt/homebrew/bin/brew shellenv)"; fi
command -v brew >/dev/null 2>&1 || (( DRY )) || { echo "brew not found after install" >&2; exit 1; }

# ---------------------------------------------------------------- terminal
if (( T_PKGS )); then
  step "Terminal apps and tools (Brewfile.terminal)"
  run brew bundle --file "$KIT/Brewfile.terminal"
fi

ZSHRC_BACKUP=""
if (( T_SHELL )); then
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

  step "Shell config"
  # An existing ~/.zshrc is saved before it is replaced. It is not loaded again:
  # copy the lines you still want into ~/.zshrc.local (the new .zshrc loads that file).
  if [[ -f "$HOME/.zshrc" ]] && ! cmp -s "$KIT/home/.zshrc" "$HOME/.zshrc"; then
    ZSHRC_BACKUP="$HOME/.zshrc.bak-$STAMP"
    echo "    found an existing ~/.zshrc"
  fi
  put home/.zshrc                "$HOME/.zshrc"
  put home/.zprofile             "$HOME/.zprofile"
  put home/.config/starship.toml "$HOME/.config/starship.toml"
fi

if (( T_GHOSTTY )); then
  step "Ghostty config"
  put home/.config/ghostty/config "$HOME/.config/ghostty/config"
fi

if (( T_GITB )); then
  step "gitb (gitbasher)"
  if command -v gitb >/dev/null 2>&1 || [[ -x "$HOME/.local/bin/gitb" ]]; then
    echo "    already installed"
  else
    # Official installer: puts gitb into ~/.local/bin (no sudo) and checks its SHA-256
    run bash -c "curl -fsSL https://raw.githubusercontent.com/maxbolgarin/gitbasher/main/install.sh | bash"
  fi
fi

# ---------------------------------------------------------------- dev
if (( D_TOOLS )); then
  step "Dev tools (Brewfile)"
  run brew bundle --file "$KIT/Brewfile"
fi

if (( D_NODE )); then
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

if (( D_CODE )); then
  step "VS Code"
  if [[ -d "$CODE_APP" ]]; then
    echo "    already installed"
  else
    run brew install --cask visual-studio-code
  fi
fi

if (( D_CODE_SET )); then
  step "VS Code settings and keybindings"
  VSC="$HOME/Library/Application Support/Code/User"
  put vscode/settings.json    "$VSC/settings.json"
  put vscode/keybindings.json "$VSC/keybindings.json"
fi

if (( D_CODE_EXT || D_CODE_OPT )); then
  step "VS Code extensions"
  if [[ -x "$CODE_CLI" ]] || (( DRY )); then
    if (( D_CODE_EXT )); then install_extensions "$KIT/vscode/extensions.txt"; fi
    if (( D_CODE_OPT )); then install_extensions "$KIT/vscode/extensions-optional.txt"; fi
  else
    echo "    VS Code not found: install it, then run this again for the extensions"
  fi
fi

if (( D_DOCKER )); then
  step "Docker Desktop"
  if [[ -d "/Applications/Docker.app" ]]; then
    echo "    already installed"
  else
    run brew install --cask docker-desktop
  fi
fi

# ---------------------------------------------------------------- done
step "Done"
if (( T_SHELL || T_GHOSTTY )); then
  echo "    Open Ghostty (Applications). The new prompt loads in every new terminal window."
fi
if (( D_TOOLS )); then echo "    GitHub CLI: gh auth login"; fi
if (( D_DOCKER )); then echo "    Docker Desktop: open it once to finish its setup."; fi
if [[ -n "$ZSHRC_BACKUP" ]]; then
  echo "    Your old .zshrc is saved as $ZSHRC_BACKUP"
  echo "    Copy the lines you still need (aliases, PATH, exports) into ~/.zshrc.local"
fi
