{ pkgs, ... }:

{
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.hyprland.enableGnomeKeyring = true;


  environment.systemPackages = with pkgs; [
    gnome.seahorse
  ];
}
