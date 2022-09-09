.PHONY: nvim vim tmux git zsh x redshift bin dunst mutt isync
.PHONY: fonts mpv rtorrent sxiv zathura ncspot weechat

CWD=$(shell pwd)

nvim:
	mkdir -p ~/.config/nvim
	ln -s $(CWD)/nvim/init.lua $(HOME)/.config/nvim/init.lua
	ln -s $(CWD)/nvim/lua $(HOME)/.config/nvim/lua

vim:
	mkdir -p $(HOME)/.vim
	ln -s $(CWD)/vimrc $(HOME)/.vimrc
	curl -sfLo $(HOME)/.vim/autoload/plug.vim --create-dirs \
		https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

tmux:
	ln -s $(CWD)/tmux.conf $(HOME)/.tmux.conf
	mkdir -p $(HOME)/.tmux/plugins
	git clone https://github.com/tmux-plugins/tpm $(HOME)/.tmux/plugins/tpm
	# ln -s $(CWD)/tmuxp $(HOME)/.tmuxp

git:
	cp $(CWD)/gitconfig $(HOME)/.gitconfig

zsh:
	ln -s $(CWD)/dir_colors $(HOME)/.dir_colors
	mkdir $(HOME)/.zsh
	ln -s $(CWD)/zsh/zshrc $(HOME)/.zshrc
	ln -s $(CWD)/zsh/zshenv $(HOME)/.zshenv
	ln -s $(CWD)/zsh/zlogin $(HOME)/.zlogin
	ln -s $(CWD)/zsh/plugins $(HOME)/.zsh/plugins
	ln -s $(CWD)/zsh/func.zsh $(HOME)/.zsh/func.zsh

x:
	ln -s $(CWD)/Xresources $(HOME)/.Xresources
	ln -s $(CWD)/xinitrc $(HOME)/.xinitrc
	ln -s $(CWD)/xbindkeysrc $(HOME)/.xbindkeysrc
	ln -s $(CWD)/urlview $(HOME)/.urlview

fonts:
	mkdir -p $(HOME)/.config/fontconfig
	ln -s $(CWD)/fonts.conf $(HOME)/.config/fontconfig/fonts.conf

bin:
	mkdir -p $(HOME)/.local/bin
	ln -s $(CWD)/bin/dwm-status $(HOME)/.local/bin/

redshift:
	mkdir -p $(HOME)/.config/redshift
	ln -s $(CWD)/redshift.conf $(HOME)/.config/redshift/redshift.conf

dunst:
	mkdir -p $(HOME)/.config/dunst
	ln -s $(CWD)/dunstrc $(HOME)/.config/dunst/dunstrc

# email
mutt:
	mkdir -p $(HOME)/.mutt
	ln -s $(CWD)/mutt/muttrc $(HOME)/.mutt/muttrc
	ln -s $(CWD)/mutt/conf.d $(HOME)/.mutt/conf.d
	ln -s $(CWD)/mutt/accounts $(HOME)/.mutt/accounts

isync:
	ln -s $(CWD)/mbsync/mbsyncrc $(HOME)/.mbsyncrc
	#ln -s $(CWD)/mbsync/mbsync.service $(HOME)/.config/systemd/user/mbsync.service
	#ln -s $(CWD)/mbsync/mbsync.timer $(HOME)/.config/systemd/user/mbsync.timer

mpv:
	mkdir -p $(HOME)/.config/mpv
	ln -s $(CWD)/mpv.conf $(HOME)/.config/mpv/mpv.conf
	ln -s $(CWD)/mpv-input.conf $(HOME)/.config/mpv/input.conf

rtorrent:
	mkdir -p $(HOME)/.rtorrent
	ln -s $(CWD)/rtorrent.rc $(HOME)/.rtorrent.rc

sxiv:
	ln -s $(CWD)/sxiv $(HOME)/.config/sxiv

zathura:
	mkdir -p $(HOME)/.config/zathura
	ln -s $(CWD)/zathurarc $(HOME)/.config/zathura/zathurarc

ncspot:
	mkdir -p $(HOME)/.config/ncspot
	ln -s $(CWD)/ncspot.toml $(HOME)/.config/ncspot/config.toml

weechat:
	ln -s $(CWD)/weechat $(HOME)/.weechat
