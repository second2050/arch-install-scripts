#!/usr/bin/env bash

# variables
_root_device=$1 # like "vda"
_esp_part=$2    # like "1"
clover_version=5142

# switch to a temp directory
mkdir -p "/tmp/$0"
cd /tmp/$0 || exit

# download the iso if not already done so
if [[ ! -f ./CloverISO-$clover_version.tar.lzma ]]; then
    if [[ ! -f /usr/bin/wget ]]; then pacman -S --noconfirm wget; fi
    wget https://github.com/CloverHackyColor/CloverBootloader/releases/download/$clover_version/CloverISO-$clover_version.tar.lzma
    tar --lzma -xvf CloverISO-$clover_version.tar.lzma
fi

# mount the iso
mkdir iso
mount -o loop "./Clover-$clover_version-X64.iso" "/tmp/$0/iso"

# merge clover with current M-/PBR
dd if="/dev/$_root_device$_esp_part" of=./original_pbr.img bs=512 count=1 conv=notrunc
cp ./iso/usr/standalone/i386/boot1f32 ./new_pbr.img
dd if=./original_pbr.img of=new_pbr.img skip=3 seek=3 bs=1 count=87 conv=notrunc
dd if=new_pbr.img of="/dev/$_root_device$_esp_part" bs=512 count=1 conv=notrunc
dd if=./iso/usr/standalone/i386/boot0ss of="/dev/$_root_device" bs=440 count=1 conv=notrunc

# copy legacy bootloader from clover
cp ./iso/usr/standalone/i386/x64/boot6 /efi/boot

# copy over clover
cp ./iso/EFI/BOOT /efi/EFI/BOOT
cp ./iso/EFI/CLOVER /efi/EFI/CLOVER

# configure it to chainload refind
cat <<EOF > /efi/EFI/CLOVER/config.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Boot</key>
	<dict>
		<key>DefaultVolume</key>
		<string>EFI</string>
		<key>DefaultLoader</key>
		<string>\EFI\refind\refind_x64.efi</string>
		<key>Fast</key>
		<true/>
	</dict>
	<key>GUI</key>
	<dict>
		<key>Custom</key>
		<dict>
			<key>Entries</key>
			<array>
				<dict>
					<key>Hidden</key>
					<false/>
					<key>Disabled</key>
					<false/>
					<key>Image</key>
					<string>os_arch</string>
					<key>Volume</key>
					<string>EFI</string>
					<key>Path</key>
					<string>\EFI\refind\refind_x64.efi</string>
					<key>Title</key>
					<string>rEFInd</string>
					<key>Type</key>
					<string>Linux</string>
				</dict>
			</array>
		</dict>
	</dict>
</dict>
</plist>
EOF

# set "legacy bios bootable" attribute on the esp
sgdisk -A $_esp_part:set:2
