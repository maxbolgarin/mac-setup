# ~/.zshrc from mac-setup: oh-my-zsh + Starship prompt + a few modern CLI tools.
# Put your own aliases and settings in ~/.zshrc.local (loaded at the end, never overwritten).

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
    colored-man-pages
    safe-paste
    zsh-autosuggestions  # grey suggestion from history; Right arrow accepts it
)

source $ZSH/oh-my-zsh.sh

# ---- PATH ----
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac

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

# bat: cat with syntax colors; also the man pager
if command -v bat >/dev/null; then
  alias cat='bat --paging=never'
  alias catp='bat'
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
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

# ---- Your own settings ----
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
