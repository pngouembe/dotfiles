{ config, pkgs, ... }:
{
  wayland.windowManager.hyprland.settings = {
    exec-once = with pkgs; [
      "${polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
      "nm-applet &"
      "waybar &"
    ];
  };

  home.file."${config.xdg.configHome}/hypr" = {
    source = ./config;
    recursive = true;
  };
}