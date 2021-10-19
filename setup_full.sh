#!/usr/bin/env bash
# second2050 arch install script - FULL execution with TUI

# ensure dialog is installed
if [[ ! -f /bin/dialog ]]; then
    pacman -Sy dialog
fi

# Define the dialog exit status codes
: "${DIALOG_OK=0}"
: "${DIALOG_CANCEL=1}"
: "${DIALOG_HELP=2}"
: "${DIALOG_EXTRA=3}"
: "${DIALOG_ITEM_HELP=4}"
: "${DIALOG_ESC=255}"

# get output from selections in dialog
exec 3>&1

# helper functions
display_result() {
  dialog --title "$1" --backtitle "second2050's arch installer - $2"\
    --no-collapse \
    --msgbox "$result" 0 0
}

# Info section 
dialog --title "second2050's arch installer" --backtitle "second2050's arch installer" --clear \
    --msgbox "This Installer will guide you through the ArchLinux install process. It will also get you started with my personal defaults." 0 0

dialog --title "second2050's arch installer" --backtitle "second2050's arch installer" --clear \
    --msgbox "The setup consists of: \n
    1. Partitioning and formatting your drive \n
    2. Installing the base system via pacstrap \n
    3. Configurating your new install \n
    4. Installing a bootloader/-manager \n
    5. Installing a desktop environment" 0 0

dialog --title "second2050's arch installer" --backtitle "second2050's arch installer" --clear \
    --yesno "Are you sure you want to install ArchLinux now?" 0 0

if [[ $? != $DIALOG_OK ]]; then
    clear
    exit
fi

# Partitioning section
while true; do
    selection=$(dialog --title "Partitioning Menu" --backtitle "second2050's arch installer - Partitioning" --clear \
        --menu "" 0 0 4 \
        "1" "Display available devices and partitions" \
        "2" "Partition device with 'gdisk' (GPT)" \
        "3" "Partition device with 'fdisk' (MBR)" \
        "0" "Finish partitioning" 2>&1 1>&3)
    case $? in
    $DIALOG_CANCEL)
      clear
      echo "Program terminated."
      exit
      ;;
    $DIALOG_ESC)
      clear
      echo "Program aborted." >&2
      exit 1
      ;;
    esac
    case $selection in
        1 )
            result=$(lsblk -o NAME,MODEL,FSTYPE,SIZE)
            display_result "Current Partitions and Devices" "Partitioning"
            ;;
        2 )
            drivepath=$(dialog --title "Enter drive path - gdisk" --backtitle "second2050's arch installer - Partitioning" --clear \
                --no-collapse --inputbox "$(lsblk -do PATH,MODEL,SIZE)" 0 0 "/dev/" 2>&1 1>&3)
            case $? in
                $DIALOG_CANCEL)
                ;&
                $DIALOG_ESC)
                ;;
                $DIALOG_OK)
                gdisk "$drivepath"
                ;;
            esac
            ;;
        3 )
            drivepath=$(dialog --title "Enter drive path - fdisk" --backtitle "second2050's arch installer - Partitioning" --clear \
                --no-collapse --inputbox "$(lsblk -do PATH,MODEL,SIZE)" 0 0 "/dev/" 2>&1 1>&3)
            case $? in
                $DIALOG_CANCEL)
                ;&
                $DIALOG_ESC)
                ;;
                $DIALOG_OK)
                fdisk "$drivepath"
                ;;
            esac
            ;;
        0 )
            break;;
    esac
done

# Formatting menu
while true; do
    selection=$(dialog --title "Formatting Menu" --backtitle "second2050's arch installer - Formatting" --clear \
        --menu "" 0 0 6 \
        "1" "Display available devices and partitions" \
        "2" "Format root as btrfs" \
        "3" "Format ESP" \
        "4" "Mount ESP" \
        "5" "Manual formatting/mounting (drops to shell)" \
        "0" "Finish formatting and mounting" 2>&1 1>&3)
    case $? in
    $DIALOG_CANCEL)
      clear
      echo "Program terminated."
      exit
      ;;
    $DIALOG_ESC)
      clear
      echo "Program aborted." >&2
      exit 1
      ;;
    esac
    case $selection in
        1 )
            result=$(lsblk -o NAME,MODEL,FSTYPE,SIZE)
            display_result "Current Partitions and Devices" "Formatting"
            ;;
        2 )
            rootpath=$(dialog --title "Format root as btrfs - Enter drive path" --backtitle "second2050's arch installer - Formatting" --clear \
                --no-collapse --inputbox "$(lsblk -o NAME,MODEL,FSTYPE,SIZE)" 0 0 "/dev/" 2>&1 1>&3)
            case $? in
                $DIALOG_CANCEL)
                ;&
                $DIALOG_ESC)
                ;;
                $DIALOG_OK)
                clear
                bash ./phase1_format_btrfs.sh "$rootpath"
                ;;
            esac
            ;;
        3 )
            #bash ./phase1_format_esp.sh
            result="Not yet implemented"
            display_result "Format ESP" "Formatting"
            ;;
        4 )
            esppath=$(dialog --title "Enter drive path - Mount ESP" --backtitle "second2050's arch installer - Formatting" --clear \
                --no-collapse --inputbox "$(lsblk -o NAME,MODEL,FSTYPE,SIZE)" 0 0 "/dev/" 2>&1 1>&3)
            case $? in
                $DIALOG_CANCEL)
                ;&
                $DIALOG_ESC)
                ;;
                $DIALOG_OK)
                mkdir -p /mnt/efi
                mount $esppath /mnt/efi
                ;;
            esac
            ;;
        5 )
            clear
            echo "type 'exit' to go back to the setup."
            zsh
            ;;
        0 )
            break;;
    esac
