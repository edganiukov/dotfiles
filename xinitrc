#!/bin/sh
#
# ~/.xinitrc
#
# Executed by startx (run your window manager from here)


# X settings
xrdb -merge .Xresources &&
xgamma -gamma 0.8

xbindkeys
# keyboard setting
setxkbmap -layout us,ru -option 'grp:caps_toggle'
# key repeat
xset r rate 200 20

# autostart
nm-applet &
xautolock -time 10 -corners 00-- -locker 'i3lock -n -c 282828' &
# brightnessctl -r &
# spotifyd --config=~/.config/spotifyd/spotifyd.conf &

# ENV vars
systemctl --user import-environment DISPLAY

# Let QT and GTK autodetect retina screen and autoadjust
export QT_SCREEN_SCALE_FACTORS=1.5
export GDK_DPI_SCALE=1

feh --bg-scale ~/dev/dotfiles/wall.png

# Start WM
# exec awesome
# exec i3
# slstatus &
dwm-status &
while true; do
    dwm 2> ~/.dwm.log
done
