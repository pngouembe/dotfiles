{ ... }:
{
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

      "l" = "eza -lah --group-directories-first --git --icons=auto";
      "ls" = "eza --icons=auto";
      "lst" = "eza --tree --level=2 --group-directories-first --git --icons=auto";

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
}
