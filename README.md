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

A minimal arch install with root login. _The script will create your user account with passwordless sudo for you_.

## Installation

Log in as root and run:

```bash
curl https://raw.githubusercontent.com/joshrnoll/myarchy/refs/heads/main/install.sh | bash
```

The script is designed to be idempotent so that it can be re-run safely.

## Package Management

Edit `packages.txt` to add/remove packages (one per line), then re-run the install script.

## Development Environments

**Vagrant VM**:

```bash
vagrant up && vagrant ssh
```

**Dev Container**:
Run `devpod up .` from the project directory.

> [!NOTE]
> The dev container does not have access to systemd or wayland and is therefore limited to testing basic script functionality.

## What Gets Configured

- yay AUR helper
- ly display manager (enabled on tty2)
- goose CLI tool
- All packages from `packages.txt`
- Dotfiles applied via chezmoi
