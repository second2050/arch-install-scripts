#!/usr/bin/env bash
# second2050 arch install script - refind install script

# install refind
echo "INFO: Installing refind..."
pacman -S --noconfirm refind

# install refind to the esp
refind-install

# setup up a working refind_linux.conf
echo "INFO: Create good refind_linux.conf"
_uuid=$(lsblk -no UUID $(df -P / | awk 'END{print $1}'))
{
    echo "\"Boot with standard options\"   \"root=UUID=$_uuid rw initrd=boot\initramfs-%v.img loglevel=3 rd.udev.log_priority=3\""
    echo "\"Boot with fallback initramfs\" \"root=UUID=$_uuid rw initrd=boot\initramfs-%v-fallback.img loglevel=3 rd.udev.log_priority=3\""
    echo "\"Boot to terminal\"             \"root=UUID=$_uuid rw initrd=boot\initramfs-%v.img loglevel=3 rd.udev.log_priority=3 systemd.unit=multi-user.target\""
} > /boot/refind_linux.conf

# finish
echo "Script is finished!"