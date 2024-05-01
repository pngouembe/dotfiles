#! /bin/bash

set -e

sudo apt update && sudo apt install -y build-essential curl git wget unzip

# Install cargo
echo "Installing rust"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

echo "Installing cargo binstall"
$HOME/.cargo/bin/cargo install cargo-binstall

echo "Installing just"
$HOME/.cargo/bin/cargo binstall -y just

exec $SHELL
