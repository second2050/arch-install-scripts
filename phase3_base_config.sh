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
locale-gen

# set keyboard layout for vconsole
echo "INFO: Setting keyboard layout for vconsole..."
read -e -p "keyboard layout?: " -i "de-latin1" _keymap
echo "KEYMAP=$_keymap" >> /etc/vconsole.conf

# set hostname
echo "INFO: Setting hostname..."
read -e -p "hostname?: " -i "second2050" _hostname
echo $_hostname > /etc/hostname
{ 
    echo "127.0.0.1    localhost"
    echo "::1          localhost"
    echo "127.0.1.1    $_hostname"
} >> /etc/hosts

# setup network
echo "INFO: Setting up Network..."
systemctl enable NetworkManager
systemctl enable iwd
systemctl enable systemd-resolved
ln -sf /run/systemd/resolve/stub-resolv.conf/etc/resolv.conf
# write NetworkManager config
mkdir -p /etc/NetworkManager/conf.d
cat <<EOF > /etc/NetworkManager/conf.d/wifi_backend.conf
[device]
wifi.backend=iwd
EOF
cat <<EOF > /etc/NetworkManager/conf.d/mdns.conf
[connection]
connection.mdns=2 # enable mdns resolution and registering/broadcasting
EOF
# write resolved config
cat <<EOF >> /etc/systemd/resolved.conf

# second2050's resolved conf
DNS=1.1.1.1
FallbackDNS=1.0.0.1 9.9.9.9 9.9.9.10 8.8.8.8 2606:4700:4700::1111 2620:fe::10 2001:4860:4860::8888
DNSSEC=yes
DNSOverTLS=yes
MulticastDNS=yes
Cache=yes
EOF

# recreate initramfs
echo "INFO: Recreating initramfs..."
mkinitcpio -P

# set root pw
echo "INFO: Setting root password..."
echo "Enter the root password."
passwd

# create user account
echo "INFO: Creating user account..."
read -e -p "username?: " -i "second2050" _username
useradd -m -G wheel -s /bin/bash $_username
echo "Enter $_username's password."
passwd $_username

# setup sudo
mkdir -p /etc/sudoers.d
cat <<EOF >> /etc/sudoers.d/second2050
# second2050's defaults
%wheel ALL=(ALL) ALL
Defaults pwfeedback
EOF

# finish
echo "Script is finished!"
echo "INFO: Don't forget to install a bootloader/-manager."
