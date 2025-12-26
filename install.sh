#!/bin/bash

set -eoux pipefail

# Display MyArchy logo
echo ""
echo "  ███╗   ███╗██╗   ██╗ █████╗ ██████╗  ██████╗██╗  ██╗██╗   ██╗"
echo "  ████╗ ████║╚██╗ ██╔╝██╔══██╗██╔══██╗██╔════╝██║  ██║╚██╗ ██╔╝"
echo "  ██╔████╔██║ ╚████╔╝ ███████║██████╔╝██║     ███████║ ╚████╔╝ "
echo "  ██║╚██╔╝██║  ╚██╔╝  ██╔══██║██╔══██╗██║     ██╔══██║  ╚██╔╝  "
echo "  ██║ ╚═╝ ██║   ██║   ██║  ██║██║  ██║╚██████╗██║  ██║   ██║   "
echo "  ╚═╝     ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   "
echo ""
echo "Like Omarchy, but it's mine."
echo ""

if [ $USER != "root" ]; then
  echo "This script must be run as root"
  exit 1
fi

# Get user input for desired username and password
NEW_USER=$(read -p "Enter desired username: ")
NEW_USER_PASSWORD=$(read -sp "Enter password: ")
PASSWORD_CONFIRMATION=$(read -sp "Confirm password: ")

if [ $NEW_USER_PASSWORD != $PASSWORD_CONFIRMATION ]; then
  echo "Passwords do not match. Exiting... "
  exit 1
fi

# Change to root user home dir and download packages.txt
cd $HOME
curl -L -O https://raw.githubusercontent.com/joshrnoll/myarchy/refs/heads/main/packages.txt

# Update pacman and install necessary packages to run the rest of the script
pacman -Syu --noconfirm
pacman -Rdd --noconfirm iptables || true # Remove conflicting iptables package, skipping dependency checks
pacman -S --noconfirm iptables-nft # Install iptables-nft to avoid conflicts when installing packages.txt
pacman -S --needed --noconfirm git base-devel sudo # Install necessary base packages to run the rest of the script

# Create desired user account with passwordless sudo privileges
useradd -m -p $NEW_USER_PASSWORD -G sudo $NEW_USER
echo "$NEW_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers

# Ensure ~/.local/bin is in PATH
export PATH="$HOME/.local/bin:$PATH"

# Install yay (AUR helper) from source if not present
if ! command -v yay &> /dev/null; then
  if [[ -d yay ]]; then
    rm -rf yay/
  fi
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
  cd $HOME
else
  echo "Yay already installed... YAY!"
fi

# Install goose CLI tool from GitHub
if ! command -v goose &> /dev/null; then
  curl -fsSL https://github.com/block/goose/releases/download/stable/download_cli.sh | CONFIGURE=false bash
else
  echo "Goose is already installed... HONK!"
fi

# Install all packages from packages.txt
if [ -f "$HOME/packages.txt" ]; then
  yay -S --needed --noconfirm $(cat $HOME/packages.txt)
else
  echo "No packages.txt found! Exiting..."
  exit 1
fi

# Enable ly display manager on tty2 and disable default getty
if systemctl status ly@tty2.service; then # TODO: Find a better way to check if ly exists
  systemctl enable ly@tty2.service
  systemctl disable getty@tty2.service
fi

# Initialize and apply dotfiles using chezmoi
if [ ! -d "$HOME/.local/share/chezmoi" ]; then
  sudo -u $NEW_USER chezmoi init https://github.com/joshrnoll/dotfiles.git
  sudo -u $NEW_USER chezmoi apply
else
  echo "Chezmoi not installed. Skipping dotfile installation..."
fi

echo "Installation complete! Rebooting..."

systemctl reboot
