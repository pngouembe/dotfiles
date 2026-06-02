{ ... }:
{
  flake.nixosModules.development =
    { pkgs, ... }:
    {
      programs.nix-ld.enable = true;

      virtualisation.docker.enable = true;
      users.users.png.extraGroups = [ "docker" ];

      environment.systemPackages = with pkgs; [
        git
        nixfmt
        nil
        nixd
        zed-editor
        gcc
        nodejs
        claude-code
        lmstudio
        android-studio
        uv
      ];
    };
}
