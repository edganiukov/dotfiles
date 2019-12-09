.PHONY: nvim vim tmux git zsh x i3 awesome redshift etc dunst rofi qutebrowser vifm mc mutt fonts bin mpv rtorrent sxiv ncspot zathura

CWD=$(shell pwd)

nvim:
	mkdir -p ~/.config/nvim && \
		ln -s $(CWD)/init.vim $(HOME)/.config/nvim/init.vim
	curl -sfLo $(HOME)/.config/nvim/autoload/plug.vim --create-dirs \
		https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

vim:
	mkdir -p $(HOME)/.vim
	ln -s $(CWD)/init.vim $(HOME)/.vimrc
	curl -sfLo $(HOME)/.vim/autoload/plug.vim --create-dirs \
		https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

tmux:
	ln -s $(CWD)/tmux.conf $(HOME)/.tmux.conf
	mkdir -p $(HOME)/.tmux/plugins && \
		git clone https://github.com/tmux-plugins/tpm $(HOME)/.tmux/plugins/tpm

git:
	cp $(CWD)/gitconfig $(HOME)/.gitconfig

zsh:
	ln -s $(CWD)/zshrc $(HOME)/.zshrc
	ln -s $(CWD)/zsh $(HOME)/.zsh
	ln -s $(CWD)/zlogin $(HOME)/.zlogin

terminal:
	ln -s $(CWD)/alacritty.yml $(HOME)/.config/alacritty/alacritty.yml

x:
	ln -s $(CWD)/Xresources $(HOME)/.Xresources
	ln -s $(CWD)/xinitrc $(HOME)/.xinitrc
	ln -s $(CWD)/xbindkeysrc $(HOME)/.xbindkeysrc

awesome:
	ln -s $(CWD)/awesome $(HOME)/.config/awesome

i3:
	ln -s $(CWD)/i3 $(HOME)/.config/i3

rofi:
	mkdir -p $(HOME)/.config/rofi
	ln -s $(CWD)/rofi.conf $(HOME)/.config/rofi/config

redshift:
	mkdir -p $(HOME)/.config/redshift
	ln -s $(CWD)/redshift.conf $(HOME)/.config/redshift/redshift.conf

dunst:
	mkdir -p $(HOME)/.config/dunst
	ln -s $(CWD)/dunstrc $(HOME)/.config/dunst/dunstrc

etc:
	sudo cp $(CWD)/etc/90-backlight.rules /etc/udev/rules.d/90-backlight.rules
	sudo cp $(CWD)/etc/91-leds.rules /etc/udev/rules.d/91-leds.rules
	sudo cp $(CWD)/etc/resolved.conf /etc/systemd/resolved.conf

qutebrowser:
	ln -s $(CWD)/qutebrowser/config.py $(HOME)/.config/qutebrowser/config.py

vifm:
	mkdir -p $(HOME)/.vifm
	ln -s $(CWD)/vifm/vifmrc $(HOME)/.vifm/vifmrc
	ln -s $(CWD)/vifm/colors $(HOME)/.vifm/colors
	ln -s $(CWD)/vifm/scripts $(HOME)/.vifm/scripts

mc:
	ln -s $(CWD)/mc/skins $(HOME)/.local/share/mc/skins

mutt:
	mkdir -p $(HOME)/.mutt
	ln -s $(CWD)/mutt/muttrc $(HOME)/.mutt/muttrc
	ln -s $(CWD)/mutt/conf.d $(HOME)/.mutt/conf.d
	ln -s $(CWD)/mutt/accounts $(HOME)/.mutt/accounts

fonts:
	mkdir -p $(HOME)/.config/fontconfig
	ln -s $(CWD)/fonts.conf $(HOME)/.config/fontconfig/fonts.conf

bin:
	ln -s $(CWD)/bin $(HOME)/.bin

mpv:
	mkdir -p $(HOME)/.config/mpv
	ln -s $(CWD)/mpv.conf $(HOME)/.config/mpv/mpv.conf

rtorrent:
	mkdir -p $(HOME)/.rtorrent
	ln -s $(CWD)/rtorrent.rc $(HOME)/.rtorrent.rc

sxiv:
	ln -s $(CWD)/sxiv $(HOME)/.config/sxiv

ncspot:
	mkdir -p $(HOME)/.config/ncspot
	ln -s $(CWD)/ncspot.toml $(HOME)/.config/ncspot/config.toml

zathura:
	mkdir -p $(HOME)/.config/zathura
	ln -s $(CWD)/zathurarc $(HOME)/.config/zathura/zathurarc
