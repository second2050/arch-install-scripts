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
fontpkgs=""
videopkgs=""
desktopenvpkgs=""
bootloaderpkgs=""

# load userconfig from part 1
source /root/arch_install_scripts/userconfig.conf

# install non-base packages
pacman -S --noconfirm git $fontpkgs $videopkgs $desktopenvpkgs $bootloaderpkgs

# timezone
ln -sf "/usr/share/zoneinfo/$user_timezone" /etc/localtime
hwclock --systohc

# locale
sed -i "/en_US.UTF-8/s/^#//g" /etc/locale.gen
sed -i "/$user_locale.UTF-8/s/^#//g" /etc/locale.gen

# keyboard layout for vconsole
echo "KEYMAP=$user_keymap" > /etc/vconsole.conf

# networking
## hostname
echo "$user_hostname" > /etc/hostname
cat <<EOF >> /etc/hosts 
127.0.0.1    localhost
::1          localhost
127.0.1.1    $user_hostname
EOF
systemctl enable NetworkManager
systemctl enable iwd
systemctl enable systemd-resolved
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
## write NetworkManager config
mkdir -p /etc/NetworkManager/conf.d
cat <<EOF > /etc/NetworkManager/conf.d/wifi_backend.conf
[device]
wifi.backend=iwd
EOF
cat <<EOF > /etc/NetworkManager/conf.d/mdns.conf
[connection]
connection.mdns=2 # enable mdns resolution and registering/broadcasting
EOF
## write resolved config
cat <<EOF >> /etc/systemd/resolved.conf

# second2050's resolved conf
DNS=1.1.1.1
FallbackDNS=1.0.0.1 9.9.9.9 9.9.9.10 8.8.8.8 2606:4700:4700::1111 2620:fe::10 2001:4860:4860::8888
DNSSEC=yes
DNSOverTLS=yes
MulticastDNS=yes
Cache=yes
EOF

# configurating pacman
sed -i "/Color/s/^#//g" /etc/pacman.conf
sed -i "/ParallelDownloads/s/^#//g" /etc/pacman.conf

# recreate initramfs, just to be safe
mkinitcpio -P

# create user
useradd -m -G wheel -s /bin/bash $user_username
echo "$user_username:$user_password" | chpasswd

## set fish as user shell via chainloading from bash
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

# setup sddm
systemctl enable sddm.service
mkdir -p /etc/sddm.conf.d
cat <<EOF > /etc/sddm.conf.d/kde_settings.conf
[Theme]
Current=breeze
CursorTheme=breeze_cursors
EOF

# setup refind
refind-install

## setup up a working refind_linux.conf
echo "INFO: Create good refind_linux.conf"
_uuid=$(lsblk -no UUID $(df -P / | awk 'END{print $1}'))
{
    echo "\"Boot with standard options\"   \"root=UUID=$_uuid rw initrd=boot\initramfs-%v.img loglevel=3 rd.udev.log_priority=3\""
    echo "\"Boot with fallback initramfs\" \"root=UUID=$_uuid rw initrd=boot\initramfs-%v-fallback.img loglevel=3 rd.udev.log_priority=3\""
    echo "\"Boot to terminal\"             \"root=UUID=$_uuid rw initrd=boot\initramfs-%v.img loglevel=3 rd.udev.log_priority=3 systemd.unit=multi-user.target\""
} > /boot/refind_linux.conf

## download better looking theme
## refind-theme-regular by bobafetthotmail
{
    cd /efi/EFI/refind || return # this shouldn't fail but oh well shellcheck
    git clone https://github.com/bobafetthotmail/refind-theme-regular.git

    # set theme to dark
    cp ./refind-theme-regular/theme.conf ./theme.conf
    sed -i "/.png/s/^#*/#/g" theme.conf # comment out every line referencing ".png" files
    size="128-48"
    sed -i "/$size\/bg_dark.png/s/^#//g" theme.conf
    sed -i "/$size\/selection_dark-big.png/s/^#//g" theme.conf
    sed -i "/$size\/selection_dark-small.png/s/^#//g" theme.conf
    sed -i "/source-code-pro-extralight-14.png/s/^#//g" theme.conf
}

## setup refind.conf
mv /efi/EFI/refind/refind.conf /efi/EFI/refind/refind.conf.old
cat <<EOF > /efi/EFI/refind/refind.conf
# second2050'S refind config (minified)
timeout 5
extra_kernel_version_strings linux-xanmod,linux-zen,linux-lts,linux
write_systemd_vars true
include theme.conf
EOF

echo "Setup Finished!"
