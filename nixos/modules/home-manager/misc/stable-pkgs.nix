{ pkgs, ... }:
{
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
    fontconfig
    gcc_multi
    git
    just
    nixpkgs-fmt
    pipewire
    polkit
    ripgrep
    rustup
    swaynotificationcenter
    tlrc
    unzip
    waybar
    wget
    zellij
  ];
}

