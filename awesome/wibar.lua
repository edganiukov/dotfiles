--[[
-- Awesome WM status bar config
--]]

local gears = require("gears")
local lain  = require("lain")
local awful = require("awful")
local wibox = require("wibox")
local markup = lain.util.markup
local separators = lain.util.separators

local os    = os
local dpi   = require("beautiful.xresources").apply_dpi
local table = awful.util.table or gears.table -- 4.{0,1} compatibility

local theme = require("theme")

-- Textclock
local clock = awful.widget.watch(
    "date +'%a %d %b %R'", 10,
    function(widget, stdout)
        widget:set_markup("  " .. markup.font(theme.font, stdout))
    end
)

-- Calendar
theme.cal = lain.widget.cal({
    attach_to = { clock },
    notification_preset = {
        font = theme.font,
        fg   = theme.fg_normal,
        bg   = theme.bg_normal
    }
})

-- MEM
local mem = lain.widget.mem({
    timeout = 1,
    settings = function()
        widget:set_markup(markup.font(theme.font, "  " .. mem_now.used .. "MB "))
    end
})

-- CPU
local cpu = lain.widget.cpu({
    timeout = 1,
    settings = function()
        widget:set_markup(markup.font(theme.font, "  " .. cpu_now.usage .. "% "))
    end
})

-- Coretemp
local temp = lain.widget.temp({
    timeout = 1,
    tempfile = "/sys/devices/virtual/thermal/thermal_zone1/temp",
    settings = function()
        local core_temp = "  " .. coretemp_now .. "°C "
        if coretemp_now > 75 then
            core_temp = markup("#FF0000", core_temp)
        end
        widget:set_markup(markup.font(theme.font,  core_temp))
    end
})

-- / fs
theme.fs = lain.widget.fs({
    timeout = 5,
    notification_preset = {
        fg = theme.fg_normal,
        bg = theme.bg_normal,
        font = theme.font,
    },
    settings = function()
        widget:set_markup(markup.font(theme.font, "  home: " .. fs_now["/home"].percentage .. "% "))
    end
})

-- Battery
local bat = lain.widget.bat({
    timeout = 5,
    settings = function()
        local bat_icon
        if bat_now.ac_status == 1 then
            bat_icon = ""
        else
            bat_icon = ""
        end
        widget:set_markup(markup.font(theme.font, " " .. bat_icon .. " " .. bat_now.perc .. "% " .. bat_now.time .. " "))
    end
})

-- Pulseaudio volume
theme.volume = lain.widget.pulse {
    timeout = 1,
    settings = function()
        local vlevel
        if volume_now.muted == "yes" then
            vlevel = "  0% "
        else
            vlevel = "   " .. volume_now.left .. "% "
        end
        widget:set_markup(vlevel)
    end
}

-- Net
local net = lain.widget.net({
    timeout = 1,
    notify = "off",
    -- wifi_state = "on",
    units = 1024,
    settings = function()
        local net_info
        if net_now.state == "up" then
            net_info = markup("#7AC82E", "  ") ..
                -- net_now.devices["wlp3s0"].signal .. "dBm " ..
                " " .. net_now.received .. "kb " ..
                " " .. net_now.sent .. "kb "
        else
            net_info = markup("#FF0000", "  down ")
        end
        widget:set_markup(markup.font(theme.font, net_info))
    end
})

-- local email = lain.widget.imap{
--     timeout  = 60,
--     pwdtimeout = 1,
--     port     = 993,
--     is_plain = false,
--     server   = "imap.fastmail.com",
--     mail     = "ed@gnkv.io",
--     password = function()
--         local pass = ""
--         awful.spawn.easy_async("gopass show core/imap.fastmail.com", function(out)
--             pass = out
--         end)
--         print("pass1: " .. pass)
--         return pass, false
--     end,
--     settings = function()
--         mail_notification_preset.position = "top_right"
--         widget:set_markup(markup.font(theme.font, "  " .. mailcount .. " "))
--     end
-- }

-- Separators
local spr     = wibox.widget.textbox(' ')
local arrl_dl = separators.arrow_left(theme.bg_focus, "alpha")
local arrl_ld = separators.arrow_left("alpha", theme.bg_focus)

local wibar = {}
function wibar.at_screen_connect(s)
    -- If wallpaper is a function, call it with the screen
    local wallpaper = theme.wallpaper
    if type(wallpaper) == "function" then
        wallpaper = wallpaper(s)
    end
    gears.wallpaper.maximized(wallpaper, s, true)

    -- Tags
    awful.tag(awful.util.tagnames, s, awful.layout.layouts)

    -- Create a promptbox for each screen
    -- s.mypromptbox = awful.widget.prompt()

    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(
        table.join(
            awful.button({}, 1, function () awful.layout.inc(1) end),
            awful.button({}, 2, function () awful.layout.set(awful.layout.layouts[1]) end),
            awful.button({}, 3, function () awful.layout.inc(-1) end),
            awful.button({}, 4, function () awful.layout.inc( 1) end),
            awful.button({}, 5, function () awful.layout.inc(-1) end)
        ))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, awful.util.taglist_buttons)

    -- Create a tasklist widget
    -- s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, awful.util.tasklist_buttons)

    -- Create the wibox
    s.mywibox = awful.wibar({
        position = "top",
        screen = s,
        height = dpi(20),
        bg = theme.bg_normal,
        fg = theme.fg_normal,
    })

    -- Keyboard map indicator and switcher
    s.mykeyboardlayout = awful.widget.keyboardlayout()

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            mylauncher,
            spr,
            s.mytaglist,
            s.mypromptbox,
            spr,
        },
        spr,
        -- s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            wibox.widget.systray(),
            spr,
            arrl_ld,
            -- wibox.container.background(email.widget, theme.bg_focus),
            arrl_dl,
            s.mykeyboardlayout,
            arrl_ld,
            wibox.container.background(theme.volume.widget, theme.bg_focus),
            arrl_dl,
            bat.widget,
            arrl_ld,
            wibox.container.background(net.widget, theme.bg_focus),
            arrl_dl,
            temp.widget,
            arrl_ld,
            wibox.container.background(cpu.widget, theme.bg_focus),
            arrl_dl,
            mem.widget,
            arrl_ld,
            wibox.container.background(theme.fs.widget, theme.bg_focus),
            arrl_dl,
            clock,
            spr,
            arrl_ld,
            wibox.container.background(s.mylayoutbox, theme.bg_focus),
        },
    }
end

return wibar
