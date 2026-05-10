{ ... }:
{
  flake.nixosModules.development = { pkgs, ... }: {
    programs.nix-ld.enable = true;

    environment.systemPackages = with pkgs; [
      git
      nixfmt
      nil
      nixd
      zed-editor
      gcc
      claude-code
      lmstudio
    ];
  };
}
