# Arch Linux Install Script
This script will interactively guide you through your Arch Linux installation, while also using my own defaults

## System configuration:
- Pacman
  - Enabled colored output
  - Enabled parallel downloads
- Networking
  - Using NetworkManager + systemd-resolved
  - Cloudflare DNS (`1.1.1.1`) as default DNS server with DNSSEC + DNSoverTLS
- Graphical Environment
  - Desktop Environment: KDE Plasma 5
  - Display Manager: Simple Desktop Display Manager
    - using Breeze theme
- User defaults:
  - 🐟 (`fish`) as default shell
- Bootloader: rEFInd
  - using [refind-theme-regular by bobafetthotmail](https://github.com/bobafetthotmail/refind-theme-regular)


## BTRFS subvolume layout:
`@` as `/`  
`@home` as `/home` with zstd compression  
`@var` as `/var`  
