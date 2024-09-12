set shell := ["bash", "-uc"]

# List all the available recipes
default:
  @just --list --justfile {{justfile()}}

alias a := install-all
alias all := install-all

# Installs the complete setup
install-all: install-my-zsh install-cli-tools install-dev-tools


# =================Utils=======================

# Backs up a file (renames it with the .bak extention)
_backup-file file_path:
  @rm -rf {{file_path}}.bak
  @if {{path_exists(file_path)}}; then echo "Backing up {{file_path}}"; mv {{file_path}} {{file_path}}.bak; fi

# Creates the .config directory
_config-directory:
  @echo "Creating the .config directory"
  @mkdir -p ~/.config

@install-nerd-fonts:
  @echo "Installing nerd fonts"
  @mkdir -p $HOME/.local/share/fonts
  wget -q -O $HOME/.local/share/fonts/FiraCode.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/FiraCode.zip
  unzip -qq -o -d $HOME/.local/share/fonts/ $HOME/.local/share/fonts/FiraCode.zip
  rm $HOME/.local/share/fonts/FiraCode.zip


# =================ZSH=======================

# Installs my complete zsh setup
install-my-zsh: install-zsh install-zsh-config install-zsh-aliases install-zsh-arch-linux-config

# Installs zsh and sets it as the default shell
install-zsh:
  @echo "Installing zsh"
  # sudo apt install -qq -y zsh

  @echo "Setting zsh as the default shell"
  chsh -s $(which zsh)

# Installs zsh configuration
install-zsh-config: install-zsh install-oh-my-zsh install-starship install-just-completions install-zsh-autosuggestions install-zsh-syntax-highlighting install-zsh-256color
  @echo "Installing zsh configuration"
  @just _backup-file ~/.zshrc
  ln -s {{justfile_directory()}}/zsh/rc.zsh ~/.zshrc

# Installs zsh config for arch linux
install-zsh-arch-linux-config: _zsh-directory
  @just _backup-file ~/.zsh/arch-linux.zsh
  ln -s {{justfile_directory()}}/zsh/arch-linux.zsh ~/.zsh/arch-linux.zsh

# Installs zsh aliases
install-zsh-aliases: _zsh-directory
  @echo "Installing zsh aliases"
  @just _backup-file ~/.zsh/aliases.zsh
  ln -s {{justfile_directory()}}/zsh/aliases.zsh ~/.zsh/aliases.zsh

# Installs oh-my-zsh
install-oh-my-zsh:
  @echo "Installing oh-my-zsh"
  @just _backup-file ~/.oh-my-zsh
  curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh -s -- --skip-chsh --keep-zshrc

# Installs the just completions
install-just-completions: _oh-my-zsh-completion-directory
  @echo "Installing just completions for zsh"
  just --completions zsh > ~/.oh-my-zsh/completions/_just

# Installs zsh autosuggestions
install-zsh-autosuggestions: _oh-my-zsh-plugins-directory
  @echo "Installing zsh autosuggestions"
  @just _backup-file ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions

# Installs zsh syntax highlighting
install-zsh-syntax-highlighting: _oh-my-zsh-plugins-directory
  @echo "Installing zsh syntax highlighting"
  @just _backup-file ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

# Installs zsh 256 color
install-zsh-256color: _oh-my-zsh-plugins-directory
  @echo "Installing zsh 256 color"
  @just _backup-file ~/.oh-my-zsh/custom/plugins/zsh-256color
  git clone https://github.com/chrissicool/zsh-256color ~/.oh-my-zsh/custom/plugins/zsh-256color

# Creates the .zsh directory
_zsh-directory:
  @echo "Creating the .zsh directory"
  @mkdir -p ~/.zsh

# Creates the .oh-my-zsh directory
_oh-my-zsh-directory:
  @echo "Creating the .oh-my-zsh directory"
  @mkdir -p ~/.oh-my-zsh

# Creates the .oh-my-zsh/completions directory
_oh-my-zsh-completion-directory: _oh-my-zsh-directory
  @echo "Creating the .oh-my-zsh/completions directory"
  @mkdir -p ~/.oh-my-zsh/completions

# Creates the .oh-my-zsh/custom/plugins directory
_oh-my-zsh-plugins-directory: _oh-my-zsh-directory
  @echo "Creating the .oh-my-zsh/plugins directory"
  @mkdir -p ~/.oh-my-zsh/custom/plugins


# =================CLI Tools=======================

