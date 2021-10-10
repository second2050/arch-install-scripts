#!/usr/bin/env bash
# second2050 arch install script - base install script

# install arch base
echo "INFO: Installing arch base..."
pacstrap /mnt base base-devel vim man-db linux linux-headers linux-firmware $*

# generate fstab
echo "INFO: Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab

# finish
echo "Script is finished!"
echo "Phase 3 and beyond must be run in the arch chroot."
echo "\'arch-chroot /mnt\'"
