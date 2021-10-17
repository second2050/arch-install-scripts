#!/usr/bin/env bash
# second2050 arch install script - base install script

# variables
_basepkgs="base base-devel vim man-db linux-firmware networkmanager iwd sudo fish"
_kernelpkgs="linux linux-headers"
_fontpkgs="noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra ttf-cascadia-code"

# install arch base
echo "INFO: Installing arch base..."
pacstrap /mnt $_basepkgs $_kernelpkgs $_fontpkgs $*
_pacstrapexit=$?
if [[ $_pacstrapexit != 0 ]]; then
    echo "ERROR: pacstrap exitcode: $_pacstrapexit"
    exit $_pacstrapexit
fi

# remove /etc/resolv.conf in new root because I can't seem to symlink systemd-resolved's stub correctly otherwise...
rm /mnt/etc/resolv.conf

# generate fstab
echo "INFO: Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab

# finish
echo "Script is finished!"
echo "Phase 3 and beyond must be run in the arch chroot."
echo "\'arch-chroot /mnt\'"
