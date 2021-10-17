#!/usr/bin/env bash
# second2050 arch install script - FULL execution (Phase 2 and later) without desktop environment
if [[ $1 == "phase3" ]]; then
    ./phase3_base_config.sh
    exit
else
    echo "THIS WILL START THE INSTALLATION OF ARCH"
    echo "ARE YOU SURE YOU WANT TO DO THIS?"
    echo "THIS WILL RUN ALL SCRIPTS BACK-TO-BACK!"
    echo ""
    echo "Chosen Setup: No Bootmanager"
    read -t 10 -p "[YES/no]: " _doit
    if [[ $_doit != "YES" ]]; then
    	echo "User aborted."
    	exit
    fi
    bash phase2_base_install.sh
    mkdir -p /mnt/root/arch_install_scripts
    cp -r . /mnt/root/arch_install_scripts
    arch-chroot /mnt /root/arch_install_scripts/"$0" phase3
fi;

