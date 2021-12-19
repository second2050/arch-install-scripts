#!/usr/bin/env bash
# second2050 arch install script - FULL execution with TUI

# ensure dialog is installed
if [[ ! -f /bin/dialog ]]; then
    pacman -Sy dialog ncurses bash
fi

# Define the dialog exit status codes
: "${DIALOG_OK=0}"
: "${DIALOG_CANCEL=1}"
: "${DIALOG_HELP=2}"
: "${DIALOG_EXTRA=3}"
: "${DIALOG_ITEM_HELP=4}"
: "${DIALOG_ESC=255}"

# setup stream redirection to get output from dialog in selections
exec 3>&1

# helper functions
display_msg() {
    dialog --title "$1" --backtitle "second2050's arch installer"\
        --no-collapse \
        --msgbox "$2" 0 0
}
display_abortion() {
    while true; do
        dialog --title "Abort Installation?" --backtitle "second2050's arch installer"\
            --defaultno --yesno "Aborting the setup can leave your system in an inconsistent state!" 0 0
        case $? in
            $DIALOG_OK)
                clear
                echo "Setup Aborted!" >&2
                exit 1
                ;;
            $DIALOG_CANCEL)
                return
        esac
    done
}

# variables for user config
user_timezone=""
user_locale=""
user_keymap=""
user_hostname=""
user_username=""
user_password=""
system_kernel=""
system_gpu=""

# variables used for this script
export backtitle="second2050's arch installer"
basepkgs="base base-devel vim man-db linux-firmware networkmanager iwd sudo fish btrfs-progs"
fontpkgs="noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra ttf-cascadia-code"
scriptpkgs="dialog"
desktopenvpkgs="plasma-meta sddm kde-applications plasma-wayland-session"
bootloaderpkgs="refind"

# BEGINNING of the script
dialog --title "second2050's arch installer" --backtitle "$backtitle" --clear \
    --msgbox "The setup consists of:\n
    1. Choosing your HDD/SSD + partition & formating it.\n
    2. Configurating your new system\n
    3. Installing the packages" 0 0

dialog --title "second2050's arch installer" --backtitle "$backtitle" --clear \
    --yesno "Are you sure you want to install ArchLinux now?" 0 0
if [[ $? != $DIALOG_OK ]]; then clear; exit; fi

# DRIVE SETUP
while true; do
    selection=$(dialog --title "Drive Setup" --backtitle "$backtitle" --clear \
        --menu "How do you want to install Arch Linux?" 0 0 0 \
        "Erase Disk" "Start with a fresh install of Arch Linux" \
        "Manual" "Manually partition and format your target drive" 2>&1 1>&3)
    case $? in
        $DIALOG_CANCEL)
            display_abortion;;
        $DIALOG_ESC)
            display_abortion;;
    esac
    case $selection in
        "Erase Disk")
            unset options
            while read -r device name; do # read all HDDs and SSDs into a list
                options+=("$device" "$name")
            done < <(lsblk -do NAME,MODEL,SIZE | grep -E "sd|vd|nvme")
            drive=$(dialog --title "Erase Disk" --backtitle "$backtitle" --menu "Select the drive on which Arch Linux should be installed:" 0 0 0 "${options[@]}" 2>&1 1>&3)
            if [[ $(bash ./helpers/erase_disk.sh) == 0 ]]; then break; fi
            ;;
        "Manual") # TODO: Implement
            display_msg "Not Implemented" "Not Implemented"
            break
            ;;
    esac
done

# USER CONFIGURATION
## Keyboard Layout
while true; do
    user_keymap=$(dialog --title "Keyboard Layout" --backtitle "$backtitle" --menu "Choose your keyboard layout:" 0 0 0 \
        "us" "US ANSI" \
        "uk" "UK ISO" \
        "de-latin1" "German ISO" \
        "de-latin1-nodeadkeys" "German ISO without Dead Keys" \
        "other" "List all keymaps" 2>&1 1>&3)
    case $? in
        $DIALOG_CANCEL)
            display_abortion;;
        $DIALOG_ESC)
            display_abortion;;
    esac
    if [[ $user_keymap == "other" ]]; then
        unset options
        while read -r _keymap; do
            options+=("$_keymap" "")
        done < <(localectl list-keymaps)
        user_keymap=$(dialog --title "Other Keyboard Layouts" --backtitle "$backtitle" --menu "Choose your keyboard layout:" 0 0 0 "${options[@]}" 2>&1 1>&3)
    fi
    if [[ $user_keymap != "" && $user_keymap != "other" ]]; then
        break
    fi
done
loadkeys $user_keymap # load the specified keymap for use in the rest of the setup

## locale
while true; do
    user_locale=$(dialog --title "Language" --backtitle "$backtitle" --clear --help-button --no-cancel \
                    --no-collapse --inputbox "What language do you want to use?" 0 0 "en_US" 2>&1 1>&3)
    case $? in
        $DIALOG_HELP)
            dialog --title "Available locales" --backtitle "second2050's arch installer" --clear \
                --msgbox "$(cat /etc/locale.gen)" 40 83
            ;;
        $DIALOG_ESC)
            display_abortion;;
        $DIALOG_OK)
            break;;
    esac
