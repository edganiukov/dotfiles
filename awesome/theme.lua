--[[
    Awesome Theme configuration
--]]

local gears = require("gears")
local lain  = require("lain")
local awful = require("awful")
local wibox = require("wibox")
local dpi   = require("beautiful.xresources").apply_dpi

local os = os
local my_table = awful.util.table or gears.table -- 4.{0,1} compatibility

local theme                    = {}
theme.dir                      = os.getenv("HOME") .. "/.config/awesome"
theme.wallpaper                = theme.dir .. "/wall.png"
theme.font                     = "Source Code Pro, Inconsolata 9.5"
theme.fg_normal                = "#ebdbb2"
theme.fg_focus                 = "#EA6F81"
theme.fg_urgent                = "#CC9393"
theme.bg_normal                = "#1A1A1A"
theme.bg_focus                 = "#313131"
theme.bg_urgent                = "#1A1A1A"
theme.border_width             = dpi(2)
theme.border_normal            = "#3F3F3F"
theme.border_focus             = "#7F7F7F"
theme.border_marked            = "#CC9393"
theme.tasklist_bg_focus        = "#1A1A1A"
theme.titlebar_bg_focus        = theme.bg_focus
theme.titlebar_bg_normal       = theme.bg_normal
theme.titlebar_fg_focus        = theme.fg_focus
theme.menu_height              = dpi(20)
theme.menu_width               = dpi(140)
theme.tasklist_plain_task_name = true
theme.tasklist_disable_icon    = true
theme.useless_gap              = dpi(0)

theme.menu_awesome_icon = theme.dir .. "/icons/awesome.png"
theme.menu_submenu_icon = theme.dir .. "/icons/submenu.png"

theme.taglist_squares_sel   = theme.dir .. "/icons/square_sel.png"
theme.taglist_squares_unsel = theme.dir .. "/icons/square_unsel.png"
theme.layout_tile           = theme.dir .. "/icons/tile.png"
theme.layout_tileleft       = theme.dir .. "/icons/tileleft.png"
theme.layout_tilebottom     = theme.dir .. "/icons/tilebottom.png"
theme.layout_tiletop        = theme.dir .. "/icons/tiletop.png"
theme.layout_fairv          = theme.dir .. "/icons/fairv.png"
theme.layout_fairh          = theme.dir .. "/icons/fairh.png"
theme.layout_spiral         = theme.dir .. "/icons/spiral.png"
theme.layout_dwindle        = theme.dir .. "/icons/dwindle.png"
theme.layout_max            = theme.dir .. "/icons/max.png"
theme.layout_fullscreen     = theme.dir .. "/icons/fullscreen.png"
theme.layout_magnifier      = theme.dir .. "/icons/magnifier.png"
theme.layout_floating       = theme.dir .. "/icons/floating.png"

theme.titlebar_close_button_focus               = theme.dir .. "/icons/titlebar/close_focus.png"
theme.titlebar_close_button_normal              = theme.dir .. "/icons/titlebar/close_normal.png"
theme.titlebar_ontop_button_focus_active        = theme.dir .. "/icons/titlebar/ontop_focus_active.png"
theme.titlebar_ontop_button_normal_active       = theme.dir .. "/icons/titlebar/ontop_normal_active.png"
theme.titlebar_ontop_button_focus_inactive      = theme.dir .. "/icons/titlebar/ontop_focus_inactive.png"
theme.titlebar_ontop_button_normal_inactive     = theme.dir .. "/icons/titlebar/ontop_normal_inactive.png"
theme.titlebar_sticky_button_focus_active       = theme.dir .. "/icons/titlebar/sticky_focus_active.png"
theme.titlebar_sticky_button_normal_active      = theme.dir .. "/icons/titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_inactive     = theme.dir .. "/icons/titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_inactive    = theme.dir .. "/icons/titlebar/sticky_normal_inactive.png"
theme.titlebar_floating_button_focus_active     = theme.dir .. "/icons/titlebar/floating_focus_active.png"
theme.titlebar_floating_button_normal_active    = theme.dir .. "/icons/titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_inactive   = theme.dir .. "/icons/titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_inactive  = theme.dir .. "/icons/titlebar/floating_normal_inactive.png"
theme.titlebar_maximized_button_focus_active    = theme.dir .. "/icons/titlebar/maximized_focus_active.png"
theme.titlebar_maximized_button_normal_active   = theme.dir .. "/icons/titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_inactive  = theme.dir .. "/icons/titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_inactive = theme.dir .. "/icons/titlebar/maximized_normal_inactive.png"

local markup = lain.util.markup
local separators = lain.util.separators

-- Textclock
local clock = awful.widget.watch(
    "date +'%a %d %b %R'", 60,
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
    settings = function()
        widget:set_markup(markup.font(theme.font, "  " .. mem_now.perc .. "% "))
    end
})

-- CPU
local cpu = lain.widget.cpu({
    settings = function()
        widget:set_markup(markup.font(theme.font, "  " .. cpu_now.usage .. "% "))
    end
})

-- Coretemp
local temp = lain.widget.temp({
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
    timeout = 10,
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
    notify = "off",
    -- wifi_state = "on",
    units = 1024,
    settings = function()
        local net_info
        if net_now.state == "up" then
            net_info = markup("#7AC82E", "  ") ..
                -- net_now.devices["wlp3s0"].signal .. "dBm " ..
                " " .. net_now.received .. "kb " ..
                " " .. net_now.sent .. "kb "
        else
            net_info = markup("#FF0000", "  down ")
        end
        widget:set_markup(markup.font(theme.font, net_info))
    end
})

-- local email = lain.widget.imap({
--     timeout  = 120,
--     port     = 993,
--     server   = "imap.fastmail.com",
--     mail     = "",
--     password = function()
--         return retrieved_password, try_again
--     end,
--     settings = function()
--         widget:set_text(markup.font(theme.font("  " .. mailcount))
--     end
-- })

-- Separators
local spr     = wibox.widget.textbox(' ')
local arrl_dl = separators.arrow_left(theme.bg_focus, "alpha")
local arrl_ld = separators.arrow_left("alpha", theme.bg_focus)

function theme.at_screen_connect(s)
    -- Quake application
    s.quake = lain.util.quake({ app = awful.util.terminal })

    -- If wallpaper is a function, call it with the screen
    local wallpaper = theme.wallpaper
    if type(wallpaper) == "function" then
        wallpaper = wallpaper(s)
    end
    gears.wallpaper.maximized(wallpaper, s, true)

    -- Tags
    awful.tag(awful.util.tagnames, s, awful.layout.layouts)

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(
        my_table.join(
            awful.button({}, 1, function () awful.layout.inc(1) end),
            awful.button({}, 2, function () awful.layout.set(awful.layout.layouts[1]) end),
            awful.button({}, 3, function () awful.layout.inc(-1) end),
            awful.button({}, 4, function () awful.layout.inc( 1) end),
            awful.button({}, 5, function () awful.layout.inc(-1) end)
        ))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, awful.util.taglist_buttons)

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, awful.util.tasklist_buttons)

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

return theme
