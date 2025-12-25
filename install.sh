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

# Update pacman and remove conflicting iptables package
sudo pacman -Syu --noconfirm
sudo pacman -R --noconfirm iptables || true

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
if [ -f "packages.txt" ]; then
  yay -S --needed --noconfirm $(cat packages.txt)
else
  echo "No packages.txt found! Exiting..."
  exit 1
fi

# Enable ly display manager on tty2 and disable default getty
if systemctl status ly@tty2.service; then # TODO: Find a better way to check if ly exists
  sudo systemctl enable ly@tty2.service
  sudo systemctl disable getty@tty2.service
fi

# Initialize and apply dotfiles using chezmoi
if [ ! -d "$HOME/.local/share/chezmoi" ]; then
  chezmoi init https://github.com/joshrnoll/dotfiles.git
  chezmoi apply
else
  echo "Chezmoi not installed. Skipping dotfile installation..."
fi

echo "Installation complete! Rebooting..."

sudo systemctl reboot
