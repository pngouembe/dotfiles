{ ... }:
{
  programs.fzf = {
    enable = true;
    defaultCommand = "fd --hidden --strip-cwd-prefix --follow --exclude .git";
    defaultOptions = [
      "--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8"
      "--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc"
      "--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
    ];
    changeDirWidgetCommand = "fd --type=d --hidden --strip-cwd-prefix --follow --exclude .git";
    changeDirWidgetOptions = [ "--preview 'eza --icons --group-directories-first --git --color=always --tree --level=2 {}" ];

    fileWidgetCommand = "fd --hidden --strip-cwd-prefix --follow --exclude .git";
    fileWidgetOptions = [ "--preview 'bat --color=always --style=header,grid --line-range :500 {}" ];
  };
}
