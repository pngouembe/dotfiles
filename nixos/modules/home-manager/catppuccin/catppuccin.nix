{ ... }:
{
  catppuccin = {
    enable = true;
    pointerCursor.enable = true;
  };

  gtk.catppuccin = {
    enable = true;
    icon.enable = true;
  };

  programs.kitty.catppuccin.enable = true;

  programs.rofi.catppuccin.enable = true;

  wayland.windowManager.hyprland.catppuccin.enable = true;
}
