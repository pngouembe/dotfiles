{ inputs, ... }:
let
  system = "x86_64-linux";
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };
in
{
  # Standalone home-manager configuration for non-NixOS hosts (Ubuntu in
  # Docker, other Linux laptops). Pairs with `stow .` from this repo to wire
  # up the user-level configs.
  #
  # Apply with:
  #   nix run home-manager/master -- switch --flake .#png
  flake.homeConfigurations.png = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    extraSpecialArgs = { inherit inputs; };
    modules = [
      ../home/_core.nix
    ];
  };
}
