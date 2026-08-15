.PHONY: bash vim nvim tmux screen git x fonts gtk redshift dunst grobi ripgrep
.PHONY: mpv rtorrent sxiv zathura ncspot weechat mutt email ghostty
.PHONY: system76 qutebrowser alacritty bin sway

CWD=$(shell pwd)

bin:
	mkdir -p $(HOME)/.local/bin
	ln -sf $(CWD)/bin/ccs $(HOME)/.local/bin/ccs

nvim:
	mkdir -p ~/.config/nvim
	ln -sf $(CWD)/nvim/init.lua $(HOME)/.config/nvim/init.lua
	ln -sfn $(CWD)/nvim/colors $(HOME)/.config/nvim/colors

vim:
	mkdir -p $(HOME)/.vim
	ln -sf $(CWD)/vim/vimrc $(HOME)/.vimrc
	ln -sf $(CWD)/vim/colors $(HOME)/.vim/colors
	curl -sfLo $(HOME)/.vim/autoload/plug.vim --create-dirs \
		https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

tmux:
	ln -sf $(CWD)/tmux.conf $(HOME)/.tmux.conf
	ln -sf $(CWD)/tmux $(HOME)/.tmux

screen:
	ln -sf $(CWD)/screenrc $(HOME)/.screenrc

ghostty:
	ln -sf $(CWD)/ghostty $(HOME)/.config/

alacritty:
	mkdir -p $(HOME)/.config/alacritty
	ln -sf $(CWD)/alacritty.toml $(HOME)/.config/alacritty/alacritty.toml

git:
	ln -sf $(CWD)/gitconfig $(HOME)/.gitconfig
	ln -sf $(CWD)/tigrc $(HOME)/.tigrc

bash:
	ln -sf $(CWD)/dir_colors $(HOME)/.dir_colors
	ln -sf $(CWD)/bash/bashrc $(HOME)/.bashrc
	ln -sf $(CWD)/bash/bash_profile $(HOME)/.bash_profile

x:
	ln -sf $(CWD)/Xresources $(HOME)/.Xresources
	ln -sf $(CWD)/xinitrc $(HOME)/.xinitrc
	ln -sf $(CWD)/xbindkeysrc $(HOME)/.xbindkeysrc
	ln -sf $(CWD)/urlview $(HOME)/.urlview
	ln -sf $(CWD)/smm.conf $(HOME)/.config/smm.conf

sway:
	mkdir -p $(HOME)/.config/sway
	ln -sf $(CWD)/sway/config $(HOME)/.config/sway/config

gtk:
	mkdir -p ~/.config/gtk-3.0
	ln -sf $(CWD)/gtk3-settings.ini $(HOME)/.config/gtk-3.0/settings.ini

fonts:
	mkdir -p $(HOME)/.config/fontconfig
	ln -sf $(CWD)/fonts.conf $(HOME)/.config/fontconfig/fonts.conf

redshift:
	mkdir -p $(HOME)/.config/redshift
	ln -sf $(CWD)/redshift.conf $(HOME)/.config/redshift/redshift.conf

dunst:
	mkdir -p $(HOME)/.config/dunst
	ln -sf $(CWD)/dunstrc $(HOME)/.config/dunst/dunstrc

agents:
	ln -sf $(CWD)/claude-settings.json $(HOME)/.claude/settings.json
	ln -sf $(CWD)/pi/settings.json $(HOME)/.pi/agent/settings.json
	ln -sf $(CWD)/pi/extensions $(HOME)/.pi/agent/extensions/
	ln -sf $(CWD)/pi/skills $(HOME)/.pi/agent/skills/

# email
mutt:
	mkdir -p $(HOME)/.mutt
	ln -sf $(CWD)/mutt/muttrc $(HOME)/.mutt/muttrc
	ln -sf $(CWD)/mutt/conf.d $(HOME)/.mutt/conf.d
	ln -sf $(CWD)/mutt/accounts $(HOME)/.mutt/accounts

email:
	ln -sf $(CWD)/email/mbsyncrc $(HOME)/.mbsyncrc
	cp $(CWD)/email/mbsync.service $(HOME)/.config/systemd/user/mbsync.service
	cp $(CWD)/email/mbsync.timer $(HOME)/.config/systemd/user/mbsync.timer
	mkdir -p ~/.config/mirador
	ln -sf $(CWD)/email/mirador.toml ~/.config/mirador/config.toml
	cp $(CWD)/email/mirador.service $(HOME)/.config/systemd/user/mirador.service
	# mkdir -p ~/.config/neverest
	# ln -sf $(CWD)/email/neverest.toml ~/.config/neverest/config.toml

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

ripgrep:
	ln -sf $(CWD)/ripgreprc $(HOME)/.ripgreprc

qutebrowser:
	ln -s $(CWD)/qutebrowser/config.py $(HOME)/.config/qutebrowser/config.py
