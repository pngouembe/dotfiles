source_if_exists () {
    if test -r "$1"; then
        source "$1"
    fi
}

# Setting up oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"
plugins=(
    docker
    docker-compose
    git
    sudo
    zsh-256color
    zsh-autosuggestions
    zsh-syntax-highlighting
)
source_if_exists $ZSH/oh-my-zsh.sh
autoload compinit
compinit -i

# Installing zsh aliases
source_if_exists $HOME/.zsh/aliases.zsh

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

export VISUAL=nvim
export EDITOR=nvim
export PATH="$PATH:/usr/local/sbin:$HOME/.local/bin:$HOME/neovim/bin"

# Fix tmux colors
export TERM=xterm-256color

# Arch linux additions
if test -f /etc/arch-release ; then
    source "$HOME/.zsh/arch-linux.zsh"
fi
