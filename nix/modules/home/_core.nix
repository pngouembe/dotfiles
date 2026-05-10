{ pkgs, ... }:

{
  home.username = "png";
  home.homeDirectory = "/home/png";
  home.stateVersion = "25.11";

  # HM owns ~/.zshrc so it can declare oh-my-zsh and plugins, then sources
  # ~/.config/zsh/extra.zsh (stow-linked) at the end for bits we still want
  # to iterate on without a rebuild.
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

    # Editors / dev
    neovim
    rustup
    opencode

    # Docker
    docker
    lazydocker
  ];
}
