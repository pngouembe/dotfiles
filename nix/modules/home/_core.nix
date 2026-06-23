{ pkgs, lib, ... }:

{
  home.username = "png";
  home.homeDirectory = "/home/png";
  home.stateVersion = "25.11";

  # The nixpkgs `rustup` patchelf's each toolchain it downloads, hard-coding the
  # ELF interpreter to a specific nix-store glibc. A later glibc bump +
  # garbage-collect can remove that glibc, leaving cargo/rustc pointing at a
  # linker that no longer exists (surfaces as `cargo: No such file or
  # directory`). Re-running `rustup toolchain install` re-patches against the
  # current glibc. We only do it when stable is missing or broken, so healthy
  # rebuilds stay instant and offline. Also bootstraps rust on a fresh machine.
  home.activation.repairRustup = lib.hm.dag.entryAfter [ "installPackages" ] ''
    rustup="${pkgs.rustup}/bin/rustup"
    if ! "$rustup" run stable cargo --version >/dev/null 2>&1; then
      $DRY_RUN_CMD "$rustup" toolchain install stable || \
        echo "warning: 'rustup toolchain install stable' failed (offline?); run it manually once online."
    fi
  '';

  # HM owns ~/.zshrc so it can declare oh-my-zsh and plugins, then sources
  # ~/.config/zsh/extra.zsh (stow-linked) at the end for bits we still want
  # to iterate on without a rebuild.
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "docker"
        "docker-compose"
      ];
    };

    initContent = ''
      if [[ -r "$HOME/.config/zsh/extra.zsh" ]]; then
        source "$HOME/.config/zsh/extra.zsh"
      fi
    '';
  };

  home.packages = with pkgs; [
    # Shell + prompt (zsh, oh-my-zsh, zsh-autosuggestions are pulled in by
    # programs.zsh above)
    starship
    nix-your-shell

    # Fuzzy finder + smart cd
    fzf
    zoxide

    # Multiplexers
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
    yazi

    # Editors / dev
    neovim
    rustup
    opencode

    # Docker
    docker
    lazydocker
  ];
}
