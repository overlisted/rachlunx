#!/bin/bash
# Usage:
#   rachlogin.sh [custom]
# custom   - Path to the custom config script

set -e

RACH=/usr/share/rach

FLATPAK_REPOS=(
	"flathub https://flathub.org/repo/flathub.flatpakrepo"
	"flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo"
	"gnome-nightly https://nightly.gnome.org/gnome-nightly.flatpakrepo"
	"webkit https://software.igalia.com/flatpak-refs/webkit-sdk.flatpakrepo"
)

if [ -z $1 ]; then
	source $RACH/custom/noop.sh
else
	PATH="$PATH:$RACH/custom" source $RACH/custom/$1
fi

cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm

yay --noconfirm -R sudo || sudo rm /usr/bin/sudo
yay --noconfirm --sudo doas -S aur/yay aur/opendoas-sudo $CUSTOM_YAY

for ((i = 0; i < ${#FLATPAK_REPOS[@]}; i++)); do
	flatpak remote-add --user --if-not-exists ${FLATPAK_REPOS[$i]}
done

# i don't want any apps accidentally getting installed under root
sudo flatpak remote-delete flathub

for app in $CUSTOM_FLATPAK; do
	flatpak install --noninteractive --user $app
done

custom_post

[ -z "$CUSTOM_ENABLE" ] || sudo systemctl enable $CUSTOM_ENABLE

homectl update $(whoami) --shell=$CUSTOM_SHELL

sudo reboot now
