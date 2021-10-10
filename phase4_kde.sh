#!/usr/bin/env bash
# second2050 arch install script - KDE install script

# install packages
echo "INFO: Installing packages..."
pacman -S --noconfirm plasma-meta sddm kde-applications plasma-wayland-session

# set sddm as the dm
echo "INFO: Setting SDDM as the Display Manager..."
systemctl enable sddm.service

# set breeze theme in sddm
echo "INFO: Setting Theme of SDDM..."
cat <<EOF > /etc/sddm.conf.d/kde_settings.conf
[Theme]
Current=breeze
CursorTheme=breeze_cursors
EOF

# finish
echo "Script is finished!"
