#!/bin/bash

set -e

export COSMARCHY_ONLINE_INSTALL=true

ansi_art='
   ____   ___   ____  __  __     _    ____    ____  _   _ __   __
  / ___| / _ \ / ___||  \/  |   / \  |  _ \  / ___|| | | |\ \ / /
 | |    | | | |\___ \| |\/| |  / _ \ | |_) || |    | |_| | \ V / 
 | |___ | |_| | ___) | |  | | / ___ \|  _ < | |___ |  _  |  | |  
  \____| \___/ |____/|_|  |_|/_/   \_\|_| \_\ \____||_| |_|  |_|  
                                  GNOME Meets Arch Linux
'

clear
echo -e "\e[36m$ansi_art\e[0m\n"

# Use custom branch/repo if instructed
COSMARCHY_REF="${COSMARCHY_REF:-main}"
COSMARCHY_REPO="${COSMARCHY_REPO:-hteariH/Gnomarchy}"

echo -e "Installing base prerequisites..."
sudo pacman -Syu --noconfirm --needed git curl base-devel

echo -e "\nCloning Cosmarchy from: https://github.com/${COSMARCHY_REPO}.git"
echo -e "\e[32mUsing branch: $COSMARCHY_REF\e[0m"
rm -rf ~/.local/share/cosmarchy/
git clone --branch "$COSMARCHY_REF" "https://github.com/${COSMARCHY_REPO}.git" ~/.local/share/cosmarchy >/dev/null

echo -e "\nStarting Cosmarchy installation..."
source ~/.local/share/cosmarchy/install.sh
