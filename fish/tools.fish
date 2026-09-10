# Interactive shell integrations — fish port of the eval blocks in zsh/extra.zsh.
#
# Not ported: fzf's _fzf_compgen_*/_fzf_comprun hooks (zsh completion API; the
# FZF_*_OPTS previews in env.fish still apply), fzf-git.sh (bash/zsh only), and
# nix-your-shell (Nix-only, and this host has no Nix).

if status is-interactive
    # Initialise the starship prompt
    if type -q starship
        starship init fish | source
    end

    # Initialise zoxide
    if type -q zoxide
        zoxide init fish --cmd cd | source
    end

    # Hook direnv into the prompt
    if type -q direnv
        direnv hook fish | source
    end

    # Set up fzf key bindings and fuzzy completion
    if type -q fzf
        fzf --fish | source
    end
end
