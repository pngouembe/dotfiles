# Managed by ~/dotfiles — stow links this to ~/.config/fish/config.fish.
#
# Load order matters: fish sources conf.d/*.fish *before* this file, so anything
# that has to win over CachyOS's defaults must be sourced from here, after
# cachyos-config.fish.
#
# NOTE: the caelestia installer rewrites ~/.config/fish/config.fish in place,
# which replaces the stow symlink and takes our aliases down with it. Its
# contents are folded in below, so after re-running that installer just restore
# the link:  rm ~/.config/fish/config.fish && cd ~/dotfiles && stow -R .

# CachyOS defaults: fastfetch greeting, bat man-pager, pacman helper aliases,
# !!/!$ bindings, and an eza-based ls family (partly overridden below).
if test -r /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

# Our layer, mirroring the zsh/ split. Sourced last so these definitions win.
for _file in env aliases git tools
    if test -r "$__fish_config_dir/$_file.fish"
        source "$__fish_config_dir/$_file.fish"
    end
end
set --erase _file

# CAELESTIA -------------------------------------------------------------------
# Carried over from the config.fish the caelestia installer writes. Its git
# abbreviations are dropped where they would shadow an alias from aliases.fish
# (ga, gc, gd, gl, gp, gb, gbd, gco, gst, and the l/ll/la/lla ls family, which
# cachyos-config.fish already covers); the additive ones are kept.
if status is-interactive
    abbr lg 'lazygit'
    abbr gs 'git status'
    abbr gsh 'git show'
    abbr gsw 'git switch'
    abbr gsm 'git switch main'
    abbr gpl 'git pull'
    abbr gsp 'git stash pop'

    # Terminal palette from the active caelestia scheme.
    cat ~/.local/state/caelestia/sequences.txt 2>/dev/null

    # OSC 133 prompt marks, so the terminal can jump between prompts.
    function mark_prompt_start --on-event fish_prompt
        echo -en "\e]133;A\e\\"
    end

    # Escape hatch the caelestia installer owns; sourced last of all.
    if set -q XDG_CONFIG_HOME
        set -l cConf $XDG_CONFIG_HOME/caelestia
        source $cConf/user-config.fish 2>/dev/null
    else
        source $HOME/.config/caelestia/user-config.fish 2>/dev/null
    end
end
