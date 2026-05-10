{ inputs, config, ... }:
{
  flake.nixosConfigurations.paul-desktop = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    system = "x86_64-linux";
    modules = [
      ./_machines/paul-desktop-hardware-config.nix
      config.flake.nixosModules.base
      config.flake.nixosModules.desktop
      config.flake.nixosModules.gaming
      config.flake.nixosModules.development
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit inputs; };
        home-manager.users.png = import ../nixosModules/home/_home.nix;
      }
    ];
  };
}
