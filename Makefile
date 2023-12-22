.PHONY: nvim vim tmux git zsh x gtk redshift bin dunst mutt himalaya
.PHONY: fonts mpv rtorrent sxiv zathura ncspot weechat
.PHONY: system76

CWD=$(shell pwd)

nvim:
	mkdir -p ~/.config/nvim
	ln -sf $(CWD)/nvim/init.lua $(HOME)/.config/nvim/init.lua
	ln -sf $(CWD)/nvim/lua $(HOME)/.config/nvim/lua

vim:
	mkdir -p $(HOME)/.vim
	ln -sf $(CWD)/vimrc $(HOME)/.vimrc
	curl -sfLo $(HOME)/.vim/autoload/plug.vim --create-dirs \
		https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

tmux:
	ln -sf $(CWD)/tmux.conf $(HOME)/.tmux.conf
	mkdir -p $(HOME)/.tmux/plugins
	git clone https://github.com/tmux-plugins/tpm $(HOME)/.tmux/plugins/tpm

git:
	cp $(CWD)/gitconfig $(HOME)/.gitconfig

zsh:
	ln -sf $(CWD)/dir_colors $(HOME)/.dir_colors
	mkdir $(HOME)/.zsh
	ln -sf $(CWD)/zsh/zshrc $(HOME)/.zshrc
	ln -sf $(CWD)/zsh/zshenv $(HOME)/.zshenv
	ln -sf $(CWD)/zsh/zlogin $(HOME)/.zlogin
	ln -sf $(CWD)/zsh/plugins $(HOME)/.zsh/plugins
	ln -sf $(CWD)/zsh/func.zsh $(HOME)/.zsh/func.zsh

x:
	ln -sf $(CWD)/Xresources $(HOME)/.Xresources
	ln -sf $(CWD)/xinitrc $(HOME)/.xinitrc
	ln -sf $(CWD)/xbindkeysrc $(HOME)/.xbindkeysrc
	ln -sf $(CWD)/urlview $(HOME)/.urlview

gtk:
	mkdir -p ~/.config/gtk-3.0
	ln -sf $(CWD)/settings.ini $(HOME)/.config/gtk-3.0/settings.ini

fonts:
	mkdir -p $(HOME)/.config/fontconfig
	ln -sf $(CWD)/fonts.conf $(HOME)/.config/fontconfig/fonts.conf

bin:
	mkdir -p $(HOME)/.local/bin
	ln -sf $(CWD)/bin/dwm-status $(HOME)/.local/bin/

redshift:
	mkdir -p $(HOME)/.config/redshift
	ln -sf $(CWD)/redshift.conf $(HOME)/.config/redshift/redshift.conf

dunst:
	mkdir -p $(HOME)/.config/dunst
	ln -sf $(CWD)/dunstrc $(HOME)/.config/dunst/dunstrc

# email
mutt:
	mkdir -p $(HOME)/.mutt
	ln -sf $(CWD)/mutt/muttrc $(HOME)/.mutt/muttrc
	ln -sf $(CWD)/mutt/conf.d $(HOME)/.mutt/conf.d
	ln -sf $(CWD)/mutt/accounts $(HOME)/.mutt/accounts

himalaya:
	mkdir -p ~/.config/himalaya
	ln -sf $(CWD)/himalaya.toml ~/.config/himalaya/config.toml
	ln -sf $(CWD)/mbsyncrc $(HOME)/.mbsyncrc

mpv:
	mkdir -p $(HOME)/.config/mpv
	ln -sf $(CWD)/mpv.conf $(HOME)/.config/mpv/mpv.conf
	ln -sf $(CWD)/mpv-input.conf $(HOME)/.config/mpv/input.conf

rtorrent:
	mkdir -p $(HOME)/.rtorrent
	ln -sf $(CWD)/rtorrent.rc $(HOME)/.rtorrent.rc

sxiv:
	ln -sf $(CWD)/sxiv $(HOME)/.config/sxiv

zathura:
	mkdir -p $(HOME)/.config/zathura
	ln -sf $(CWD)/zathurarc $(HOME)/.config/zathura/zathurarc

ncspot:
	mkdir -p $(HOME)/.config/ncspot
	ln -sf $(CWD)/ncspot.toml $(HOME)/.config/ncspot/config.toml

weechat:
	ln -sf $(CWD)/weechat $(HOME)/.weechat


grobi:
	ln -sf $(CWD)/grobi.conf $(HOME)/.config/grobi.conf

system76:
	sudo cp $(CWD)/system76/system76-power.service /etc/systemd/system
