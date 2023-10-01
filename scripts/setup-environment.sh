#!/bin/bash


# Set zsh as default shell
sudo chsh -s $(which zsh) $USER

# Install alacritty themes
mkdir -p ~/.config/alacritty/themes
git clone https://github.com/alacritty/alacritty-theme ~/.config/alacritty/themes
