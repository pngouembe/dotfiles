{ ... }:
{
  programs.kitty = {
    enable = true;
    catppuccin.enable = true;
  };

  xdg.configFile.kitty.source = ./config;
}