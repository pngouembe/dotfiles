{ ... }:
{
  flake.nixosModules.media = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.rawtherapee ];
  };
}
