.PHONY: alacritty rofi qutebrowser vifm mc i3 awesome xmonad luakit lf

CWD=$(shell pwd)

alacritty:
	mkdir -p $(HOME)/.config/alacritty
	ln -s $(CWD)/alacritty.yml $(HOME)/.config/alacritty/alacritty.yml
# wm
awesome:
	ln -s $(CWD)/awesome $(HOME)/.config/awesome

i3:
	ln -s $(CWD)/i3 $(HOME)/.config/i3

xmonad:
	mkdir -p $(HOME)/.xmonad
	ln -s $(CWD)/xmonad/xmonad.hs $(HOME)/.xmonad/xmonad.hs
	ln -s $(CWD)/xmonad/xmobarrc $(HOME)/.xmobarrc

rofi:
	mkdir -p $(HOME)/.config/rofi
	ln -s $(CWD)/rofi.conf $(HOME)/.config/rofi/config

# browsers
qutebrowser:
	ln -s $(CWD)/qutebrowser/config.py $(HOME)/.config/qutebrowser/config.py

luakit:
	mkdir -p $(HOME)/.config/luakit
	ln -s $(CWD)/luakit/userconf.lua $(HOME)/.config/luakit/userconf.lua

# file managers
vifm:
	mkdir -p $(HOME)/.vifm
	ln -s $(CWD)/vifm/vifmrc $(HOME)/.vifm/vifmrc
	ln -s $(CWD)/vifm/colors $(HOME)/.vifm/colors
	ln -s $(CWD)/vifm/scripts $(HOME)/.vifm/scripts

mc:
	ln -s $(CWD)/mc/skins $(HOME)/.local/share/mc/skins
	ln -s $(CWD)/mc/mc.keymap $(HOME)/.config/mc/mc.keymap

lf:
	mkdir -p $(HOME)/.config/lf
	ln -s $(CWD)/lfrc $(HOME)/.config/lf/lfrc
msmtp:
	ln -s $(CWD)/msmtprc $(HOME)/.msmtprc

ncspot:
	mkdir -p $(HOME)/.config/ncspot
	ln -s $(CWD)/ncspot.toml $(HOME)/.config/ncspot/config.toml
