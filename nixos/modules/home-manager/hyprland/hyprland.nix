{ pkgs, ... }:
{
  wayland.windowManager.hyprland.settings = {
    exec-once = with pkgs; [
      "${polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
      "nm-applet &"
      "waybar &"
    ];
  };

  xdg.configFile."hypr" = {
    source = ./config;
  };
}