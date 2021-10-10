#!/usr/bin/env bash
# second2050 arch install script - Nvidia driver install script

# install packages
pacman -S --noconfirm nvidia-dkms

# finish
echo "Script is finished!"
echo "INFO: To enable DRM KMS add \'nvidia-drm.modeset=1\' to your kernel parameters."
