.PHONY: etc dwl kanshi swayimg user-dirs email mutt weechat

CWD=$(shell pwd)

etc:
	sudo install -Dm644 $(CWD)/etc/polkit-1/rules.d/50-fprintd.rules /etc/polkit-1/rules.d/50-fprintd.rules
	sudo install -Dm644 $(CWD)/etc/pam.d/* /etc/pam.d/
	sudo install -Dm644 $(CWD)/etc/tlp.d/10-battery.conf /etc/tlp.d/10-battery.conf
	sudo install -Dm644 $(CWD)/etc/systemd/logind.conf.d/10-lid.conf /etc/systemd/logind.conf.d/10-lid.conf
	sudo install -Dm644 $(CWD)/etc/systemd/sleep.conf.d/10-suspend-then-hibernate.conf /etc/systemd/sleep.conf.d/10-suspend-then-hibernate.conf

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

alacritty:
	mkdir -p $(HOME)/.config/alacritty
	ln -sf $(CWD)/alacritty.toml $(HOME)/.config/alacritty/alacritty.toml

foot:
	mkdir -p $(HOME)/.config/foot
	ln -sf $(CWD)/foot/foot.ini $(HOME)/.config/foot/foot.ini

swayimg:
	mkdir -p $(HOME)/.config/swayimg
	ln -sf $(CWD)/swayimg/init.lua $(HOME)/.config/swayimg/init.lua

git:
	ln -sf $(CWD)/gitconfig $(HOME)/.gitconfig
	ln -sf $(CWD)/tigrc $(HOME)/.tigrc

shell:
	ln -sf $(CWD)/dir_colors $(HOME)/.dir_colors
	ln -sf $(CWD)/bash/bashrc $(HOME)/.bashrc
	ln -sf $(CWD)/bash/bash_profile $(HOME)/.bash_profile
	ln -sf $(CWD)/urlview $(HOME)/.urlview
	ln -sf $(CWD)/ripgreprc $(HOME)/.ripgreprc

user-dirs:
	mkdir -p $(HOME)/.config
	ln -sf $(CWD)/user-dirs.dirs $(HOME)/.config/user-dirs.dirs

dwl:
	mkdir -p $(HOME)/.config/dwl
	ln -sf $(CWD)/dwl/autostart $(HOME)/.config/dwl/autostart
	ln -sf $(CWD)/dwl/status $(HOME)/.config/dwl/status

kanshi:
	mkdir -p $(HOME)/.config/kanshi
	ln -sf $(CWD)/kanshi.config $(HOME)/.config/kanshi/config

fonts:
	mkdir -p $(HOME)/.config/fontconfig
	ln -sf $(CWD)/fonts.conf $(HOME)/.config/fontconfig/fonts.conf

dunst:
	mkdir -p $(HOME)/.config/dunst
	ln -sf $(CWD)/dunstrc $(HOME)/.config/dunst/dunstrc

agents:
	# ln -sf $(CWD)/claude-settings.json $(HOME)/.claude/settings.json
	mkdir -p $(HOME)/.pi/agent
	ln -sf $(CWD)/pi/settings.json $(HOME)/.pi/agent/settings.json
	ln -sf $(CWD)/pi/models.json $(HOME)/.pi/agent/models.json 
	ln -sf $(CWD)/pi/extensions $(HOME)/.pi/agent/extensions
	ln -sf $(CWD)/pi/skills $(HOME)/.pi/agent/skills

mutt:
	mkdir -p $(HOME)/.mutt
	ln -sf $(CWD)/mutt/muttrc $(HOME)/.mutt/muttrc
	ln -sf $(CWD)/mutt/conf.d $(HOME)/.mutt/conf.d
	ln -sf $(CWD)/mutt/accounts $(HOME)/.mutt/accounts

email:
	ln -sf $(CWD)/email/mbsyncrc $(HOME)/.mbsyncrc
	install $(CWD)/email/mbsync.service $(HOME)/.config/systemd/user/mbsync.service
	install $(CWD)/email/mbsync.timer $(HOME)/.config/systemd/user/mbsync.timer
	mkdir -p ~/.config/mirador
	ln -sf $(CWD)/email/mirador.toml ~/.config/mirador/config.toml
	install $(CWD)/email/mirador.service $(HOME)/.config/systemd/user/mirador.service

mpv:
	mkdir -p $(HOME)/.config/mpv
	ln -sf $(CWD)/mpv.conf $(HOME)/.config/mpv/mpv.conf
	ln -sf $(CWD)/mpv-input.conf $(HOME)/.config/mpv/input.conf

rtorrent:
	mkdir -p $(HOME)/.rtorrent
	ln -sf $(CWD)/rtorrent.rc $(HOME)/.rtorrent.rc

ncspot:
	mkdir -p $(HOME)/.config/ncspot
	ln -sf $(CWD)/ncspot.toml $(HOME)/.config/ncspot/config.toml

weechat:
	mkdir -p $(HOME)/.weechat/python/autoload $(HOME)/.weechat/themes
	ln -sf $(CWD)/weechat/*.conf $(HOME)/.weechat/
	ln -sf $(CWD)/weechat/weemoji.json $(HOME)/.weechat/weemoji.json
	ln -sf $(CWD)/weechat/python/*.py $(HOME)/.weechat/python/
	ln -sf ../autosort.py $(HOME)/.weechat/python/autoload/autosort.py
	ln -sf ../buffer_autoset.py $(HOME)/.weechat/python/autoload/buffer_autoset.py
	ln -sf ../edit.py $(HOME)/.weechat/python/autoload/edit.py
	ln -sf ../notify_send.py $(HOME)/.weechat/python/autoload/notify_send.py
	ln -sf ../slack.py $(HOME)/.weechat/python/autoload/slack.py
	ln -sf ../theme.py $(HOME)/.weechat/python/autoload/theme.py
	ln -sf $(CWD)/weechat/themes/gnkv.theme $(HOME)/.weechat/themes/gnkv.theme
