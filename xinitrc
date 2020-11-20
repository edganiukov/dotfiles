#!/bin/bash
#
# ~/.xinitrc
#
# Executed by startx (run your window manager from here)

# X settings
xrdb -merge .Xresources &&
xgamma -gamma 0.8

xbindkeys # keyboard setting
setxkbmap -layout us,ru -option 'grp:caps_toggle'
# key repeat
xset r rate 200 20

# export QT_FONT_DPI=96
# export GDK_DPI_SCALE=0.8
# export QT_AUTO_SCREEN_SCALE_FACTOR=1

feh --bg-scale ~/dev/dotfiles/wall_f1_vettel.webp

# autostart
xautolock -time 10 -corners 00-- -locker 'i3lock -n -c 282828' &
redshift &
dunst &
nm-applet &
syncthing &
# mopidy &

## Start WM
# exec slstatus
dwm-status &
exec dwm
# while true; do
#     dwm 2> ~/.dwm.log
# done
