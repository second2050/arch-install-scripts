#!/usr/bin/env bash
# second2050 arch post-install script - aurto setup

# check if git is installed

echo "INFO: Checking for git..."
if [ ! -f /bin/git ]; then
    echo "INFO: git not found, installing..."
    pacman -S --noconfirm git
else
    echo "INFO: git found!"
fi

# getting required packages
echo "INFO: Downloading packages..."
git clone https://aur.archlinux.org/aurutils.git
git clone https://aur.archlinux.org/aurto.git

# building and installing packages
echo "INFO: Building packages..."
cd aurutils; makepkg -si --noconfirm; cd ..
cd aurto; makepkg -si --noconfirm; cd ..

# initalizing aurto
echo "INFO: Initializing aurto..."
aurto init

# adding aurutils and aurto to aurto's db
echo "INFO: Adding 'aurto' and 'aurutils' to aurto's db..."
echo "      This will enable auto building of updates for aurto"
aurto add aurutils aurto
