# ~/.zshrc from mac-setup: oh-my-zsh + Starship prompt + modern CLI tools + Node, Go, pnpm PATH setup.
# Edit freely. Running mac-setup again replaces this file (the old one is kept as ~/.zshrc.bak-<date>).

# ---- oh-my-zsh ----
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""   # the prompt is Starship (below); config: ~/.config/starship.toml
HYPHEN_INSENSITIVE="true"
COMPLETION_WAITING_DOTS="true"
HIST_STAMPS="yyyy-mm-dd"

plugins=(
    git
    sudo                 # Esc Esc: add sudo to the current or last command
    dirhistory           # Alt+Left/Right: back/forward through folders
    aliases              # `als`: list all aliases, `als git` to filter
    colored-man-pages
    safe-paste
    zsh-autosuggestions  # grey suggestion from history; Right arrow accepts it
)
# Aliases and completions for tools that are installed
command -v docker >/dev/null && plugins+=(docker)   # e.g. dps, dcup
command -v go >/dev/null && plugins+=(golang)       # e.g. gob, got

source $ZSH/oh-my-zsh.sh

# ---- PATH ----
_path_prepend() { case ":$PATH:" in *":$1:"*) ;; *) [[ -d "$1" ]] && export PATH="$1:$PATH" ;; esac; }
_path_prepend "$HOME/.local/bin"            # uv tools, gitb, pipx-style installs
_path_prepend "${GOPATH:-$HOME/go}/bin"     # `go install` binaries
export PNPM_HOME="$HOME/Library/pnpm"       # `pnpm add -g` binaries
_path_prepend "$PNPM_HOME"
# VS Code CLI: `code .` opens the current folder (no "Install 'code' command" step needed)
_vscode_bin="/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
[[ -d "$_vscode_bin" ]] && case ":$PATH:" in *":$_vscode_bin:"*) ;; *) export PATH="$PATH:$_vscode_bin" ;; esac
unset _vscode_bin

# ---- Node (nvm, fast path) ----
# Sourcing nvm.sh costs ~400ms per shell. Instead, put nvm's default Node on PATH
# directly (alias "24" -> newest installed v24.x; no default -> newest installed),
# so `node`, `npm`, `npx` and `#!/usr/bin/env node` scripts work from the first command.
# nvm itself loads on first use: `nvm use 22`, `nvm install --lts`, ...
export NVM_DIR="$HOME/.nvm"
if [[ -d "$NVM_DIR/versions/node" ]]; then
  _nvm_default=""
  [[ -r "$NVM_DIR/alias/default" ]] && _nvm_default=$(<"$NVM_DIR/alias/default")
  _nvm_default=${_nvm_default#v}
  [[ $_nvm_default =~ '^[0-9]+(\.[0-9]+)*$' ]] || _nvm_default=""   # only "24", "24.1", "24.1.0"
  _nvm_bins=( "$NVM_DIR"/versions/node/v${_nvm_default}*/bin(N/n) )
  (( ${#_nvm_bins} )) && _path_prepend "${_nvm_bins[-1]}"
  unset _nvm_default _nvm_bins
fi
nvm() {
  unset -f nvm
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm "$@"
}

# ---- Completion ----
zstyle ':completion:*' menu select
setopt AUTO_MENU
setopt interactive_comments

# ---- Modern CLI tools ----
# fzf: Ctrl-R fuzzy history, Ctrl-T file picker, Alt-C cd, **<Tab> completion
if command -v fzf >/dev/null; then
  source <(fzf --zsh)
  if command -v fd >/dev/null; then
    # fd respects .gitignore and skips .git
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
fi

# zoxide: `z foo` jumps to the folder you use most that matches "foo"; `zi` picks with fzf
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# bat: colored man pages (run `bat <file>` to view a file with syntax colors)
command -v bat >/dev/null && export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# gitb (gitbasher): short git commands, `gitb` lists them
if command -v gitb >/dev/null; then
  alias g='gitb'
  alias gir='gitb'     # typo-tolerant
  alias girb='gitb'
fi

# Short names for tools that are installed
command -v kubectl >/dev/null && alias k='kubectl'
if command -v docker >/dev/null; then
  alias d='docker'
  alias dc='docker compose'
fi

# eza: ls with colors and git status
if command -v eza >/dev/null; then
  alias ls='eza'
  alias ll='eza -l --git'
  alias la='eza -la --git'
  alias lt='eza --tree --level=2'
fi

# ---- Prompt: Starship ----
command -v starship >/dev/null && eval "$(starship init zsh)"

# Transient prompt: after Enter, the full prompt above the command shrinks to "❯ cmd",
# so the scrollback shows commands and output, not repeated path/git lines.
# Done in zle-line-finish: it keeps bracketed paste working (a pasted multi-line block
# waits for Enter instead of running its first line).
_TRANSIENT_FULL_PROMPT=$PROMPT
_transient_line_finish() {
  # OSC 133 A/B marks tell the terminal where a prompt and its input start.
  # Ghostty uses them for Cmd+Up/Down (jump between commands); other terminals ignore them.
  PROMPT=$'%{\e]133;A\a%}%F{green}❯%f %{\e]133;B\a%}' RPROMPT=''
  zle .reset-prompt
}
zle -N zle-line-finish _transient_line_finish
_transient_restore() { PROMPT=$_TRANSIENT_FULL_PROMPT; }
precmd_functions=(_transient_restore $precmd_functions)

# ---- Quick LLM helpers (only when the signed-in Claude Code CLI `claude` exists) ----
if command -v claude >/dev/null; then
  # ask: short answer to any question.   e.g.  ask how do tcp keepalives work
  ask() {
    claude -p --model haiku "Answer concisely for an experienced developer in a macOS/zsh terminal. Question: $*"
  }
  # how: print ONLY the shell command for a task and copy it to the clipboard.
  #   e.g.  how generate an ed25519 ssh key for github
  how() {
    local out
    out=$(claude -p --model haiku "Output ONLY the shell command(s) to accomplish the following on macOS with zsh. No prose, no explanation, no markdown code fences. Task: $*" \
          | sed -e 's/^```[a-zA-Z]*$//' -e 's/^```$//' -e '/^[[:space:]]*$/d')
    print -r -- "$out"
    if command -v pbcopy >/dev/null; then
      printf '%s' "$out" | command pbcopy && print -P -- "%F{244}  (copied to clipboard)%f"
    fi
  }
fi

# ---- GitHub token for tools that read GITHUB_TOKEN (for example MCP servers) ----
# Off by default: every program you start from the shell can then read the token.
# command -v gh >/dev/null && export GITHUB_TOKEN=$(gh auth token 2>/dev/null)
