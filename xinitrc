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
xset r rate 150 20

# Start WM
# exec awesome
exec i3
