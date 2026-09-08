{
  pkgs,
  inputs,
  ...
}:

{
  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    x11.enable = true;
    name = "catppuccin-mocha-dark-cursors";
    package = pkgs.catppuccin-cursors.mochaDark;
    size = 24;
  };

  # NixOS's programs.hyprland ships no session target, and Hyprland (launched
  # straight from GDM, without uwsm) never activates graphical-session.target on
  # its own. xdg-desktop-portal has `Requisite=graphical-session.target`, so it
  # refuses to start, and GTK4/libadwaita apps -- which read color-scheme from
  # the portal on Wayland, not from GSettings -- fall back to light Adwaita.
  # BindsTo pulls graphical-session.target up as a dependency, which is the only
  # way to start it (the unit is RefuseManualStart=yes). Started from
  # hypr/hyprland.lua's autostart block.
  systemd.user.targets.hyprland-session = {
    Unit = {
      Description = "hyprland compositor session";
      BindsTo = [ "graphical-session.target" ];
      Wants = [ "graphical-session-pre.target" ];
      After = [ "graphical-session-pre.target" ];
    };
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
    google-chrome

    # Notes & sync
    obsidian
    syncthing
    spotify

    # Windows apps (Wine prefix manager)
    bottles

    # Fonts
    nerd-fonts.fira-code
  ];
}
