#!/bin/bash
#
# ~/.xinitrc
#
# Executed by startx (run your window manager from here)

# X settings
xgamma -gamma 0.8

# keyboard setting
xset r rate 220 25
setxkbmap -layout us,ru -option "grp:caps_toggle"
syndaemon -i 0.5 -t -K -R -d

feh --bg-scale ~/dev/dotfiles/walls/wall_f1.webp

# autostart
xset s 600 30
[ -n "$(pidof xss-lock)" ] || xss-lock -n /usr/libexec/xsecurelock/dimmer -l -- xsecurelock &
[ -n "$(pidof xbindkeys)" ] || xbindkeys

systemctl --user import-environment DISPLAY PATH
export XDG_DESKTOP_DIR="$HOME"
export XDG_DOWNLOAD_DIR="$HOME/tmp"

# Start WM
exec /usr/local/bin/slstatus &
exec /usr/local/bin/dwm
