#!/bin/bash
#
# ~/.xinitrc
#
# Executed by startx (run your window manager from here)

# X settings
xrdb -merge .Xresources &&
xgamma -gamma 0.8

# keyboard setting
xset r rate 220 25
setxkbmap -layout us,ru -option "grp:caps_toggle"
syndaemon -i 0.5 -t -K -R -d

gpgconf --launch gpg-agent

feh --bg-scale ~/dev/dotfiles/walls/wall_f1.webp

# autostart
xset s 600 30
[ -n "$(pidof xss-lock)" ] || xss-lock -n /usr/libexec/xsecurelock/dimmer -l -- xsecurelock &
[ -n "$(pidof xbindkeys)" ] || xbindkeys
[ -n "$(pidof redshift)" ] || redshift &
[ -n "$(pidof dunst)" ] || dunst &

export LIBSEAT_BACKEND=logind
export XDG_DESKTOP_DIR="$HOME"
export XDG_DOWNLOAD_DIR="$HOME/tmp"

# Start WM
exec pipewire-pulse &
exec ~/.local/bin/dwm-status &
exec dbus-launch --exit-with-session /usr/local/bin/dwm
