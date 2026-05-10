{
  pkgs,
  inputs,
  ...
}:

{
  home.username = "png";
  home.homeDirectory = "/home/png";
  home.stateVersion = "25.11";

  # Most program configuration lives in ~/dotfiles and is symlinked in by stow,
  # not by Nix. zsh is the exception: HM owns ~/.zshrc so it can declare
  # oh-my-zsh and plugins, then sources ~/.zsh/extra.zsh (stow-linked) at the
  # end for bits we still want to iterate on without a rebuild.
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "docker" "docker-compose" ];
    };

    initContent = ''
      if [[ -r "$HOME/.config/zsh/extra.zsh" ]]; then
        source "$HOME/.config/zsh/extra.zsh"
      fi
    '';
  };

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
    # Shell + prompt (zsh, oh-my-zsh, zsh-autosuggestions are pulled in by
    # programs.zsh above)
    starship
    nix-your-shell

    # Fuzzy finder + smart cd
    fzf
    zoxide

    # Terminal emulators & multiplexers
    alacritty
    tmux
    zellij

    # Modern CLI tools
    bat
    bottom
    dust
    eza
    fd
    jq
    ripgrep
    stow
    tlrc
    just

    # Editors / dev
    neovim
    rustup
    opencode

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
