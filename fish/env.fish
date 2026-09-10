# Environment — fish port of the export block in zsh/extra.zsh.

# Setup bat. The theme is installed into (bat --config-dir)/themes.
set -gx BAT_THEME "Catppuccin Mocha"

set -gx VISUAL nvim
set -gx EDITOR nvim
set -gx TERMINAL kitty

# Force Nerd Fonts for pi-powerline-footer extension
set -gx POWERLINE_NERD_FONTS 1

## use fd as default fzf command
set -gx FZF_DEFAULT_COMMAND "fd --hidden --strip-cwd-prefix --follow --exclude .git"
set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
set -gx FZF_ALT_C_COMMAND "fd --type=d --hidden --strip-cwd-prefix --follow --exclude .git"

## use bat as previewer
set -gx FZF_CTRL_T_OPTS "--preview 'bat --color=always --style=header,grid --line-range :500 {}'"
set -gx FZF_ALT_C_OPTS "--preview 'eza --icons --group-directories-first --git --color=always --tree --level=2 {}'"

## Set Catppuccin as the default theme
set -gx FZF_DEFAULT_OPTS "\
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

set -gx CARGO_HOME $HOME/.cargo
set -gx BUN_INSTALL $HOME/.bun

# ~/.local/bin and ~/.cargo/bin are already added by cachyos-config.fish.
# npm global installs go to a writable prefix (see ~/.npmrc).
fish_add_path $HOME/.npm-global/bin $BUN_INSTALL/bin

# LM Studio CLI (lms)
fish_add_path $HOME/.lmstudio/bin
