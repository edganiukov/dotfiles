#!/bin/sh

INTERVAL=1
BAT="$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1)"

get_layout() {
    raw=$(swaymsg -t get_inputs -r | jq -r '[.[] | select(.type=="keyboard")][0].xkb_active_layout_name // "?"')
    case "$raw" in
        "English (US)") echo "us" ;;
        "Ukrainian")    echo "ua" ;;
        *)              echo "$raw" ;;
    esac
}

get_battery() {
    if [ -n "$BAT" ]; then
        cap=$(cat "$BAT/capacity" 2>/dev/null)
        status=$(cat "$BAT/status" 2>/dev/null)
        case "$status" in
            Charging)               sym="+" ;;
            Discharging)            sym="-" ;;
            "Not charging"|Full)    sym="~" ;;
            *)                      sym="?" ;;
        esac
        echo "${sym}${cap}%"
    else
        echo "no battery"
    fi
}

get_volume() {
    state=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null) || {
        echo "?"
        return
    }
    level=$(printf '%s\n' "$state" | awk '{ printf "%.0f", $2 * 100 }')
    case "$state" in
        *"[MUTED]"*) echo "${level}%M" ;;
        *)           echo "${level}%" ;;
    esac
}

get_time() {
    date +'%a %d %b %R'
}

while true; do
    printf '%s < Þ %s < %s < %s\n' "$(get_layout)" "$(get_volume)" "$(get_battery)" "$(get_time)"
    sleep "$INTERVAL"
done

