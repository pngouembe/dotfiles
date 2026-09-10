{ self, ... }:
{
  flake.nixosModules.desktop =
    { pkgs, ... }:
    {
      programs.hyprland = {
        enable = true;
        package = self.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
        portalPackage = self.packages.${pkgs.stdenv.hostPlatform.system}.hyprland-portal;
      };

      services.xserver.enable = true;
      services.displayManager.gdm.enable = true;
      services.desktopManager.gnome.enable = true;

      services.xserver.xkb = {
        layout = "us,us";
        variant = ",intl";
        options = "grp:alt_shift_toggle";
      };

      services.printing.enable = true;

      services.pulseaudio.enable = false;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };

      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
        settings = {
          General = {
            Privacy = "device";
            JustWorksRepairing = "always";
            Class = "0x000100";
            FastConnectable = "true";
          };
        };
      };

      boot.extraModprobeConfig = ''
        options bluetooth disable_ertm=1
      '';
      services.upower.enable = true;
      services.power-profiles-daemon.enable = true;

      # Location provider for gammastep's night light, which is started from
      # hypr/hyprland.lua's autostart block. Without it gammastep has no way to
      # work out sunset and refuses to start.
      services.geoclue2.enable = true;

      programs.firefox.enable = true;
    };
}
