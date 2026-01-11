![MyArchy](./myarchy.png)

My personal Arch Linux configuration automation.

It's like [Omarchy](https://omarchy.org/), but just for me.

## And you can use it too!

MyArchy serves two purposes:

1. Automation for me, a chronic hardware-hopper who wants a consistent environment across all my machines.

2. A jumping-off point for your Arch linux journey. It's like NeoVim's [kickstart](https://github.com/nvim-lua/kickstart.nvim), but for a Hyprland-based Arch linux setup.

## What It Does

Automates a complete Arch Linux desktop setup with:

- Hyprland desktop environment with waybar, wofi, and swaync
- Development tools (git, go, npm, docker, neovim)
- AI tooling (claude-code, goose)
- Virtualization stack (qemu, libvirt, virt-manager, vagrant)
- All Nerd Fonts
- Personal dotfiles from [joshrnoll/dotfiles](https://github.com/joshrnoll/dotfiles) via chezmoi

## What Gets Configured

- yay AUR helper
- ly display manager (enabled on tty2)
- [goose](https://block.github.io/goose/docs/quickstart/) CLI tool
- All packages from `packages.txt`
- Dotfiles applied via chezmoi

## Prerequisites

To use MyArchy, you'll need a minimal arch installation with a root login. You can install it manually (the fun way), or you can use the [archinstall](https://wiki.archlinux.org/title/Archinstall) script. _The script will create your user account with passwordless sudo for you_.

## Installation

Log in as root and run:

```bash
curl -fsSL https://myarchy.joshrnoll.com | bash
```

Provide your desired username and password, which will be created by the script if it doesn't exist, and you're off to the races.

> [!NOTE]
> The script is designed to be idempotent so that it can be re-run safely.
> If something fails in the middle of the script, don't be afraid to run it again.

## Development Environments

**Vagrant VM**:

```bash
vagrant up && vagrant ssh
```

> [!NOTE]
> The vagrant VM has been giving me troubles. It's meant to use the `libvirt` provider,
> but I haven't gotten it to work properly on my machines, so I've just been using a manually created VM.

**Dev Container**:
Run `devpod up .` from the project directory.

> [!NOTE]
> The dev container does not have access to systemd or wayland and is therefore limited to testing basic script functionality.
