#!/bin/bash

set -e

if [ -d /usr/share/rach ]; then
	rach=/usr/share/rach
else
	rach=$(pwd)
fi

source $rach/tasks.sh

function task() {
	local oldpwd=$(pwd)

	printf "%s\n===> %8s $2\n\n" "$(tput setaf 9)" "($1)"

	$1_$2 ${@:3}

	cd "$oldpwd"
}

while getopts ":p:" opt; do
	case $opt in
	p)
		part_prefix=$OPTARG
		;;
	\?)
		echo "Invalid option: -$OPTARG" >&2
		exit 1
		;;
	:)
		echo "Option -$OPTARG requires an argument." >&2
		exit 1
		;;
	esac
done

if [ $1 = "base" ]; then
	task iso partitions $2 $part_prefix
	task iso packages
	task iso fstab
	task iso usr_rach
	task iso chroot "/usr/share/rach/rach.sh _chrooted"
	task iso chroot
	task iso reboot
elif [ $1 = "userspace" ]; then
	task root root_pass
	task root home_save $2
	task root groups
	task root user $2
	task root podman $2
	task root ufw
	task root ntp
	task root flatpak
	task root login $2 $rach/rach.sh _logged_in $3
	echo -e "\n\n\nReboot whenever you're ready."
elif [ $1 = "_chrooted" ]; then
	task chroot systemd_boot
	task chroot services
	task chroot doas
	task chroot zram
	task chroot pacman
	task chroot root_pass
elif [ $1 = "_logged_in" ]; then
	task user load_custom $2
	task user yay
	task user yay_pkgs
	task user flatpak
	task user enable
	task user shell
	task user post
fi
