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

# helper functions
format_root() {
    unset options
    while read -r device name; do # read all HDDs and SSDs into a list
        options+=("$device" "$name")
    done < <(lsblk -nlo NAME,LABEL,FSTYPE,SIZE $_device | tail -n +2)
    _partition=$(dialog --title "Choose Partition" --backtitle "$backtitle" --menu "Select the partition which should be root:" 0 0 0 "${options[@]}" 2>&1 1>&3)

    dialog --title "Erase Partition?" --backtitle "$backtitle" --clear \
    --defaultno --yesno "Device: $(lsblk -lo NAME,LABEL,FSTYPE,SIZE "$_partition")\n
Are you sure you want to ERASE this partition?\n
\n
THIS WILL REMOVE ALL CONTENTS OF THE PARTITION!" 0 0
case $? in
    $DIALOG_CANCEL)
        return 1;;
    $DIALOG_ESC)
        return 1;;
esac
(
mkfs.btrfs -f /dev/"$_partition"

# mounting
umount -R /mnt
mount -o $_btrfsmountoptions,subvolid=5 /dev/"$_partition" /mnt

# creating subvolumes
cd /mnt
btrfs subvolume create @
btrfs subvolume set-default @
btrfs subvolume create @home
btrfs subvolume create @var

# final mount
cd $_oldwd
umount -R /mnt
mount -o $_btrfsmountoptions,subvol=@ /dev/"$_partition" /mnt
mkdir /mnt/{home,var,efi}
mount -o $_btrfsmountoptions,compress=zstd,subvol=@home /dev/"$_partition" /mnt/home
mount -o $_btrfsmountoptions,subvol=@var /dev/"$_partition" /mnt/var
) &> /dev/null
}

format_esp() {
    unset options
    while read -r device name; do # read all HDDs and SSDs into a list
        options+=("$device" "$name")
    done < <(lsblk -nlo NAME,LABEL,FSTYPE,SIZE $_device | tail -n +2)
    _partition=$(dialog --title "Choose Partition" --backtitle "$backtitle" --menu "Select the partition which should be your new ESP:" 0 0 0 "${options[@]}" 2>&1 1>&3)

    dialog --title "Erase Partition?" --backtitle "$backtitle" --clear \
    --defaultno --yesno "Device: $(lsblk -lo NAME,LABEL,FSTYPE,SIZE "$_partition")\n
Are you sure you want to ERASE this partition?\n
\n
THIS WILL REMOVE ALL CONTENTS OF THE PARTITION!" 0 0
case $? in
    $DIALOG_CANCEL)
        return 1;;
    $DIALOG_ESC)
        return 1;;
esac

mkfs.vfat /dev/"$_partition"
mount /dev/"$_partition" /mnt/efi
}

mount_esp() {
    unset options
    while read -r device name; do # read all HDDs and SSDs into a list
        options+=("$device" "$name")
    done < <(lsblk -nlo NAME,LABEL,FSTYPE,SIZE $_device | tail -n +2)
    _partition=$(dialog --title "Choose Partition" --backtitle "$backtitle" --menu "Select the partition which should be your new ESP:" 0 0 0 "${options[@]}" 2>&1 1>&3)
    mount /dev/"$_partition" /mnt/efi
}

while true; do
    selection=$(dialog --title "Disk Partition Guide" --backtitle "$backtitle" --clear \
        --menu "Target Device: $(lsblk -do NAME,MODEL,SIZE $_device | grep -E "sd|vd|nvme")" 0 0 0 \
        "1" "Partition the drive" \
        "2" "Format+mount root partition" \
        "3a" "Format+mount EFI system partition" \
        "3b" "Mount existing EFI system partition" 2>&1 1>&3)
        "0" "Finish paritioning"
    case $? in
        $DIALOG_CANCEL)
            display_abortion;;
        $DIALOG_ESC)
            display_abortion;;
    esac
    case $selection in
        1)
            gdisk $_device;;
        2)
            format_root;;
        3a) 
            format_esp;;
        3b)
            mount_esp;;
        0)
            break;;
    esac
done