#!/bin/bash

sudo apt update
sudo apt upgrade -y

# Package manager installation
sudo apt install -y \
    curl \
    fzf \
    gettext \
    git \
    ninja-build \
    pip \
    python3 \
    python3-pip \
    unzip \
    software-properties-common \
    tmux \
    wget \
    zsh

# Python package install
pip install \
    cmake \
    rich

# Install rust
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"

## Install cargo binstall prebuilt package 
curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash

## Install cargo packages
cargo binstall \
    bat \
    exa \
    fd-find \
    ripgrep \
    bottom


# Install starship
curl -sS https://starship.rs/install.sh | sh -s -- -y

## Install the nerd font to make starship display correctly
mkdir -p $HOME/.local/share/fonts
wget -O $HOME/.local/share/fonts/FiraCode.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/FiraCode.zip 
unzip -o -d $HOME/.local/share/fonts/ $HOME/.local/share/fonts/FiraCode.zip
rm $HOME/.local/share/fonts/FiraCode.zip


# Install neovim from source
git clone https://github.com/neovim/neovim $HOME/neovim
cd $HOME/neovim
git checkout stable

make CMAKE_BUILD_TYPE=Release CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=$HOME/neovim"
make install
export PATH="$HOME/neovim/bin:$PATH"
cd -

# Install NvChad
git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1

# Install z
wget https://raw.githubusercontent.com/rupa/z/master/z.sh -O ~/.local/bin/z.sh

# Install alacritty
sudo add-apt-repository ppa:aslatter/ppa -y
sudo apt install -y alacritty

# Install zsh auto suggestion
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions

# Install tmux package manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
