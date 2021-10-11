#!/usr/bin/env bash
# second2050 arch post-install script - swapfile setup for btrfs

# mount btrfs root
echo "INFO: Making sure that btrfs-root is mounted..."
mount /mnt/btrfs-root

# creating subvolume dedicated to the swapfile, add it to fstab and mount it
echo "INFO: Creating and mounting @swapfile subvolume..."
btrfs subvolume create /mnt/btrfs-root/@swapfile
_uuid=$(lsblk -no UUID $(df -P / | awk 'END{print $1}'))
{
    echo "# swapfile"
    echo "UUID=$_uuid /swapfile btrfs rw,noatime,subvol=@swapfile 0 0"
    echo "/swapfile/swapfile none swap defaults 0 0"
} >> /etc/fstab
mkdir /swapfile
mount /swapfile

# ask the user what the size should be and
echo "INFO: Creating swapfile..."
read -e -p "swapfile size? [MB]: " -i "8192" _size
if [[ $_size == "" ]]; then echo "User aborted."; exit; fi # abort if no size or 0 is given.
if [[ $_size == "0" ]]; then echo "User aborted."; exit; fi

# prepare swapfile
truncate -s 0 /swapfile/swapfile
chattr +C /swapfile/swapfile
btrfs property set /swapfile/swapfile compression none

# create the swapfile itself
dd if=/dev/zero of=/swapfile/swapfile bs=1M count=$_size status=progress

# make the swapfile only +rw for root
chmod 600 /swapfile/swapfile

# format the swap and activate
echo "INFO: Formatting swapfile..."
mkswap /swapfile/swapfile
echo "INFO: Enabling swapfile..."
swapon /swapfile/swapfile
