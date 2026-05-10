{ inputs, ... }:
{
  systems = [ "x86_64-linux" ];

  perSystem =
    { pkgs, system, ... }:
    let
      hyprlandPkg = inputs.hyprland.packages.${system}.hyprland;
      noctaliaPkg = inputs.noctalia.packages.${system}.default;
      quickshellPkg = inputs.noctalia.inputs.noctalia-qs.packages.${system}.quickshell;

      hyprlandWrapped = inputs.wrappers.wrapperModules.hyprland.apply (
        { lib, ... }: {
          inherit pkgs;
          package = lib.mkForce hyprlandPkg;

          # Drop the wrapper's default `--config <path>` so Hyprland falls back
          # to ~/.config/hypr/hyprland.conf (provided by the dotfiles repo via
          # stow). The wrapper still bundles env vars and extraPackages.
          flags."--config" = lib.mkForce false;

          env = {
            NIXOS_OZONE_WL = "1";
            NOCTALIA_CACHE_DIR = "/tmp/noctalia-cache";
          };

          extraPackages = [
            noctaliaPkg
            quickshellPkg
            pkgs.hyprpolkitagent
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