# Installs all my CLI tools
install-cli-tools: install-bat install-bottom install-dust install-eza install-fd install-fzf install-fzf-git install-ripgrep install-starship install-tlrc install-zoxide

# Installs bat
install-bat: install-wget
  @echo "Installing bat"
  cargo binstall -y bat
  mkdir -p "$(bat --config-dir)/themes"
  wget -P "$(bat --config-dir)/themes" https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Mocha.tmTheme
  bat cache --build


# Installs bottom
install-bottom:
  @echo "Installing bottom"
  cargo binstall -y bottom

# Installs dust
install-dust:
  @echo "Installing dust"
  cargo binstall -y du-dust

# Installs eza
install-eza:
  @echo "Installing eza"
  cargo binstall -y eza

# Installs fd
install-fd:
  @echo "Installing fd"
  cargo binstall -y fd-find

# Installs fzf
install-fzf: install-git
  @echo "Installing fzf"
  @just _backup-file ~/.fzf
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install --no-bash --no-fish --no-update-rc --key-bindings --completion

install-fzf-git: install-git
  @echo "Installing fzf"
  @just _backup-file ~/.fzf-git
  git clone --depth 1 https://github.com/junegunn/fzf-git.sh.git ~/.fzf-git

# Installs ripgrep
install-ripgrep:
  @echo "Installing ripgrep"
  cargo binstall -y ripgrep

# Installs starship command prompt
install-starship: _config-directory install-nerd-fonts
  @echo "Installing starship"
  cargo binstall -y starship

  @echo "Installing starship configuration"
  @just _backup-file ~/.config/starship.toml
  ln -s {{justfile_directory()}}/starship/starship.toml ~/.config/starship.toml

# Installs tlrc
install-tlrc:
  @echo "Installing tlrc"
  cargo binstall -y tlrc

# Installs wget
install-wget:
  @echo "Installing wget"
  # sudo apt install -qq -y wget

# Installs zoxide
install-zoxide: install-fzf
  @echo "Installing zoxide"
  cargo binstall -y zoxide

# =================Dev Tools=======================

# Installs all my dev tools
install-dev-tools: install-my-neovim install-zellij

# Installs my neovim setup
install-my-neovim: install-neovim install-neovim-config

# Installs neovim
install-neovim: install-cmake install-gettext install-git
  @echo "Installing neovim"
  @just _backup-file ~/neovim
  git clone https://github.com/neovim/neovim ~/neovim
  cd ~/neovim && \
  git checkout stable && \
  make CMAKE_BUILD_TYPE=Release CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=~/neovim" && \
  make install


NVIM_CONFIG_DST := "~/.config/nvim/lua/"
NVIM_CONFIG_SRC := join(justfile_directory(), "nvim")
# Installs neovim configuration
install-neovim-config:
  @echo "Installing neovim configuration"
  @just _backup-file ~/.config/nvim
  @just _backup-file ~/.local/share/nvim 
  git clone https://github.com/NvChad/starter ~/.config/nvim


  @just _link-in-nvchad-config "chadrc.lua"
  @just _link-in-nvchad-config "configs/lspconfig.lua"
  @just _link-in-nvchad-config "plugins/init.lua"

_link-in-nvchad-config path:
  @echo "Linking {{join(NVIM_CONFIG_SRC,path)}} to {{join(NVIM_CONFIG_DST,path)}}"
  rm -rf {{join(NVIM_CONFIG_DST, path)}} 
  ln -s {{join(NVIM_CONFIG_SRC, path)}} {{join(NVIM_CONFIG_DST, path)}}

_nvchad-custom-directory:
  @echo "Creating the nvchad custom directory"
  @mkdir -p ~/.config/nvim/lua/custom

# Installs cmake
install-cmake:
  @echo "Installing cmake"
  # sudo apt install -qq -y cmake

# Installs gettext
install-gettext:
  @echo "Installing gettext"
  # sudo apt install -qq -y gettext

# Installs git
install-git:
  @echo "Installing git"
  # sudo apt install -qq -y git

# Installs zellij
install-zellij:
  @echo "Installing zellij"
  cargo binstall -y zellij

  @just _backup-file ~/.config/zellij
  @just _zellij-directory
  ln -s {{justfile_directory()}}/zellij/config.kdl ~/.config/zellij/config.kdl


_zellij-directory:
  @echo "Creating the zellij config directory"
  @mkdir -p ~/.config/zellij
