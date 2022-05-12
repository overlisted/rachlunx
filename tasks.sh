### iso

# $1 - disk device
function iso_partitions() {
	efi_part=1
	root_part=2

	function fdisk_commands() {
		echo "g"

		echo "n"
		echo "$efi_part" # part num
		echo "" # first sector
		echo "+256M" # last sector

		echo "t"
		# echo "$efi_part" # part num
		echo "1" # type number

		echo "n"
		echo "$root_part" # part num
		echo "" # first sector
		echo "" # last sector

		echo "t"
		echo "$root_part" # part num
		echo "23" # type number

		echo "w"
	}

	fdisk_commands | fdisk -W always $1 # -W gets rid of that annoying y/n prompt

	mkfs.vfat $1$efi_part
	mkfs.ext4 $1$root_part -L archroot

	mount $1$root_part /mnt
	mkdir /mnt/boot
	mount $1$efi_part /mnt/boot
}

function iso_packages() {
	packages=(
		linux-zen linux-firmware amd-ucode intel-ucode fuse-overlayfs
		base dbus-broker networkmanager ufw flatpak libvirt zram-generator
		opendoas wget curl git nano rsync docker podman
		linux-zen-headers base-devel go
	)

	pacstrap /mnt ${packages[@]}
}

function iso_fstab() {
	genfstab -U /mnt >> /mnt/etc/fstab
}

function iso_usr_rach() {
	cp -r $rach /mnt/usr/share/rach
}

# $:1 - execv command to run
function iso_chroot() {
	arch-chroot /mnt ${@:1}
}

function iso_reboot() {
	reboot
}

### chroot

function chroot_systemd_boot() {
	bootctl install
	cp $rach/data/systemd-boot/loader.conf /boot/loader
	cp $rach/data/systemd-boot/arch.conf /boot/loader/entries
}

function chroot_services() {
	services=(
		systemd-resolved systemd-homed NetworkManager avahi-daemon libvirtd ufw
		docker
	)

	systemctl disable dbus
	systemctl enable dbus-broker ${services[@]}
}

function chroot_doas() {
	ln -sf /usr/bin/doas /usr/bin/sudo
	cp $rach/data/doas.conf /etc/doas.conf
	chmod 0400 /etc/doas.conf
}

function chroot_zram() {
	# zram-generator enables itself
	cp $rach/data/zram-generator.conf /etc/systemd/zram-generator.conf
}

function chroot_pacman() {
	cat $rach/data/pacman.conf.append >> /etc/pacman.conf
	pacman -Sy
}

function chroot_root_pass() {
	passwd -d root
}

### root

function root_root_pass() {
	passwd -l root
}

# $1 - dir name
function root_home_save() {
	mv /home/$1 /home/$1.old || :
}

function root_groups() {
	groupadd libvirt || :
	groupadd docker || :
	groupadd wheel || :
}

# $1 - username
function root_user() {
	homectl create \
		--storage=directory \
		--member-of=libvirt \
		--member-of=docker \
		--member-of=wheel \
		$1
}

# $1 - username
function root_podman() {
	touch /etc/subuid /etc/subgid
	usermod --add-subuids 100000-165535 --add-subgids 100000-165535 $1
}

function root_ufw() {
	ufw enable
}

function root_ntp() {
	timedatectl set-ntp true
}

function root_flatpak() {
	flatpak remote-delete flathub || :
}

# $1 - username
# $:2 - execv command to run
function root_login() {
	homectl activate $1
	# sudo deactivates the homedir without this
	# and all session services mess up too
	machinectl shell $1@.host ${@:2}
}

### user

# $1 - script name
function user_load_custom() {
	cd $rach/custom

	if [ -n "$1" ]; then
		source $1.sh
	else
		source noop.sh
	fi
}

function user_yay() {
	cd /tmp
	git clone https://aur.archlinux.org/yay.git || :
	cd yay
	makepkg -si --noconfirm
}

function user_yay_pkgs() {
	yay --noconfirm --sudo doas -S archlinux-keyring
	yay --noconfirm --sudo doas -R sudo || sudo rm /usr/bin/sudo
	yay --sudo doas -S aur/yay aur/opendoas-sudo $custom_yay
}

function user_flatpak() {
	repos=(
		"flathub https://flathub.org/repo/flathub.flatpakrepo"
		"flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo"
		"gnome-nightly https://nightly.gnome.org/gnome-nightly.flatpakrepo"
		"webkit https://software.igalia.com/flatpak-refs/webkit-sdk.flatpakrepo"
	)

	for ((i = 0; i < ${#repos[@]}; i++)); do
		flatpak remote-add --user --if-not-exists ${repos[$i]}
	done

	for app in $custom_flatpak; do
		flatpak install --noninteractive --user $app
	done
}

function user_enable() {
	[ -n "$custom_enable" ] && sudo systemctl enable $custom_enable
}

function user_shell() {
	[ -n "$custom_shell" ] && homectl update $(whoami) --shell=$custom_shell
}

function user_post() {
	custom_post
}
