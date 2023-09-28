source_if_exists () {
    if test -r "$1"; then
        source "$1"
    fi
}

source_if_exists $HOME/.env.sh
source_if_exists $HOME/.local/bin/z.sh
source_if_exists $DOTFILES/zsh/history.zsh
source_if_exists $DOTFILES/zsh/git.zsh
source_if_exists ~/.fzf.zsh
source_if_exists $DOTFILES/zsh/aliases.zsh

if type "direnv" > /dev/null; then
    eval "$(direnv hook zsh)"
fi

autoload -U zmv
autoload -U promptinit && promptinit
autoload -U colors && colors
autoload -Uz compinit && compinit

if test -z ${ZSH_HIGHLIGHT_DIR+x}; then
else
    source $ZSH_HIGHLIGHT_DIR/zsh-syntax-highlighting.zsh
fi

precmd() {
    source $DOTFILES/zsh/aliases.zsh
}

export VISUAL=nvim
export EDITOR=nvim
export PATH="$PATH:/usr/local/sbin:$DOTFILES/bin:$HOME/.local/bin:$HOME/neovim/bin"

eval "$(starship init zsh)"

# VIM MODE (http://dougblack.io/words/zsh-vi-mode.html) -----------------------
# bindkey -v
bindkey '^?' backward-delete-char

# function zle-line-init zle-keymap-select {
#     VIM_PROMPT="%{$fg[yellow]%}[% NORMAL]% %{$reset_color%}"
#     RPS1="${${KEYMAP/vicmd/$VIM_PROMPT}/(main|viins)/}"
#     zle reset-prompt
# }

# zle -N zle-line-init
# zle -N zle-keymap-select
# export KEYTIMEOUT=1
# END VIM MODE ----------------------------------------------------------------

#eval "$(lua ~/bin/z.lua --init zsh)"

source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
fpath+=~/.zfunc
autoload -Uz compinit && compinit


# Fix ctrl-r in tmux
bindkey -v
bindkey '^R' history-incremental-search-backward
