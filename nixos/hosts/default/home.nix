{ config, pkgs, pkgs-unstable, ... }:
{
  home.username = "png";
  home.homeDirectory = "/home/png";

  wayland.windowManager.hyprland.settings = {
    exec-once = with pkgs; [
      "${polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
      "nm-applet &"
      "waybar &"
    ];
  };

  nixpkgs.config.allowUnfree = true;

  home.packages = [
    pkgs.bottles
    pkgs.bottom
    pkgs.brave
    pkgs.cargo-binstall
    pkgs.curl
    pkgs.dig
    pkgs.dust
    pkgs.eza
    pkgs.fd
    pkgs.fira-code-nerdfont
    pkgs.fzf
    pkgs.gcc_multi
    pkgs.git
    pkgs.just
    pkgs.nixpkgs-fmt
    pkgs.pipewire
    pkgs.polkit
    pkgs.ripgrep
    pkgs.rustup
    pkgs.swaynotificationcenter
    pkgs.tlrc
    pkgs.unzip
    pkgs.waybar
    pkgs.wget
    pkgs.zellij

    pkgs-unstable.vscodium
  ];

  fonts.fontconfig.enable = true;

  home.stateVersion = "24.05";
  programs.home-manager.enable = true;

}
