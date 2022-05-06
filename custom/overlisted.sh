source .base_gnome.sh
source .base_amdgpu.sh
source .base_codecs.sh
source .base_zsh.sh

export CUSTOM_YAY="$CUSTOM_YAY
	aur/vscodium-bin aur/ttf-twemoji aur/nerd-fonts-jetbrains-mono
	community/neovim community/virt-manager community/ttf-dejavu community/rustup
	community/inter-font community/glfw-wayland
	community/firefox-developer-edition
	core/man-pages
	extra/noto-fonts extra/qemu extra/noto-fonts-cjk
	multilib/steam"

export CUSTOM_FLATPAK="$CUSTOM_FLATPAK
	org.gnome.Weather//stable
	org.gnome.Epiphany.Devel//
	org.telegram.desktop//beta
	com.mattjakeman.ExtensionManager//beta
	de.haeckerfelix.Fragments//stable
	com.usebottles.bottles//stable
	com.github.tchx84.Flatseal//stable"

function custom_post() {
	git clone --recurse-submodules https://github.com/overlisted/dotfiles /tmp/dotfiles
	rsync -a /tmp/dotfiles/files/.* $HOME
	dconf load / < /tmp/dotfiles/settings.dconf

	rustup default nightly
	rustup component add rustfmt
}
