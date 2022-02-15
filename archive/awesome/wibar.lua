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
        widget:set_markup(" " .. markup.font(theme.font, stdout) .. " ")
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

-- Coretemp
local tempicon = wibox.widget.imagebox(theme.widget_temp)
local temp = lain.widget.temp({
    timeout = 1,
    tempfile = "/sys/devices/virtual/thermal/thermal_zone1/temp",
    settings = function()
        local core_temp = coretemp_now .. "°C "
        if coretemp_now > 75 then
            core_temp = markup("#FF0000", core_temp)
        end
        widget:set_markup(markup.font(theme.font, " " .. core_temp))
    end
})

-- Battery
local baticon = wibox.widget.imagebox(theme.widget_battery)
local bat = lain.widget.bat({
    timeout = 5,
    settings = function()
        if bat_now.status and bat_now.status ~= "N/A" then
            if bat_now.ac_status == 1 then
                baticon:set_image(theme.widget_ac)
            elseif not bat_now.perc and tonumber(bat_now.perc) <= 10 then
                baticon:set_image(theme.widget_battery_empty)
            elseif not bat_now.perc and tonumber(bat_now.perc) <= 20 then
                baticon:set_image(theme.widget_battery_low)
            else
                baticon:set_image(theme.widget_battery)
            end
            widget:set_markup(markup.font(theme.font, " " .. bat_now.perc .. "% "))
        else
            widget:set_markup(markup.font(theme.font, " AC "))
            baticon:set_image(theme.widget_ac)
        end
    end
})

-- Alsa volume
local volicon = wibox.widget.imagebox(theme.widget_vol)
theme.volume = lain.widget.alsa({
    timeout = 1,
    settings = function()
        if volume_now.status == "off" then
            volicon:set_image(theme.widget_vol_mute)
        elseif tonumber(volume_now.level) == 0 then
            volicon:set_image(theme.widget_vol_no)
        elseif tonumber(volume_now.level) <= 50 then
            volicon:set_image(theme.widget_vol_low)
        else
            volicon:set_image(theme.widget_vol)
        end
        widget:set_markup(markup.font(theme.font, " " .. volume_now.level .. "% "))
    end
})

local pass = ""
awful.spawn.easy_async("pass show core/imap.fastmail.com", function(stdout, stderr, reason, exit_code)
    pass = stdout
end)

local mailicon = wibox.widget.imagebox(theme.widget_mail)
local mail = lain.widget.imap{
    timeout  = 15,
    pwdtimeout = 5,
    port     = 993,
    is_plain = false,
    -- server   = "",
    -- mail     = "",
    password = function()
        local try_again = false
        if pass == "" then
            try_again = true
        end
        return pass, try_again
    end,
    settings = function()
        mail_notification_preset.position = "top_right"
        if mailcount > 0 then
            mailicon:set_image(theme.widget_mail_on)
        else
            mailicon:set_image(theme.widget_mail)
        end
        widget:set_markup(markup.font(theme.font, " " .. mailcount .. " "))
    end
}

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
    awful.tag(awful.util.tagnames, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()

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
        height = dpi(14),
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
            -- spare
            arrl_dl,
            s.mykeyboardlayout,
            arrl_ld,
            wibox.container.background(mailicon, theme.bg_focus),
            wibox.container.background(mail.widget, theme.bg_focus),
            arrl_dl,
            volicon,
            theme.volume.widget,
            arrl_ld,
            wibox.container.background(baticon, theme.bg_focus),
            wibox.container.background(bat.widget, theme.bg_focus),
            arrl_dl,
            clock,
            spr,
            arrl_ld,
            wibox.container.background(s.mylayoutbox, theme.bg_focus),
        },
    }
end

return wibar
