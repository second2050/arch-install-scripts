#!/usr/bin/env bash
# second2050 arch install script - base config script

# set timezone
echo "INFO: Setting Timezone..."
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc

# set locale
echo "INFO: Setting locale"
sed -i '133s/.//' /etc/locale.gen # de_DE.UTF-8 UTF-8 # this uncomments the 133rd line
sed -i '160s/.//' /etc/locale.gen # en_GB.UTF-8 UTF-8
sed -i '177s/.//' /etc/locale.gen # en_US.UTF-8 UTF-8
{ 
    echo "LANG=en_US.UTF-8"
    echo "LC_CTYPE=en_US.UTF-8"
    echo "LC_NUMERIC=de_DE.UTF-8"
    echo "LC_TIME=en_GB.UTF-8"
    echo "LC_COLLATE=en_US.UTF-8"
    echo "LC_MONETARY=de_DE.UTF-8"
    echo "LC_MESSAGES=en_US.UTF-8"
    echo "LC_PAPER=de_DE.UTF-8"
    echo "LC_NAME=de_DE.UTF-8"
    echo "LC_ADDRESS=de_DE.UTF-8"
    echo "LC_TELEPHONE=de_DE.UTF-8"
    echo "LC_MEASUREMENT=de_DE.UTF-8"
    echo "LC_IDENTIFICATION=de_DE.UTF-8"
} > /etc/locale.conf

# set keyboard layout for vconsole
echo "INFO: Setting keyboard layout for vconsole..."
echo "KEYMAP=de-latin1" >> /etc/vconsole.conf

# set hostname
echo "INFO: Setting hostname..."
read -p "hostname? [second2050]: " _hostname
_hostname=${parameter:-second2050}
echo $_hostname > /etc/hostname
{ 
    echo "127.0.0.1    localhost"
    echo "::1          localhost"
    echo "127.0.1.1    $_hostname"
} >> /etc/hosts

# recreate initramfs
echo "INFO: Recreating initramfs..."
mkinitcpio -P

# set root pw
echo "INFO: Setting root password..."
echo "Enter the root password."
passwd

# create user account
echo "INFO: Creating user account..."
read -p "username? [second2050]: " _username
_username=${parameter:-second2050}
useradd -m -G wheel -s /bin/bash $_username

# finish
echo "Script is finished!"
echo "INFO: Don't forget to install a bootloader/-manager."
