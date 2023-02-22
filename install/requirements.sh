#!/bin/bash

install_package_if_needed() {
  COMMAND="$1"
  PACKAGE_NAME="$1"
  if [ -z "$2" ]; then
    PACKAGE_NAME="$2"
  fi

  if ! type $COMMAND > /dev/null; then 
    echo ''
    echo "Installing $PACKAGE_NAME"
    echo ''
    apt-get install -y $PACKAGE_NAME 
    echo ''
    echo "Done installing $PACKAGE_NAME"
    echo ''
  fi
}

apt-get update

install_package_if_needed zsh 
install_package_if_needed exa 
install_package_if_needed python3
install_package_if_needed pip  python3-pip


wget https://raw.githubusercontent.com/rupa/z/master/z.sh -O ~/.local/bin/z.sh
