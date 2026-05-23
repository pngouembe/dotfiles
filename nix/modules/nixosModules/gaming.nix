{ ... }:
{
  flake.nixosModules.gaming = { pkgs, ... }: {
    programs.steam = {
      enable = true;
      extraCompatPackages = [ pkgs.proton-ge-bin ];
    };

    programs.gamescope.enable = true;
    programs.gamemode.enable = true;

    environment.systemPackages = [ pkgs.heroic ];
  };
}
