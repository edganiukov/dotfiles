#!/bin/sh

alsa_volume() {
    ON=$(amixer get Master | awk -F'[][]' 'END{ print $6 }')
    VOL=$(amixer get Master | awk -F'[][]' 'END{ print $2 }')

    if [ "${ON}" == "on" ]; then
        echo "$VOL"
    else
        echo "0% M"
    fi
}

battery() {
    CAP=$(cat /sys/class/power_supply/BAT0/capacity)
    STATUS=$(cat /sys/class/power_supply/BAT0/status)

    if [ "${STATUS}" == "Charging" ]; then
        echo "+$CAP%"
    else
        echo "-$CAP%"
    fi
}

temp() {
    TEMP=$(cat /sys/devices/virtual/thermal/thermal_zone1/temp)

    echo "$((TEMP / 1000))°C"
}

datetime() {
    echo "$(date +'%a %d %b %R')"
}

while true; do
    xsetroot -name "< $(alsa_volume) < $(battery) < $(temp) < $(datetime) <"
    sleep 1
done
