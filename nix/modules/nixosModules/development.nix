{ ... }:
{
  flake.nixosModules.development =
    { pkgs, ... }:
    {
      programs.nix-ld.enable = true;

      # fnm's zsh init. It lives here, not in the stow-linked zsh config, so it
      # stays scoped to NixOS hosts: that file is shared with the standalone
      # homeConfiguration (Ubuntu, other laptops), which has no fnm. Runs from
      # /etc/zshrc, before ~/.zshrc, so fnm's Node precedes the nixpkgs one.
      programs.zsh.interactiveShellInit = ''
        if command -v fnm >/dev/null 2>&1; then
          eval "$(fnm env --use-on-cd --shell zsh)"
        fi
      '';

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
        cmake
        curl.dev
        gnumake
        nodejs
        # Official-build Node, managed by fnm. Some npm packages ship native
        # addons that probe Node's compiled internals and fail to recognize the
        # nixpkgs build (e.g. @deepseek-ai/dsh's HMR loader). fnm fetches the
        # upstream binaries, which nix-ld above makes runnable.
        fnm
        claude-code
        lmstudio
        android-studio
        uv
        python3
        pipx
      ];
    };
}
