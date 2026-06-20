{ ... }:
{
  flake.nixosModules.development =
    { pkgs, ... }:
    {
      programs.nix-ld.enable = true;

      virtualisation.docker.enable = true;
      # Make the `host.docker.internal:host-gateway` mapping resolve to the
      # docker0 bridge gateway so containers can reach services on the host.
      virtualisation.docker.daemon.settings.host-gateway-ip = "172.17.0.1";
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
