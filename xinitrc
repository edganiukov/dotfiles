#!/bin/sh
#
# ~/.xinitrc
#
# Executed by startx (run your window manager from here)

# X settings
xrdb -merge .Xresources &&

# Start WM
exec awesome
