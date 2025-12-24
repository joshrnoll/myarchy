FROM docker.io/archlinux:latest

RUN pacman -Syu --noconfirm
RUN pacman -S git sudo --noconfirm

# Create user 'josh' with home directory
RUN useradd -m -s /bin/bash josh

# Grant passwordless sudo permissions to josh
RUN echo "josh ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
