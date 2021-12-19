#!/usr/bin/env bash

# Define the dialog exit status codes
: "${DIALOG_OK=0}"
: "${DIALOG_CANCEL=1}"
: "${DIALOG_HELP=2}"
: "${DIALOG_EXTRA=3}"
: "${DIALOG_ITEM_HELP=4}"
: "${DIALOG_ESC=255}"

# setup stream redirection to get output from dialog in selections
exec 3>&1

# variables
_oldwd=$(pwd)
_device="/dev/$1"
_btrfsmountoptions="rw,noatime,discard=async"

# exit if device does not exist
if [ -f $_device ]; then 
    dialog --title "ERROR" --backtitle "$backtitle" --clear \
        --msgbox "Device does not exist!" 0 0
    exit 1
fi

dialog --title "Erase Disk?" --backtitle "$backtitle" --clear \
    --defaultno --yesno "Device: $(lsblk -do "MODEL,SIZE" "$_device")\n
Are you sure you want to ERASE this disk?\n
\n
THIS WILL REMOVE ALL CONTENTS OF THE DISK!" 0 0
case $? in
    $DIALOG_CANCEL)
        exit 1;;
    $DIALOG_ESC)
        exit 1;;
esac

dialog --infobox "\n  Formatting disk, please wait..." 5 39
(
# erasing and partitioning the drive
wipefs -af "$_device" 
sgdisk -Zo "$_device" 
sgdisk -n 0:0:+100M -t 0:ef00 -c 0:"EFI System Partition" "$_device" 
sgdisk -n 0:0:0 -t 0:8300 -c 0:"Arch Linux" "$_device" 

# formatting
mkfs.vfat "$_device"1 
mkfs.btrfs "$_device"2 

# mounting
umount -R /mnt
mount -o $_btrfsmountoptions,subvolid=5 "$_device"2 /mnt

# creating subvolumes
cd /mnt
btrfs subvolume create @
btrfs subvolume set-default @
btrfs subvolume create @home
btrfs subvolume create @var

# final mount
cd $_oldwd
umount -R /mnt
mount -o $_btrfsmountoptions,subvol=@ "$_device"2 /mnt
mkdir /mnt/{home,var,efi}
mount -o $_btrfsmountoptions,compress=zstd,subvol=@home "$_device"2 /mnt/home
mount -o $_btrfsmountoptions,subvol=@var "$_device"2 /mnt/var
mount "$_device"1 /mnt/efi
) &> /dev/null
