{ config, ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # needed for Steam and 32-bit games
  };

  hardware.nvidia = {
    modesetting.enable = true; # required for Wayland / Hyprland
    open = false; # proprietary driver; flip to true for Turing+ open kernel modules
    nvidiaSettings = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable; # 595.x on nixos-unstable
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia"; # VA-API hardware video decode
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct"; # pipewire/wayland direct VA-API path
  };
}
