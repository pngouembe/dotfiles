#!/bin/bash


# Set zsh as default shell
chsh -s $(which zsh)

# Install alacritty themes
mkdir -p ~/.config/alacritty/themes
git clone https://github.com/alacritty/alacritty-theme ~/.config/alacritty/themes