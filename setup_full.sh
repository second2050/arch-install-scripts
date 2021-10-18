#!/usr/bin/env bash
# second2050 arch install script - FULL execution
if [[ $1 == "phase3" ]]; then
    /root/arch_install_scripts/phase3_base_config.sh
    if [[ $2 != "" ]]; then
        /root/arch_install_scripts/phase3_"$2".sh
    fi
    case $3 in
        "nvidia")
            /root/arch_install_scripts/phase3_nvidia.sh
    esac
    case $4 in
        "kde")
            /root/arch_install_scripts/phase4_kde.sh
    esac
    exit
else
    _bootmgrlist=("none" "UEFI (rEFInd)" "BIOS (GRUB)")
    _gpulist=("none" "nvidia")
    _delist=("none" "KDE")

    echo ""
    PS3="Which boot manager?"
    select _bootmgrselection in "${_bootmgrlist[@]}"; do
        case $_bootmgrselection in
            "none")
                _bootmgr=""
                break;;
            "UEFI (rEFInd)")
                _bootmgr="bootmgr_refind"
                break;;
            "BIOS (GRUB)")
                _bootmgr="bootmgr_grub_bios"
                break;;
        esac
    done

    echo ""
    PS3="Which display driver?"
    select _gpulistselection in "${_gpulist[@]}"; do
        case $_gpulistselection in
            "none")
                _gpu=""
                break;;
            "Nvidia")
                _gpu="nvidia"
                break;;
        esac
    done

    echo ""
    PS3="Which desktop environment?"
    select _delistselection in "${_delist[@]}"; do
        case $_delistselection in
            "none")
                _de=""
                break;;
            "KDE")
                _de="kde"
                break;;
        esac
    done

    echo ""
    echo "THIS WILL START THE INSTALLATION OF ARCH"
    echo "ARE YOU SURE YOU WANT TO DO THIS?"
    echo "THIS WILL RUN ALL SCRIPTS BACK-TO-BACK!"
    echo ""
    read -t 10 -p "[YES/no]: " _doit
    if [[ $_doit != "YES" ]]; then
    	echo "User aborted."
    	exit
    fi


    # Execution!
    bash phase2_base_install.sh
    mkdir -p /mnt/root/arch_install_scripts
    cp -r . /mnt/root/arch_install_scripts
    arch-chroot /mnt /root/arch_install_scripts/"$0" phase3 $_bootmgr $_gpu $_de
fi;

