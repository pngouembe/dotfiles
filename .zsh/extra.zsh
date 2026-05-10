source_if_exists () {
    if test -r "$1"; then
        source "$1"
    fi
}

# Local zsh config split into focused files
source_if_exists $HOME/.zsh/aliases.zsh
source_if_exists $HOME/.zsh/git.zsh
source_if_exists $HOME/.zsh/history.zsh

# Setup bat
export BAT_THEME="Catppuccin Mocha"

# Set up fzf key bindings and fuzzy completion
source_if_exists $HOME/.fzf.zsh

# TODO: Fix me, I don't know why source_if_exists is not working
if test -r "$HOME/.fzf-git/fzf-git.sh"; then
    source "$HOME/.fzf-git/fzf-git.sh"
fi

## use fd as default fzf command
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --follow --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --follow --exclude .git"

_fzf_compgen_path() {
    fd --hidden --follow --exclude .git . "$1"
}

_fzf_compgen_dir() {
    fd --type=d --hidden --follow --exclude .git . "$1"
}

## use bat as previewer
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=header,grid --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --icons --group-directories-first --git --color=always --tree --level=2 {}'"

_fzf_comprun() {
    local command=$1
    shift

    case "$command" in
        cd)             fzf --preview 'eza --icons --tree {} | head -200' "$@" ;;
        export|unset)   fzf --preview "eval 'echo \$' {}" "$@" ;;
        ssh)            fzf --preview 'dig {}' "$@" ;;
        *)              fzf --preview "--preview 'bat -n --color=always --style=header,grid --line-range :500 {}'" "$@" ;;
    esac
}

## Set Catppuccin as the default theme
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

# Initialise the starship prompt
eval "$(starship init zsh)"

# Initialise zoxide
eval "$(zoxide init --cmd cd zsh)"

# Re-enter zsh inside `nix-shell` / `nix develop` so this rc is loaded there too.
# Only available on Nix-based systems.
if command -v nix-your-shell >/dev/null 2>&1; then
    eval "$(nix-your-shell zsh)"
fi

export VISUAL=nvim
export EDITOR=nvim
export PATH="$PATH:/usr/local/sbin:$HOME/.local/bin:$HOME/neovim/bin"

# Fix tmux colors
export TERM=xterm-256color
