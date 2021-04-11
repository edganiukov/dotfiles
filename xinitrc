#!/bin/bash
#
# ~/.xinitrc
#
# Executed by startx (run your window manager from here)

# X settings
xrdb -merge .Xresources &&
xgamma -gamma 0.8
 # keyboard setting
setxkbmap -layout us,ru -option 'grp:caps_toggle'
# key repeat
xset r rate 200 20

systemctl --user import-environment DISPLAY
wmname compiz

gpgconf --launch gpg-agent

# export QT_FONT_DPI=96
# export GDK_DPI_SCALE=0.8
# export QT_AUTO_SCREEN_SCALE_FACTOR=1

feh --bg-scale ~/dev/dotfiles/walls/wall_f1.webp

# autostart
[ -n "$(pidof xautolock)" ] || xautolock -time 10 -corners 00-- -locker 'i3lock -n -c 282828' &
[ -n "$(pidof xbindkeys)" ] || xbindkeys
[ -n "$(pidof redshift)" ] || redshift &
[ -n "$(pidof syncthing)" ] || syncthing &

# [ -n "$(pidof dunst)" ] || dunst &
# [ -n "$(pidof nm-applet)" ] || nm-applet &

## Start WM
# exec slstatus
[ -n "$(pidof dwm-status)" ] || dwm-status &
exec dwm
# while true; do
#     dwm 2> ~/.dwm.log
# done
