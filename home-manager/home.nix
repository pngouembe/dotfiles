{config, pkgs, ...}:
{
    home.username = "png";
    home.homeDirectory = "/home/png";

    programs.bat = {
      enable = true;
      config = {
        theme = "Catppuccin Mocha";
      };
      themes = {
        "Catppuccin Mocha" = {
            src = pkgs.fetchurl {
                url = "https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Mocha.tmTheme";
                hash = "sha256-UDJ6FlLzwjtLXgyar4Ld3w7x3/zbbBfYLttiNDe4FGY=";
            };
        };
      };
    };

    programs.fzf = {
        enable = true;
        defaultCommand = "fd --hidden --strip-cwd-prefix --follow --exclude .git";
        defaultOptions = [
            "--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8"
            "--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc"
            "--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
        ];
        changeDirWidgetCommand = "fd --type=d --hidden --strip-cwd-prefix --follow --exclude .git";
        changeDirWidgetOptions = ["--preview 'eza --icons --group-directories-first --git --color=always --tree --level=2 {}"];

        fileWidgetCommand = "fd --hidden --strip-cwd-prefix --follow --exclude .git";
        fileWidgetOptions = ["--preview 'bat --color=always --style=header,grid --line-range :500 {}"];
    };

    programs.kitty.enable = true;

    programs.neovim = {
        enable = true;
        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;
        defaultEditor = true;
        plugins = with pkgs.vimPlugins; [
            nvchad
            nvchad-ui
        ];
    };
    
    xdg.configFile."nvim" = {
        source = pkgs.fetchFromGitHub {
            owner = "nvchad";
            repo = "starter";
            rev = "0c7d9cefa99b01a6dadff495fd91ae52a15e756a";
            sha256 = "sha256-2ImwNH6vqp13lEjHhO4B5/bAVD0ZTnmwiFksDZSPAF8=";
        };
    };

    programs.starship = {
        enable = true;
    };

    programs.zoxide = {
        enable = true;
        options = [ "--cmd cd" ];
    };

    programs.zsh = {
        enable = true;
        autosuggestion.enable = true;
        oh-my-zsh.enable = true;

        # TODO: Find a way to make that cleaner
        initExtra = ''
            if [ -n "''${commands[fzf-share]}" ]; then
                source "$(fzf-share)/key-bindings.zsh"
                source "$(fzf-share)/completion.zsh"
            fi

            _fzf_comprun() {
                local command=$1
                shift

                case "$command" in
                    cd)             fzf --preview 'eza --icons --tree {} | head -200' "$@" ;;
                    export|unset)   fzf --preview "eval 'echo \$' {}" "$@" ;;
                    ssh)            fzf --preview 'dig {}' "$@" ;;
                    *)              fzf --preview "--preview 'bat -n --color=always --style=header,grid --line-range :500 {}" "$@" ;;
                esac
            }
        '';

        shellAliases = {
            "d" = "docker";
            "dc" = "docker-compose";

            "v" = "nvim";
            "vi" = "nvim";
            "vim" = "nvim";

            "l" = "eza -lah --group-directories-first --git --icons";
            "ls" = "eza --icons";
            "lst" = "eza --tree --level=2 --group-directories-first --git --icons";

            "c" = "clear";
            "s" = "source ~/.zshrc";

            "gc" = "git commit";
            "gco" = "git checkout";
            "ga" = "git add";
            "gb" = "git branch";
            "gba" = "git branch --all";
            "gbd" = "git branch -D";
            "gcp" = "git cherry-pick";
            "gd" = "git diff -w";
            "gds" = "git diff -w --staged";
            "grs" = "git restore --staged";
            "gst" = "git rev-parse --git-dir > /dev/null 2>&1 && git status || exa";
            "gu" = "git reset --soft HEAD~1";
            "gpr" = "git remote prune origin";
            "ff" = "gpr && git pull --ff-only";
            "grd" = "git fetch origin && git rebase origin/master";
            "gbf" = "git branch | head -1 | xargs' # top branch";
            "gl" = "git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
            "gla" = "gl";
            "git-current-branch" = "git branch | grep \* | cut -d ' ' -f2";
            "grc" = "git rebase --continue";
            "gra" = "git rebase --abort";
            "gcan" = "gc --amend --no-edit";

            "gp" = "git push";
            "gpf" = "git push --force-with-lease";

            "gg" = "git branch | fzf | xargs git checkout";
            "gup" = "git branch --set-upstream-to=origin/$(git-current-branch) $(git-current-branch)";
        };
    };


    xdg.configFile."starship.toml" = {
        source = "${config.home.homeDirectory}/dotfiles/starship/starship.toml";
    };

    nixpkgs.config.allowUnfree = true;

    home.packages = with pkgs; [
        bottles
        bottom
        brave
        cargo-binstall
        curl
        dig
        dust
        eza
        fd
        fira-code-nerdfont
        fzf
        gcc_multi
        git
        just
        ripgrep
        rustup
        steam
        tlrc
        unzip
        vscodium
        wget
        zellij
    ];

    fonts.fontconfig.enable = true;

    home.stateVersion = "24.05";
    programs.home-manager.enable = true;

}
