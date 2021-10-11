# ArchLinux Install Script
These script should semi-automatically give you a usable ArchLinux System.

Partitioning must still be done by hand but formating your root partition as
btrfs can be done automatically.
## BTRFS subvolume layout:
`@` as `/`  
`@home` as `/home` with zstd compression  
`@var` as `/var`  

# Phase Descriptions:
Phase 1: Pre-install  
Phase 2: Installation of base packages  
Phase 3: System configuration  
Phase 4: Desktop Environments  

# ToDo:
- Phase 4
  - Xmonad
  - i3-gaps