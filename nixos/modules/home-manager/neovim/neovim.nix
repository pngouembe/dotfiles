{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    defaultEditor = true;
    plugins = with pkgs.vimPlugins; [
      nvchad
      nvchad-ui
    ];
  };

  xdg.configFile."nvim" = {
    source = pkgs.fetchFromGitHub {
      owner = "nvchad";
      repo = "starter";
      rev = "0c7d9cefa99b01a6dadff495fd91ae52a15e756a";
      sha256 = "sha256-2ImwNH6vqp13lEjHhO4B5/bAVD0ZTnmwiFksDZSPAF8=";
    };
  };
}