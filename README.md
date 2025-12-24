# MyArchy

Personal Arch Linux system setup and configuration automation.

It's like [Omarchy](https://omarchy.org/), but just for me.

## What It Does

Automates a complete Arch Linux installation with:

- Hyprland desktop environment with waybar, wofi, and swaync
- Development tools (git, go, npm, docker, neovim, claude-code)
- Virtualization stack (qemu, libvirt, virt-manager, vagrant)
- All Nerd Fonts
- Personal dotfiles from [joshrnoll/dotfiles](https://github.com/joshrnoll/dotfiles) via chezmoi

## Prerequisites

**IMPORTANT**: Configure passwordless sudo before running:

```bash
echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$USER
```

## Installation

```bash
./install.sh
```

The script is idempotent and can be re-run safely.

## Package Management

Edit `packages.txt` to add/remove packages (one per line), then re-run the install script.

## Development Environments

**Vagrant VM**:

```bash
vagrant up && vagrant ssh
```

**Dev Container**:
Open in VS Code with Remote Containers extension.

## What Gets Configured

- yay AUR helper
- ly display manager (enabled on tty2)
- goose CLI tool
- All packages from `packages.txt`
- Dotfiles applied via chezmoi
