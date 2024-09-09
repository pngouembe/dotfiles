{
  home.username = "png";
  home.homeDirectory = "/home/png";

  home.stateVersion = "24.05";
  programs.home-manager.enable = true;

  imports = [
    ./bat
    ./catppuccin
    ./fzf
    ./gtk
    ./hyprland
    ./kitty
    ./misc
    ./neovim
    ./starship
    ./waybar
    ./yazi
    ./zoxide
    ./zsh
  ];
}