#!/bin/bash
# Usage:
#   rach.sh <disk>
# disk - Target disk (/dev/sda)

set -e

PKG_KERNEL="linux-zen linux-firmware amd-ucode intel-ucode"
PKG_SYSTEM="base dbus-broker networkmanager ufw flatpak libvirt zram-generator"
PKG_PROGRAMS="opendoas wget curl git nano rsync docker"
PKG_DEVEL="linux-zen-headers base-devel go"

PACKAGES="$PKG_KERNEL $PKG_SYSTEM $PKG_DEVEL $PKG_PROGRAMS"
ENABLE="systemd-resolved systemd-homed NetworkManager avahi-daemon libvirtd ufw
	docker"

RACH=/usr/share/rach

if [ $1 = "chrooted" ]; then
	bootctl install
	cp $RACH/systemd-boot/loader.conf /boot/loader/
	cp $RACH/systemd-boot/arch.conf /boot/loader/entries/

	systemctl disable dbus
	systemctl enable dbus-broker $ENABLE

	ln -sf /usr/bin/doas /usr/bin/sudo
	cp $RACH/doas.conf /etc/doas.conf
	chmod 0400 /etc/doas.conf

	# zram-generator enables itself
	cp $RACH/zram-generator.conf /etc/systemd/zram-generator.conf

	cat $RACH/pacman.conf.append >> /etc/pacman.conf
	pacman -Sy

	timedatectl set-ntp true

	usermod --password $(echo 1 | openssl passwd -1 -stdin) root
else
	export EFI_PART=1
	export ROOT_PART=2

	function fdisk_commands() {
		echo "g"

		echo "n"
		echo "$EFI_PART" # part num
		echo "" # first sector
		echo "+256M" # last sector

		echo "t"
		# echo "$EFI_PART" # part num
		echo "1" # type number

		echo "n"
		echo "$ROOT_PART" # part num
		echo "" # first sector
		echo "" # last sector

		echo "t"
		echo "$ROOT_PART" # part num
		echo "23" # type number

		echo "w"
	}

	fdisk_commands | fdisk -W always $1 # -W gets rid of that annoying y/n prompt

	mkfs.vfat $1$EFI_PART
	mkfs.ext4 $1$ROOT_PART -L archroot

	mount $1$ROOT_PART /mnt
	mkdir /mnt/boot
	mount $1$EFI_PART /mnt/boot

	pacstrap /mnt $PACKAGES
	genfstab -U /mnt >> /mnt/etc/fstab

	mv /tmp/rach /mnt/$RACH
	arch-chroot /mnt $RACH/rach.sh chrooted
	arch-chroot /mnt # interactive
fi
