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
        layout = "us";
        variant = "";
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

      programs.firefox.enable = true;

      environment.systemPackages = [
        pkgs.kitty
      ];
    };
}