done

# Installing the base system with pacstrap
basepkgs="base base-devel vim man-db linux-firmware networkmanager iwd sudo fish"
fontpkgs="noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra ttf-cascadia-code"
scriptpkgs="dialog"

# choose kernel
selection=$(dialog --title "Choose kernel package" --backtitle "second2050's arch installer - Packages" --clear \
    --radiolist "Press 'space' to select then press 'enter' to confirm." 0 0 3 \
    "1" "Vanilla" on \
    "2" "Zen Kernel" off \
    "3" "LTS Kernel" off 2>&1 1>&3)
case $? in
    $DIALOG_CANCEL)
        clear
        echo "Program terminated."
        exit
        ;;
    $DIALOG_ESC)
        clear
        echo "Program aborted." >&2
        exit 1
        ;;
esac
case $selection in
    1 )
        kernelpkgs="linux linux-headers"
        ;;
    2 ) 
        kernelpkgs="linux-zen linux-zen-headers"
        ;;
    3 )
        kernelpkgs="linux-lts linux-lts-headers"
        ;;
esac

# choose video drivers
selection=$(dialog --title "Choose video driver" --backtitle "second2050's arch installer - Packages" --clear \
    --radiolist "Press 'space' to select then press 'enter' to confirm." 0 0 7 \
    "1" "None" on \
    "2" "AMD (GCN 3 and higher)" off \
    "3" "ATI (GCN 2 and lower)" off \
    "4" "Intel" off \
    "5" "NVIDIA (Nouveau)" off \
    "6" "NVIDIA (Proprietary)" off 2>&1 1>&3)
case $? in
    $DIALOG_CANCEL)
        clear
        echo "Program terminated."
        exit
        ;;
    $DIALOG_ESC)
        clear
        echo "Program aborted." >&2
        exit 1
        ;;
esac
case $selection in
    1 )
        videopkgs=""
        ;;
    2 )
        videopkgs="xf86-video-amdgpu mesa"
        ;;
    3 )
        videopkgs="xf86-video-ati mesa"
        ;;
    4 )
        videopkgs="xf86-video-intel mesa"
        ;;
    5 )
        videopkgs="xf86-video-nouveau mesa"
        ;;
    6 )
        videopkgs="nvidia-dkms nvidia-utils"
        ;;
esac

# actually install packages
pacstrap /mnt $basepkgs $kernelpkgs $fontpkgs $scriptpkgs $videopkgs | dialog --title "Installing..." --backtitle "second2050's arch installer - Installation" --progressbox -1 -1
_pacstrapexit=${PIPESTATUS[0]}
if [[ $_pacstrapexit != 0 ]]; then
    result="'pacstrap' exited with $_pacstrapexit \nSetup will be aborted..."
    display_result "ERROR" "Installing"
    exit $_pacstrapexit
fi

# remove /etc/resolv.conf in new root because I can't seem to symlink systemd-resolved's stub correctly otherwise...
rm /mnt/etc/resolv.conf

# switching to arch-chroot to continue with the setup
mkdir -p /mnt/root/arch_install_scripts
cp -r . /mnt/root/arch_install_scripts
arch-chroot /mnt /root/arch_install_scripts/setup_full_chroot.sh

# when chroot is finished greet user
if [[ $? != 0 ]]; then
    dialog --title "second2050's arch installer" --backtitle "second2050's arch installer" --clear \
        --msgbox "Something went wrong, the base system was installed but the second part of the script exited without finishing." 0 0
else
    dialog --title "second2050's arch installer" --backtitle "second2050's arch installer" --clear \
        --msgbox "The Setup is finished and you should have a working ArchLinux install now." 0 0
fi
