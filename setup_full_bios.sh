#!/usr/bin/env bash
# second2050 arch install script - FULL execution (Phase 2 and later) without desktop environment
if [[ $1 == "phase3" ]]; then
    ./phase3_base_config.sh
    ./phase3_bootmgr_grub_bios.sh
    exit
else
    echo "THIS WILL START THE INSTALLATION OF ARCH"
    echo "ARE YOU SURE YOU WANT TO DO THIS?"
    echo "THIS WILL RUN ALL SCRIPTS BACK-TO-BACK!"
    echo ""
    echo "Chosen Setup: BIOS (with grub)"
    bash phase2_base_install.sh
    cp . /mnt/root/arch_install_scripts
    arch-chroot /mnt /mnt/root/arch_install_scripts/setup_second2050.sh phase3
fi;
