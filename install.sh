#!/bin/bash

set -eou pipefail

clear

cat << 'EOF'

  ███╗   ███╗██╗   ██╗ █████╗ ██████╗  ██████╗██╗  ██╗██╗   ██╗
  ████╗ ████║╚██╗ ██╔╝██╔══██╗██╔══██╗██╔════╝██║  ██║╚██╗ ██╔╝
  ██╔████╔██║ ╚████╔╝ ███████║██████╔╝██║     ███████║ ╚████╔╝
  ██║╚██╔╝██║  ╚██╔╝  ██╔══██║██╔══██╗██║     ██╔══██║  ╚██╔╝
  ██║ ╚═╝ ██║   ██║   ██║  ██║██║  ██║╚██████╗██║  ██║   ██║
  ╚═╝     ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝

  Like Omarchy, but it's mine.

  ═══════════════════════════════════════════════════════════════

  ⚠️  NOTICE

  This script will create a user with passwordless sudo privileges.
  Part of this script will be ran as this user.

  ═══════════════════════════════════════════════════════════════

EOF

if [ $USER != "root" ]; then
  echo "This script must be run as root!"
  exit 1
fi

# Get user input for desired username and password
read -p "Enter desired username: " NEW_USER </dev/tty
read -sp "Enter password: " NEW_USER_PASSWORD </dev/tty
echo ""
read -sp "Confirm password: " PASSWORD_CONFIRMATION </dev/tty
echo ""

if [ $NEW_USER_PASSWORD != $PASSWORD_CONFIRMATION ]; then
  echo "Passwords do not match. Exiting... "
  exit 1
fi

# Update pacman and install necessary packages to run the rest of the script
pacman -Syu --noconfirm
pacman -Rdd --noconfirm iptables || true # Remove conflicting iptables package, skipping dependency checks
pacman -S --noconfirm iptables-nft # Install iptables-nft to avoid conflicts when installing packages.txt
pacman -S --needed --noconfirm git base-devel sudo # Install necessary base packages to run the rest of the script

# Create sudo group if it doesn't exist
if ! getent group sudo &> /dev/null; then
  echo "No sudo group found. Creating..."
  groupadd sudo 
fi

# Add sudo privileges to sudo group if it's not already configured
if ! grep -q "%sudo ALL=(ALL:ALL) ALL" /etc/sudoers; then
  echo "Adding sudo group to sudoers file..."
  echo "%sudo ALL=(ALL:ALL) ALL" >> /etc/sudoers
fi

# Create desired user account if it doesn't exist
if ! id -u $NEW_USER; then
  echo "User $NEW_USER does not exist. Creating..."
  useradd -m -G sudo $NEW_USER
  echo "$NEW_USER:$NEW_USER_PASSWORD" | chpasswd
  echo "$NEW_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
else
  # Add the user to the sudo group if they aren't already a member
  # and configure passwordless sudo if not already configured
  if ! getent group sudo | grep "$NEW_USER"; then
    echo "User is not in the sudo group. Adding..."
    usermod -aG sudo $NEW_USER
  fi 

  if ! grep -q "$NEW_USER ALL=(ALL) NOPASSWD:ALL" /etc/sudoers; then
    echo "User does not have passwordless sudo privileges. Adding..."
    echo "$NEW_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
  fi
fi

# Download userscript
curl -L -o /home/$NEW_USER/userscript.sh https://raw.githubusercontent.com/joshrnoll/myarchy/refs/heads/main/userscript.sh
chmod +x /home/$NEW_USER/userscript.sh
chown $NEW_USER:$NEW_USER /home/$NEW_USER/userscript.sh 

# Run userscript as new user
runuser -u $NEW_USER /bin/bash /home/$NEW_USER/userscript.sh

# Enable ly display manager
if ! systemctl status ly@tty2.service; then
  echo "Enabling ly display manager on tty2..."
  systemctl disable getty@tty2.service
  systemctl enable ly@tty2.service
fi

echo "Installation complete! Rebooting..."

systemctl reboot