done

## timezone
_autotz="$(curl --silent --fail https://ipapi.co/timezone)"
while true; do
    user_timezone=$(dialog --title "Timezone" --backtitle "$backtitle" --clear --help-button --no-cancel \
                    --no-collapse --inputbox "What Timezone are you in?" 0 0 "$autotz" 2>&1 1>&3)
    case $? in
        $DIALOG_HELP)
            dialog --title "Available timezones" --backtitle "$backtitle" --clear \
                --msgbox "$(timedatectl list-timezones)" 20 40
            ;;
        $DIALOG_ESC)
            clear
            echo "Program aborted." >&2
            exit 1
            ;;
        $DIALOG_OK)
            break;;
    esac
done

## hostname
while true; do
    user_hostname=$(dialog --title "Hostname" --backtitle "$backtitle" --clear --no-cancel \
                    --no-collapse --inputbox "What hostname do you want to use?" 0 0 "second2050" 2>&1 1>&3)
    case $? in
        $DIALOG_ESC)
            display_abortion;;
        $DIALOG_OK)
            if [[ $user_hostname != "" ]]; then break; fi
            break;
    esac
done

## user creation
while true; do
    user_username=$(dialog --title "User Account" --backtitle "second2050's arch installer - Configuration" --clear --no-cancel \
                    --no-collapse --inputbox "Please enter the name\nfor the new user" 0 0 2>&1 1>&3)
    case $? in
        $DIALOG_ESC)
            clear
            echo "Program aborted." >&2
            exit 1
            ;;
        $DIALOG_OK)
            ;;
    esac
    if [[ $rootpw == "" ]]; then
        dialog --title "User Account" --backtitle "second2050's arch installer - Configuration" --clear --no-cancel \
            --no-collapse --msgbox "A user account is needed and can't be skipped" 0 0
    else
        break
    fi
done

## set user password
while true; do
    user_password=$(dialog --title "User Password" --backtitle "second2050's arch installer - Configuration" --clear --no-cancel \
                    --no-collapse --insecure --passwordbox "Please enter the new password\nfor user $username" 0 0 2>&1 1>&3)
    case $? in
        $DIALOG_ESC)
            clear
            echo "Program aborted." >&2
            exit 1
            ;;
        $DIALOG_OK)
            ;;
    esac
    if [[ $userpw == "" ]]; then
        dialog --title "User Password" --backtitle "second2050's arch installer - Configuration" --clear --no-cancel \
            --no-collapse --msgbox "A password is needed and can't be skipped" 0 0
    else
        break
    fi
done

# System Installation
## choose kernel
while true; do
    system_kernel=$(dialog --title "Kernel" --backtitle "$backtitle" --menu "Choose your Kernel:" 0 0 0 \
        "linux" "Default Arch Linux Kernel" \
        "linux-lts" "Long Term Support Kernel" \
        "linux-zen" "Kernel optimized for workstation usecases" 2>&1 1>&3)
    case $? in
        $DIALOG_CANCEL)
            display_abortion;;
        $DIALOG_ESC)
            display_abortion;;
    esac
done

## choose video drivers
while true; do
    selection=$(dialog --title "Choose video driver" --backtitle "$backtitle" --clear \
        --radiolist "Press 'space' to select then press 'enter' to confirm." 0 0 7 \
        "1" "None" on \
        "2" "AMD (GCN 3 and higher)" off \
        "3" "ATI (GCN 2 and lower)" off \
        "4" "Intel" off \
        "5" "NVIDIA (Nouveau)" off \
        "6" "NVIDIA (Proprietary)" off 2>&1 1>&3)
    case $? in
        $DIALOG_CANCEL)
            display_abortion;;
        $DIALOG_ESC)
            display_abortion;;
        $DIALOG_OK)
            break;;
    esac
done
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

## finally pacstrap
dialog --backtitle "$backtitle" --no-cancel --pause "\n  Arch Linux will now be installed." 10 39 5
pacstrap /mnt $basepkgs $system_kernel "$system_kernel"-headers $fontpkgs $scriptpkgs $videopkgs $desktopenvpkgs $bootloaderpkgs

# remove /etc/resolv.conf in new root because I can't seem to symlink systemd-resolved's stub correctly otherwise...
rm /mnt/etc/resolv.conf

# generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# dump user config for chroot setup
(
    echo "user_timezone=\"$user_timezone\""
    echo "user_locale=\"$user_locale\""
    echo "user_keymap=\"$user_keymap\""
    echo "user_hostname=\"$user_hostname\""
    echo "user_username=\"$user_username\""
    echo "user_password=\"$user_password\""
    echo "system_kernel=\"$system_kernel\""
) > userconfig.conf

# switching to arch-chroot to continue with the setup
mkdir -p /mnt/root/arch_install_scripts
cp -r . /mnt/root/arch_install_scripts
arch-chroot /mnt /root/arch_install_scripts/setup_full_chroot.sh
