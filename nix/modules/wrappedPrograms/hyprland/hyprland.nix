{ inputs, ... }:
{
  systems = [ "x86_64-linux" ];

  perSystem =
    { pkgs, system, ... }:
    let
      hyprlandPkg = inputs.hyprland.packages.${system}.hyprland;
      noctaliaPkg = inputs.noctalia.packages.${system}.default;

      hyprlandWrapped = inputs.wrappers.wrapperModules.hyprland.apply (
        { lib, ... }: {
          inherit pkgs;
          package = lib.mkForce hyprlandPkg;

          # Drop the wrapper's default `--config <path>` so Hyprland uses its
          # own lookup and loads ~/.config/hypr/hyprland.lua (provided by the
          # dotfiles repo via stow). Note that since 0.56 there is no fallback
          # to hyprland.conf: if the .lua file is absent Hyprland reports
          # "No config file found" and generates a default over the top.
          # The wrapper still bundles env vars and extraPackages.
          flags."--config" = lib.mkForce false;

          env = {
            NIXOS_OZONE_WL = "1";
            NOCTALIA_CACHE_DIR = "/tmp/noctalia-cache";
          };

          extraPackages = [
            noctaliaPkg
            # Polkit authentication is handled by noctalia's own agent
            # (shell.polkit_agent), so no separate agent is bundled here.
            pkgs.satty # screenshot annotation editor piped from noctalia
          ];
        }
      );
    in
    {
      packages.hyprland = hyprlandWrapped.wrapper;
      packages.hyprland-portal = inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland;

      apps.hyprland = {
        type = "app";
        program = "${hyprlandWrapped.wrapper}/bin/Hyprland";
      };
    };
}
