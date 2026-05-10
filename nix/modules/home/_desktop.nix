{
  pkgs,
  inputs,
  ...
}:

{
  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    name = "catppuccin-mocha-dark-cursors";
    package = pkgs.catppuccin-cursors.mochaDark;
    size = 24;
  };

  # `lms server start` reads ~/.lmstudio/.internal/app-install-location.json and
  # spawns the unwrapped Electron binary, which can't run outside the bwrap FHS
  # environment on NixOS. Start the wrapped `lm-studio` binary directly with
  # `--run-as-service` instead.
  systemd.user.services.lmstudio = {
    Unit.Description = "LM Studio headless API server";
    Service = {
      ExecStart = "${pkgs.lmstudio}/bin/lm-studio --run-as-service";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };

  home.packages = with pkgs; [
    # Terminal emulator
    alacritty

    # System monitor
    resources

    # Browsers
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default

    # Notes & sync
    obsidian
    syncthing

    # Fonts
    nerd-fonts.fira-code
  ];
}
