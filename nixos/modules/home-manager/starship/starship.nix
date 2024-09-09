{ lib, ... }:
{
  programs.starship = {
    enable = true;
  };

  xdg = lib.mkForce {
    enable = true;
    configFile."starship.toml" = {
      source = ./config/starship.toml;
    };
  };
}
