{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin.url = "github:catppuccin/nix";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, catppuccin, ... } @ inputs:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
    in
    {
      nixosConfigurations.default = lib.nixosSystem {
        specialArgs = {
          inherit pkgs-unstable;
          inherit inputs;
        };
        modules = [
          ./hosts/default/configuration.nix
          ./modules/nixos/nvidia.nix
          ./modules/nixos/steam.nix
          ./modules/nixos/hyprland.nix
          ./modules/nixos/polkit.nix
          ./modules/nixos/keyring.nix
          catppuccin.nixosModules.catppuccin
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.users.png = {
              imports = [
                ./modules/home-manager
                catppuccin.homeManagerModules.catppuccin
              ];
            };
          }
        ];
      };
    };
}
