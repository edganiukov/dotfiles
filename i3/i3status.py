from i3pystatus import Status

def markup(fg, bg, text):
    if fg != "":
        return "<span background='"+bg+"' foreground='"+fg+"'>"+text+"</span>"
    else:
        return "<span background='"+bg+"'>"+text+"</span>"

text="#EBDBB2"
light='#383838'
dark='#282828'
red="#FF0000"
green="#00FF00"

status = Status(logfile='/tmp/i3pystatus.log')

status.register("text",
    hints={"markup": "pango", "separator": False, "separator_block_width": 0},
    text=markup(dark, light, ""),
)

## Clock
status.register("clock",
    hints={"markup": "pango", "separator": False, "separator_block_width": 0},
    format=markup(text, light, "  %a %d %b %R "),
    interval=1,
)
status.register("text",
    hints={"markup": "pango", "separator": False, "separator_block_width": 0},
    text=markup(light, dark, ""),
)

## CPU usage
status.register("cpu_usage",
    hints={"markup": "pango", "separator": False, "separator_block_width": 0},
    dynamic_color=True,
    format=markup(text, dark, "  {usage:02}% "),
)
status.register("text",
    hints={"markup": "pango", "separator": False, "separator_block_width": 0},
    text=markup(dark, light, ""),
)

## Core Temperature
status.register("temp",
    hints={"markup": "pango", "separator": False, "separator_block_width": 0},
    dynamic_color=True,
    file="/sys/class/thermal/thermal_zone1/temp",
    format=markup("", light, "  {temp}°C "),
)
status.register("text",
    hints={"markup": "pango", "separator": False, "separator_block_width": 0},
    text=markup(light, dark, ""),
)

## Battery
status.register('battery',
    hints={"markup": "pango", "separator": False, "separator_block_width": 0},
    interval=1,
    format=markup(text, dark, " {status} ") + markup("", dark, "{percentage:.2f}% "),
    alert=True,
    alert_percentage=10,
    critical_level_command="systemctl suspend",
    critical_level_percentage=1,
    status={
        'DPL': '',
        'CHR': '',
        'DIS': '',
        'FULL': '',
    }
)
status.register("text",
    hints={"markup": "pango", "separator": False, "separator_block_width": 0},
    text=markup(dark, light, ""),
)

## Wifi
status.register("network",
    hints={"markup": "pango", "separator": False, "separator_block_width": 0},
    dynamic_color=True,
    interface="wlp3s0",
    separate_color=False,
    # format_up=markup("", light, "  ")+ markup(text, light, "  {bytes_recv}KB/s  {bytes_sent}KB/s "),
    format_up=markup("", light, "  ")+ markup(text, light, "{essid} "),
    format_down=markup(red, light, "  down "),
)
status.register("text",
    hints={"markup": "pango", "separator": False, "separator_block_width": 0},
    text=markup(light, dark, ""),
)

## Audio
status.register("pulseaudio",
    hints={"markup": "pango", "separator": False, "separator_block_width": 0},
    format=markup(text, dark, "  {volume}% "),
    format_muted=markup(red, dark, "  0% "),
    on_leftclick="pactl set-sink-mute @DEFAULT_SINK@ toggle"
)
status.register("text",
    hints={"markup": "pango", "separator": False, "separator_block_width": 0},
    text=markup(dark, light, ""),
)

## Screen backlight
status.register("backlight",
    hints={"markup": "pango", "separator": False, "separator_block_width": 0},
    interval=1,
    base_path="/sys/class/backlight/acpi_video0/",
    format=markup(text, light, "  {brightness} "),
)
status.register("text",
    hints={"markup": "pango", "separator": False, "separator_block_width": 0},
    text=markup(light, dark, ""),
)

## Keyboard laouyt
status.register("xkblayout",
    hints={"markup": "pango", "separator": False, "separator_block_width": 0},
    layouts=["us", "ru"],
    uppercase=False,
    format=markup(text, dark, " {symbol} "),
)
status.register("text",
    hints={"markup": "pango", "separator": False, "separator_block_width": 0},
    text=markup(dark, light, ""),
)

##
status.register("text",
    hints={"markup": "pango", "separator": False, "separator_block_width": 0},
    text=markup(light, dark, ""),
)

status.run()
