#!/bin/bash

set -eou pipefail

clear

cat << EOF

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

if [[ $EUID != 0 ]]; then
  echo "This script must be run as root!"
  exit 1
fi

IS_JOSH=""
while [[ $IS_JOSH != "y" ]] && [[ $IS_JOSH != "n" ]];
do
  read -p "Are you Josh? [y/n]: " IS_JOSH </dev/tty
done

if [[ $IS_JOSH == "y" ]]; then
  IS_JOSH=""
  while [[ $IS_JOSH != "y" ]] && [[ $IS_JOSH != "n" ]];
  do
    read -p "Are you the Josh that wrote this script? [y/n]: " IS_JOSH </dev/tty
  done
fi

if [[ $IS_JOSH == "n" ]]; then
  cat << EOF
##############################

You have indicated that you are not Josh (well, not the right one anyway... there can only be one, you know).

In this case, the script will NOT attempt to restore the home directory with borgmatic.

##############################
EOF
else
  cat << EOF
##############################

You have indicated that you are Josh. If this is true, hello self.

If not, then you are a dirty liar, and the last part of this script will fail.

Try running it again without lying.

##############################
EOF
fi


# Get user input for desired username and password(s)
read -p "Enter desired username: " NEW_USER </dev/tty
read -sp "Enter password: " NEW_USER_PASSWORD </dev/tty
echo ""
read -sp "Confirm password: " PASSWORD_CONFIRMATION </dev/tty
echo ""

if [[ $NEW_USER_PASSWORD != $PASSWORD_CONFIRMATION ]]; then
  echo "Passwords do not match. Exiting... "
  exit 1
fi

if [[ $IS_JOSH == "y" ]]; then

  read -p "Enter TrueNAS server hostname/IP: " HOMESHARE_HOST </dev/tty

  read -sp "Enter homeshare password: " HOMESHARE_PASS </dev/tty
  echo ""
  read -sp "Confirm password: " HOMESHARE_PASS_CONFIRMATION </dev/tty
  echo ""

  if [[ $HOMESHARE_PASS != $HOMESHARE_PASS_CONFIRMATION ]]; then
    echo "Homeshare password not confirmed"
    exit 1
  fi

  read -sp "Enter borg repo passphrase: " BORG_REPO_PASS </dev/tty
  echo ""
  read -sp "Confirm borg repo passphrase : " BORG_REPO_PASS_CONFIRMATION </dev/tty
  echo ""

  if [[ $BORG_REPO_PASS != $BORG_REPO_PASS_CONFIRMATION ]]; then
    echo "Borg repo password not confirmed"
    exit 1
  fi
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
  if ! getent group sudo | grep -q "$NEW_USER"; then
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

if [[ $IS_JOSH == "y" ]]; then

  # Create SMB creds file
  touch /root/.smbcredentials
  chown root /root/.smbcredentials
  chmod 0600 /root/.smbcredentials 

  cat << EOF > /root/.smbcredentials
username=$NEW_USER
password=$HOMESHARE_PASS
domain=WORKGROUP
EOF

  # Add homeshare mount where borg repo is stored
  if ! grep -q "//$HOMESHARE_HOST/homeshare /home/$NEW_USER/homeshare" /etc/fstab; then
    cat << EOF >> /etc/fstab
# SMB mount for Homeshare on truenas-01
//$HOMESHARE_HOST/homeshare /home/$NEW_USER/homeshare cifs credentials=/root/.smbcredentials,uid=1000,gid=1000,file_mode=0755,dir_mode=0755 0 0
EOF
    mount -a
  fi

  # Create symlink for borgmatic config
  if [[ -d .borgmatic-etc ]]; then
    ln -s ~/.borgmatic-etc /etc/borgmatic
  fi

  # Download josh script (runs bormatic extract)
  curl -L -o /home/$NEW_USER/joshscript.sh https://raw.githubusercontent.com/joshrnoll/myarchy/refs/heads/main/joshscript.sh
  chmod +x /home/$NEW_USER/joshscript.sh
  chown $NEW_USER:$NEW_USER /home/$NEW_USER/joshscript.sh 

  # Run joshscript as new user (probably the user 'josh' but idk, maybe I got weird)
  runuser -u $NEW_USER /bin/bash /home/$NEW_USER/joshscript.sh "$BORG_REPO_PASS"
fi

# Enable ly display manager
if ! systemctl status ly@tty2.service; then
  echo "Enabling ly display manager on tty2..."
  systemctl stop getty@tty2.service
  systemctl disable getty@tty2.service
  systemctl enable ly@tty2.service
fi

echo "Installation complete! Rebooting..."

systemctl reboot
