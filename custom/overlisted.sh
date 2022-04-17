source .base_gnome.sh
source .base_amdgpu.sh
source .base_codecs.sh

export CUSTOM_SHELL=/bin/zsh

export CUSTOM_YAY="$CUSTOM_YAY
	aur/vscodium-bin aur/bottles aur/ttf-twemoji
	community/neovim community/virt-manager community/ttf-dejavu
	community/ttf-nerd-fonts-symbols community/inter-font community/glfw-wayland
	commuitty/rustup
	core/man-pages
	extra/zsh extra/noto-fonts extra/qemu extra/noto-fonts-cjk
	multilib/steam"

export CUSTOM_FLATPAK="$CUSTOM_FLATPAK
	org.gnome.Weather//stable
	org.gnome.Epiphany.Devel//
	org.telegram.desktop//beta
	com.mattjakeman.ExtensionManager//beta
	de.haeckerfelix.Fragments//stable"

function custom_post() {
	cd /tmp
	git clone --recurse-submodules https://github.com/overlisted/dotfiles
	rsync -a dotfiles/files/.* $HOME

	rustup default nightly
	rustup component add rustfmt
}
