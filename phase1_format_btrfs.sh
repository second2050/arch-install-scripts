#!/usr/bin/env bash
# second2050 arch install script - formatting script for btrfs

# variables
_oldwd=$(pwd)
_partition=$1

# check args
if [[ $_partition == "" ]]; then
	echo "ERROR: no partition given."
	echo "try: $0 /dev/nvme0n1p6"
	exit
elif [ -f "$_partition" ]; then
	echo "ERROR: device doesn't exist."
	exit
fi

# ask user if that is what they want
echo "THIS WILL FORMAT YOUR CHOSEN PARTITION"
echo "ARE YOU SURE YOU WANT THIS?"
echo ""
echo "MAKE SURE YOU USE A PARTITION AND NOT"
echo "THE DEVICE ITSELF!"
echo ""
echo "chosen partition: $_partition"
read -t 10 -p "[FORMAT/no]: " _doit
if [[ $_doit != "FORMAT" ]]; then
	echo "User aborted."
	exit
fi

# commence the great purge
echo "INFO: Formatting..."
mkfs.btrfs $_partition -f
if [[ $? != 0 ]]; then
	echo "ERROR: formatting failed"
	echo "is the device still mounted?"
	exit 1
fi

# mount and create subvolumes
echo "INFO: Creating subvolume layout..."
mount $_partition /mnt
cd /mnt
btrfs subvolume create @
btrfs subvolume set-default @
btrfs subvolume create @home
btrfs subvolume create @var

# setup subvolumes
mkdir ./@/home
mkdir ./@/var
mkdir -p ./@/mnt/btrfs-root

# remount
echo "INFO: Remounting to /mnt"
cd $_oldwd
umount /mnt
mount -o rw,relatime,subvol=@ $_partition /mnt
mount -o rw,relatime,compress=zstd,subvol=@home $_partition /mnt/home
mount -o rw,relatime,subvol=@var $_partition /mnt/var
mount -o rw,relatime,subvolid=5 $_partition /mnt/mnt/btrfs-root

# finish
echo "Script is finished!"
echo "INFO: don't forget to mount the esp."
