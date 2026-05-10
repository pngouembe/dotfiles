{ ... }:
{
  flake.nixosModules.base = { pkgs, ... }: {
    home-manager.backupFileExtension = "bak";

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.kernelPackages = pkgs.linuxPackages_latest;

    swapDevices = [
      {
        device = "/swapfile";
        size = 16 * 1024;
      }
    ];

    networking.hostName = "nixos";
    networking.networkmanager.enable = true;

    time.timeZone = "Europe/Paris";

    i18n.defaultLocale = "en_US.UTF-8";

    i18n.extraLocaleSettings = {
      LC_ADDRESS = "fr_FR.UTF-8";
      LC_IDENTIFICATION = "fr_FR.UTF-8";
      LC_MEASUREMENT = "fr_FR.UTF-8";
      LC_MONETARY = "fr_FR.UTF-8";
      LC_NAME = "fr_FR.UTF-8";
      LC_NUMERIC = "fr_FR.UTF-8";
      LC_PAPER = "fr_FR.UTF-8";
      LC_TELEPHONE = "fr_FR.UTF-8";
      LC_TIME = "fr_FR.UTF-8";
    };

    programs.zsh.enable = true;

    users.users.png = {
      isNormalUser = true;
      description = "Paul Ngouembe";
      shell = pkgs.zsh;
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
    };

    nixpkgs.config.allowUnfree = true;

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    system.stateVersion = "25.11";
  };
}
