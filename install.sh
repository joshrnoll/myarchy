#!/bin/bash

set -eoux pipefail

# Update pacman and remove conflicting iptables package
sudo pacman -Syu --noconfirm
sudo pacman -R --noconfirm iptables || true

# Install yay (AUR helper) from source if not present
if ! command -v yay &> /dev/null; then
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ~
fi

# Install goose CLI tool from GitHub
if ! command -v goose &> /dev/null; then
    mkdir -p ~/.local/bin
    curl -fsSL https://raw.githubusercontent.com/pressly/goose/master/install.sh | sh -s -- -b ~/.local/bin
fi

# Ensure ~/.local/bin is in PATH
export PATH="$HOME/.local/bin:$PATH"

# Install all packages from packages.txt
if [ -f "packages.txt" ]; then
    yay -S --needed --noconfirm $(cat packages.txt)
fi

# Enable ly display manager on tty2 and disable default getty
sudo systemctl enable ly.service
sudo systemctl disable getty@tty2.service

# Initialize and apply dotfiles using chezmoi
if [ ! -d "$HOME/.local/share/chezmoi" ]; then
    chezmoi init https://github.com/joshrnoll/dotfiles.git
fi
chezmoi apply

echo "Installation complete!"
