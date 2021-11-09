#!/bin/bash
#
# ~/.xinitrc
#
# Executed by startx (run your window manager from here)

# X settings
xrdb -merge .Xresources &&
xgamma -gamma 0.8

# keyboard setting
xset r rate 200 20
setxkbmap -layout us,ru -option 'grp:caps_toggle'
gpgconf --launch gpg-agent

feh --bg-scale ~/dev/dotfiles/walls/wall_f1.webp

# autostart
[ -n "$(pidof xautolock)" ] || xautolock -time 10 -corners 00-- -locker 'i3lock -n -c 282828' &
[ -n "$(pidof xbindkeys)" ] || xbindkeys
[ -n "$(pidof redshift)" ] || redshift &
# [ -n "$(pidof syncthing)" ] || syncthing &
[ -n "$(pidof dunst)" ] || dunst &

export LIBSEAT_BACKEND=logind
# Start WM
exec dbus-launch --exit-with-session ~/.local/bin/dwm-start
