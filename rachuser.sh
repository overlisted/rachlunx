#!/bin/bash
# Usage:
#   rachuser.sh <username> [custom]
# username - Username of the created user
# custom   - Path to the custom config script

set -e

RACH=/usr/share/rach

passwd -d root
mv /home/$1 /home/$1.old && echo "Moved old home"

homectl create \
	--storage=directory \
	--member-of=libvirt \
	--member-of=wheel \
	$1

ufw enable

# i hate this
echo "Please run su $1 and $RACH/rachlogin.sh (optionally with the name of the custom config)"
homectl with $1 sh
