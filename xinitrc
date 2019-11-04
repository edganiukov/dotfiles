#!/bin/sh
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

# autostart
nm-applet &
dbus-launch thunar --daemon &
xautolock -time 10 -locker 'i3lock -n -c 708090' &
brightnessctl -r &
# spotifyd --config=~/.config/spotifyd/spotifyd.conf &

# ENV vars
systemctl --user import-environment DISPLAY

# Let QT and GTK autodetect retina screen and autoadjust
# export QT_AUTO_SCREEN_SCALE_FACTOR=1
# export QT_SCALE_FACTOR=1.5
export QT_SCREEN_SCALE_FACTORS=1.5
# export GDK_SCALE=2
# export GDK_DPI_SCALE=0.5

# Start WM
# exec awesome
exec i3
