#!/usr/bin/env bash
# second2050 arch install script - FULL execution with TUI part 2

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

# set timezone
autotz="$(curl --silent --fail https://ipapi.co/timezone)"
timezone=""
while true; do
    timezone=$(dialog --title "Timezone" --backtitle "second2050's arch installer - Configuration" --clear --help-button --no-cancel \
                    --no-collapse --inputbox "What Timezone are you in?" 0 0 "$autotz" 2>&1 1>&3)
    case $? in
        $DIALOG_HELP)
            dialog --title "Available timezones" --backtitle "second2050's arch installer - Configuration" --clear \
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
ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime
hwclock --systohc # sync hardware clock

# set language
while true; do
    localelanguage=$(dialog --title "Locale - Language" --backtitle "second2050's arch installer - Configuration" --clear --help-button --no-cancel \
                    --no-collapse --inputbox "What language do you want to use?" 0 0 "en_US" 2>&1 1>&3)
    case $? in
        $DIALOG_HELP)
            dialog --title "Available locales" --backtitle "second2050's arch installer - Configuration" --clear \
                --msgbox "$(cat /etc/locale.gen)" 40 83
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
sed -i "/$localelanguage.UTF-8/s/^#//g" /etc/locale.gen

# set time locale
dialog --title "Locale - Time" --backtitle "second2050's arch installer - Configuration" \
    --yesno "Do you want to set a different locale for your time?" 0 0
case $? in
    $DIALOG_OK)
        while true; do
            localetime=$(dialog --title "Locale - Time" --backtitle "second2050's arch installer - Configuration" --clear --help-button --no-cancel \
                            --no-collapse --inputbox "What language do you want to use?" 0 0 "en_GB" 2>&1 1>&3)
            case $? in
                $DIALOG_HELP)
                    dialog --title "Available locales" --backtitle "second2050's arch installer - Configuration" --clear \
                        --msgbox "$(cat /etc/locale.gen)" 40 83
                    ;;
                $DIALOG_ESC)
                    break;;
                $DIALOG_OK)
                    sed -i "/$localetime.UTF-8/s/^#//g" /etc/locale.gen
                    break;;
            esac
        done
        ;;
    $DIALOG_ESC)
        localetime="$localelanguage"
        ;;
esac

# set other locale
dialog --title "Locale - Other" --backtitle "second2050's arch installer - Configuration" \
    --yesno "Do you want to set a different locale for measurement, addresses etc?" 0 0
case $? in
    $DIALOG_OK)
        while true; do
            localeother=$(dialog --title "Locale - Other" --backtitle "second2050's arch installer - Configuration" --clear --help-button --no-cancel \
                            --no-collapse --inputbox "What language do you want to use?" 0 0 "de_DE" 2>&1 1>&3)
            case $? in
                $DIALOG_HELP)
                    dialog --title "Available locales" --backtitle "second2050's arch installer - Configuration" --clear \
                        --msgbox "$(cat /etc/locale.gen)" 40 83
                    ;;
                $DIALOG_ESC)
                    break;;
                $DIALOG_OK)
                    sed -i "/$localeother.UTF-8/s/^#//g" /etc/locale.gen
                    break;;
            esac
        done
        ;;
    $DIALOG_ESC)
        localeother="$localelanguage"
        ;;
esac

# generate locales
locale-gen | dialog --title "Generating locales..." --backtitle "second2050's arch installer - Configuration" --clear --programbox 20 40

# set keyboard layout for vconsole
while true; do
    keymap=$(dialog --title "Keyboard Layout" --backtitle "second2050's arch installer - Configuration" --clear --help-button --no-cancel \
                    --no-collapse --inputbox "What keyboard layout do you want to use in the TTY?" 0 0 "de-latin1" 2>&1 1>&3)
    case $? in
        $DIALOG_HELP)
            dialog --title "Available keyboard layouts" --backtitle "second2050's arch installer - Configuration" --clear \
                --msgbox "$(localectl list-keymaps)" 40 39
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
echo "KEYMAP=$keymap" >> /etc/vconsole.conf

# set hostname
while true; do
    hostname=$(dialog --title "Hostname" --backtitle "second2050's arch installer - Configuration" --clear --no-cancel \
                    --no-collapse --inputbox "What hostname do you want to use?" 0 0 "second2050" 2>&1 1>&3)
    case $? in
        $DIALOG_ESC)
            clear
            echo "Program aborted." >&2
            exit 1
            ;;
        $DIALOG_OK)
            break;;
    esac
done
echo "$hostname" > /etc/hostname
cat <<EOF >> /etc/hosts 
127.0.0.1    localhost
::1          localhost
127.0.1.1    $hostname
EOF

