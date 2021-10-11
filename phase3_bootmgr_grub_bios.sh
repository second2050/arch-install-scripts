#!/usr/bin/env bash
# second2050 arch install script - grub install script for legacy systems

# install package
echo "INFO: Installing grub..."
pacman -S --noconfirm grub

# install grub to disk with root partition
_device=$(lsblk -no PKNAME $(df -P / | awk 'END{print $1}'))
echo "INFO: Installing grub to device: /dev/$_device..."
grub-install --target=i386-pc /dev/$_device

# generate grub config
echo "INFO: Generating grub config..."
grub-mkconfig -o /boot/grub/grub.cfg

# finish
echo "Script is finished!"
