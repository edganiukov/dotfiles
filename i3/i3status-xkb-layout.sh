#!/bin/sh
# shell script to prepend i3status with keyboard layout

i3status -c ~/.config/i3/i3status.conf | while :
do
    read line
    echo "$(xkb-switch)  $line" || exit 1
done
