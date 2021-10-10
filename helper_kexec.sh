#!/usr/bin/env bash
# second2050 arch install script - Kexec helper script
# this is meant sepcifically to allow installing refind
# via the refind-install command without having to deal
# with the archiso stuff

if [[ $1 == "" ]]; then
	echo "ERROR: no kernel name given"
	echo "try: $0 linux"
	exit
fi

# variables
_kernel=$1
_uuid=$(lsblk -no UUID $(df -P /mnt | awk 'END{print $1}'))

# install kexec-tools
pacman -S --noconfirm kexec-tools

# loading kernel
kexec -l /mnt/boot/vmlinuz-$_kernel --initrd=/mnt/boot/initramfs-$_kernel.img --command-line="root=UUID=$_uuid loglevel=3 rd.udev.log_priority=3"

# jmp archlinux
systemctl kexec
