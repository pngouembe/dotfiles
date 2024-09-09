{
  pkgs,
  ...
}: {
  home.packages = with pkgs; [glib]; # gsettings
  xdg.systemDirs.data = let
    schema = pkgs.gsettings-desktop-schemas;
  in ["${schema}/share/gsettings-schemas/${schema.name}"];

  gtk = {
    enable = true;
    font = {
      name = "FiraCode Nerd Font";
      size = 10;
    };
    gtk3.extraConfig = {
      gtk-xft-antialias = 1;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintslight";
      gtk-xft-rgba = "rgb";
    };
    gtk2.extraConfig = ''
      gtk-xft-antialias=1
      gtk-xft-hinting=1
      gtk-xft-hintstyle="hintslight"
      gtk-xft-rgba="rgb"
    '';
  };

  # cursor theme
  # home.file.".icons/default".source = "${pkgs.catppuccin-cursors.mochaPink}/share/icons/Catppuccin-Mocha-Pink-Cursors";
}
