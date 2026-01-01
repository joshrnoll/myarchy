#!/bin/bash

# Download list of packages
cd $HOME
curl -L -O https://raw.githubusercontent.com/joshrnoll/myarchy/refs/heads/main/packages.txt

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

# Install homebrew
if ! command -v brew &> /dev/null; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "Homebrew is already installed... 🍺"
fi

# Install all packages from packages.txt
if [ -f "$HOME/packages.txt" ]; then
  yay -S --needed --noconfirm $(cat $HOME/packages.txt)
else
  echo "No packages.txt found! Exiting..."
  exit 1
fi

# Initialize and apply dotfiles using chezmoi
if command -v chezmoi &> /dev/null; then
  if [ ! -d "$HOME/.local/share/chezmoi" ]; then
    chezmoi init https://github.com/joshrnoll/dotfiles.git
    chezmoi apply
  fi
else
  echo "Chezmoi not installed. Skipping dotfile installation..."
fi