# setup networking
{
systemctl enable NetworkManager
systemctl enable iwd
systemctl enable systemd-resolved
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
# write NetworkManager config
mkdir -p /etc/NetworkManager/conf.d
cat <<EOF > /etc/NetworkManager/conf.d/wifi_backend.conf
[device]
wifi.backend=iwd
EOF
cat <<EOF > /etc/NetworkManager/conf.d/mdns.conf
[connection]
connection.mdns=2 # enable mdns resolution and registering/broadcasting
EOF
# write resolved config
cat <<EOF >> /etc/systemd/resolved.conf

# second2050's resolved conf
DNS=1.1.1.1
FallbackDNS=1.0.0.1 9.9.9.9 9.9.9.10 8.8.8.8 2606:4700:4700::1111 2620:fe::10 2001:4860:4860::8888
DNSSEC=yes
DNSOverTLS=yes
MulticastDNS=yes
Cache=yes
EOF
} | dialog --title "Setting up networking..." --backtitle "second2050's arch installer - Configuration" --progressbox 30 100

# configurating pacman
sed -i "/Color/s/^#//g" /etc/pacman.conf
sed -i "/ParallelDownloads/s/^#//g" /etc/pacman.conf

# recreate initramfs
dialog --title "Creating initramfs..." --backtitle "second2050's arch installer - Configuration" --infobox "please wait..." 0 0
mkinitcpio -P > /dev/null

# set root password
while true; do
    rootpw=$(dialog --title "Root Password" --backtitle "second2050's arch installer - Configuration" --clear --no-cancel \
                    --no-collapse --insecure --passwordbox "Please enter the new password\nfor the root user" 0 0 2>&1 1>&3)
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
        dialog --title "Root Password" --backtitle "second2050's arch installer - Configuration" --clear --no-cancel \
            --no-collapse --msgbox "A password is needed and can't be skipped" 0 0
    else
        break
    fi
done
echo "root:$rootpw" | chpasswd

# create user account
while true; do
    username=$(dialog --title "User Account" --backtitle "second2050's arch installer - Configuration" --clear --no-cancel \
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
useradd -m -G wheel -s /bin/bash $username

# set user password
while true; do
    userpw=$(dialog --title "User Password" --backtitle "second2050's arch installer - Configuration" --clear --no-cancel \
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
echo "$username:$userpw" | chpasswd

# set fish as user shell via chainloading from bash
cat <<EOF >> /home/$username/.bashrc
# Execute fish if not run from fish itself
if [ \$(ps -p \$PPID -o comm=) != "fish" ]; then
    exec fish
fi
EOF

# setup sudo
mkdir -p /etc/sudoers.d
cat <<EOF >> /etc/sudoers.d/second2050
# second2050's defaults
%wheel ALL=(ALL) ALL
Defaults pwfeedback
EOF

# install desktop environment
selection=$(dialog --title "Choose a Desktop Environment" --backtitle "second2050's arch installer - Configuration" --clear \
    --radiolist "Press 'space' to select then press 'enter' to confirm." 0 0 3 \
    "1" "None" on \
    "2" "KDE Plasma" off 2>&1 1>&3)
case $? in
    $DIALOG_CANCEL)
        selection=1
        ;;
    $DIALOG_ESC)
        clear
        echo "Program aborted." >&2
        exit 1
        ;;
esac
case $selection in
    1 )
        ;;
    2 )
        # running in a progressbox results in... something not good
        /root/arch_install_scripts/phase4_kde.sh #| dialog --title "Installing KDE Plasma" --backtitle "second2050's arch installer - Configuration" --progressbox 30 100
        ;;
esac

# setup a bootloader
selection=$(dialog --title "Choose a bootloader/-manager" --backtitle "second2050's arch installer - Configuration" --clear \
    --radiolist "Press 'space' to select then press 'enter' to confirm." 0 0 3 \
    "1" "UEFI: rEFInd" on \
    "3" "BIOS: GRUB" off 2>&1 1>&3)
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
        /root/arch_install_scripts/phase3_bootmgr_refind.sh | dialog --title "Installing rEFInd" --backtitle "second2050's arch installer - Configuration" --progressbox 30 100
        ;;
    # 2 ) 
    #    /root/arch_install_scripts/phase3_bootmgr_grub_uefi.sh | dialog --title "Installing GRUB (UEFI)" --backtitle "second2050's arch installer - Configuration" --progressbox 30 100    
    #     ;;
    3 )
        /root/arch_install_scripts/phase3_bootmgr_grub_bios.sh | dialog --title "Installing GRUB (BIOS)" --backtitle "second2050's arch installer - Configuration" --progressbox 30 100
        ;;
esac
clear
