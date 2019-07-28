#!/bin/sh
#
# ~/.xinitrc
#
# Executed by startx (run your window manager from here)

# X settings
xrdb -merge .Xresources &&
xgamma -gamma 0.8

# keyboard layout
setxkbmap -layout us,ru -option 'grp:caps_toggle'

# key repeat
xset r rate 200 20

# Let QT and GTK autodetect retina screen and autoadjust
# export QT_AUTO_SCREEN_SCALE_FACTOR=1
# export GDK_SCALE=2
# export GDK_DPI_SCALE=0.5

# Start WM
# exec awesome
exec i3
