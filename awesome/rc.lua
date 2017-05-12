-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local hotkeys_popup = require("awful.hotkeys_popup").widget
-- Widgets
local lain = require("lain")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}


-- {{{ Autostart applications
-- Java Fix
awful.util.spawn_with_shell("wmname Sawfish")

function run_once(cmd)
   findme = cmd
   firstspace = cmd:find(" ")
   if firstspace then
      findme = cmd:sub(0, firstspace-1)
   end
   awful.util.spawn_with_shell("pgrep -u $USER -x " .. findme .. " > /dev/null || (" .. cmd .. ")")
end

run_once("urxvtd")
run_once("unclutter")
run_once("thunderbird")
run_once("kbdd")
run_once("xflux -l 53 -g 13.5")
run_once("pcmanfm -d")
run_once("nm-applet")
run_once("blueman-applet")
run_once("pasystray")
run_once("dropbox")
-- }}}

-- {{{ Variable definitions
-- localization
os.setlocale(os.getenv("LANG"))

-- beautiful init
beautiful.init(os.getenv("HOME") .. "/.config/awesome/themes/powerarrow/theme.lua")

-- common
modkey     = "Mod4"
altkey     = "Mod1"
terminal   = "urxvtc" or "xterm"
editor     = os.getenv("EDITOR") or "vim" or "vi"
editor_cmd = terminal .. " -e " .. editor

-- user defined
browser    = "firefox"
gui_editor = "gvim"
fm         = "pcmanfm"
mail       = "thunderbird"
iptraf     = terminal .. " -g 180x54-20+34 -e sudo iptraf-ng -i all "

local layouts = {
   awful.layout.suit.floating,
   awful.layout.suit.tile,
   awful.layout.suit.tile.bottom,
   awful.layout.suit.fair,
   awful.layout.suit.fair.horizontal,
}
-- }}}

-- {{{ Helper functions
local function client_menu_toggle_fn()
    local instance = nil

    return function ()
        if instance and instance.wibox.visible then
            instance:hide()
            instance = nil
        else
            instance = awful.menu.clients({ theme = { width = 250 } })
        end
    end
end
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {
    { "hotkeys", function() return false, hotkeys_popup.show_help end},
    { "manual", terminal .. " -e man awesome" },
    { "edit config", editor_cmd .. " " .. awesome.conffile },
    { "restart", awesome.restart },
    { "quit", function() awesome.quit() end},
    { "gtk config", "lxappearance" }
}

mywebmenu = {
    { "firefox", "firefox" },
    { "chromium","chromium" },
    { "dwb","dwb" },
    { "slack", "slack" },
    { "pidgin", "pidgin" },
    { "thunderbird", "thunderbird" },
    { "dropbox", "dropbox" }
}

myartmenu = {
    { "gpicview", "gpicview" },
    { "gimp", "gimp" },
    { "evince" , "evince" },
    { "golden dict", "goldendict" }
}

mymediamenu = {
    { "smplayer", "smplayer" },
    { "deadbeef", "deadbeef" },
    { "spotify", "spotify" }
}
myutilsmenu = {
    { "pcmanfm", "pcmanfm" },
    { "arandr", "arandr" }
}

mymainmenu = awful.menu({ items = {
    { "@wesome", myawesomemenu, beautiful.awesome_icon},
    { " " },
    { "web" , mywebmenu },
    { "develop" , mydevmenu },
    { "media" , mymediamenu },
    { "graphics " , myartmenu },
    { "utils" , myutilsmenu },
    { " " },
    { "sound", "pavucontrol" },
    { "htop", terminal .. " -e htop" },
    { "terminal", terminal },
    { "file manager", "pcmanfm"},
    { " " },
    { "suspend", "systemctl suspend" },
    { "reboot", "systemctl reboot" },
    { "roweroff", "systemctl poweroff" }
}, width = 200})

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon, menu = mymainmenu })
-- }}}

-- {{{ Wibox
markup = lain.util.markup
separators = lain.util.separators

-- Textclock
clockicon = wibox.widget.imagebox(beautiful.widget_clock)
mytextclock = wibox.widget.textclock(" %a %d %b  %H:%M")

-- calendar
lain.widget.calendar({
    notification_preset = {
        font = "Source Code Pro 10",
    },
    attach_to = { mytextclock },
})

-- Mail IMAP check
mailicon = wibox.widget.imagebox(beautiful.widget_mail)
mailicon:buttons(awful.util.table.join(awful.button({ }, 1, function () awful.util.spawn(mail) end)))

--[[ commented because it needs to be set before use
mailwidget = lain.widgets.imap({
     timeout  = 10,
     port = 993,
    is_plain = true,
    server   = "imap.googlemail.com",
    mail     = "<EMAIL>",
    password = "<PASSWORD>",
    settings = function()
        if mailcount > 0 then
            widget:set_text(" " .. mailcount .. " ")
            mailicon:set_image(beautiful.widget_mail_on)
        else
            widget:set_text("")
            mailicon:set_image(beautiful.widget_mail)
        end
    end
})
]]--

-- CPU
cpuicon = wibox.widget.imagebox(beautiful.widget_cpu)
cpuwidget = lain.widget.cpu({
    settings = function()
        widget:set_text(" " .. cpu_now.usage .. "% ")
    end
})

-- Coretemp
tempicon = wibox.widget.imagebox(beautiful.widget_temp)
tempwidget = lain.widget.temp({
    settings = function()
        widget:set_text(" " .. coretemp_now .. "°C ")
    end
})

-- Battery
baticon = wibox.widget.imagebox(beautiful.widget_battery)
batwidget = lain.widget.bat({
    ac  = "AC0",
    batteries = {"BAT0", "BAT1"},
    settings = function()
        if bat_now.perc == "n/a" then
            widget:set_markup(" AC ")
            baticon:set_image(beautiful.widget_ac)
            return
        elseif tonumber(bat_now.perc) <= 5 then
            baticon:set_image(beautiful.widget_battery_empty)
        elseif tonumber(bat_now.perc) <= 15 then
            baticon:set_image(beautiful.widget_battery_low)
        else
            baticon:set_image(beautiful.widget_battery)
        end
        widget:set_markup(" " .. bat_now.perc .. "% ")
    end
})

-- ALSA volume
volicon = wibox.widget.imagebox(beautiful.widget_vol)
volumewidget = lain.widget.pulseaudio({
    settings = function()
        if volume_now.muted == "yes" then
            volicon:set_image(beautiful.widget_vol_mute)
        elseif tonumber(volume_now.left) == 0 then
            volicon:set_image(beautiful.widget_vol_no)
        elseif tonumber(volume_now.left) <= 50 then
            volicon:set_image(beautiful.widget_vol_low)
        else
            volicon:set_image(beautiful.widget_vol)
        end

        widget:set_text(" " .. volume_now.left .. "% ")
    end
})

-- Lang switcher
--[[
$ sudo touch /etc/X11/xorg.conf.d/20-keyboard-layout.conf
  Section "InputClass"
    Identifier          "keyboard-layout"
    MatchIsKeyboard     "on"
    Option "XkbLayout"  "us,ru"
    Option "XkbOptions" "grp:caps_toggle"
  EndSection
]]--

kbdwidget = wibox.widget.textbox(" En ")
kbdwidget.border_width = 1
kbdwidget.border_color = beautiful.fg_normal
kbdwidget:set_text(" En ")
kbdstrings = {[0] = " En ", [1] = " Ru "}

dbus.request_name("session", "ru.gentoo.kbdd")
dbus.add_match("session", "interface='ru.gentoo.kbdd',member='layoutChanged'")
dbus.connect_signal("ru.gentoo.kbdd", function(...)
    local data = {...}
    local layout = data[2]
    kbdwidget:set_markup(kbdstrings[layout])
    end
)

-- Weather
-- Dresden: 2935022
-- weathericon = wibox.widget.textbox("❆ ")
weathericon = wibox.widget.imagebox(beautiful.widget_weather)
weatherwidget =  lain.widget.weather({
    city_id = 2935022,
    weather_na_markup = "n/a ",
    utc_offset = function ()
        return 1
    end,
    settings = function()
        widget:set_text(" " .. math.floor(weather_now["main"]["temp"]) .. "°C ")
    end
})

-- Separators
spr = wibox.widget.textbox(' ')
arrl = wibox.widget.imagebox()
arrl:set_image(beautiful.arrl)
arrl_dl = separators.arrow_left(beautiful.bg_focus, "alpha")
arrl_ld = separators.arrow_left("alpha", beautiful.bg_focus)

-- Create a wibox for each screen and add it
local taglist_buttons = awful.util.table.join(
    awful.button({ }, 1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t)
                              if client.focus then
                                  client.focus:move_to_tag(t)
                              end
                          end),
    awful.button({ }, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t)
                              if client.focus then
                                  client.focus:toggle_tag(t)
                              end
                          end),
    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    tags_1 = {
        names  = {"1:web","2:im","3:fm","4:media","5:dev","6:term"},
        layout = {layouts[1],layouts[2],layouts[2],layouts[2],layouts[2],layouts[2]}
    }

    tags_2 = {
        names  = {"1:web","2:im","3:work","4:dev"},
        layout = {layouts[1],layouts[2],layouts[2],layouts[2]}
    }

    tags_3 = {
        names  = {"1:work","2:term"},
        layout = {layouts[2],layouts[2]}
    }

    -- Each screen has its own tag table.
    if s.index == 1 then
        awful.tag(tags_1.names, s, tags_1.layout)
    elseif s.index == 2 then
        awful.tag(tags_2.names, s, tags_2.layout)
    else
        awful.tag(tags_3.names, s, tags_3.layout)
    end

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))

    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist_buttons)

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s, height = 20})

    -- Widgets that are aligned to the upper left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(mylauncher)
    left_layout:add(spr)
    left_layout:add(s.mytaglist)
    left_layout:add(s.mypromptbox)
    left_layout:add(spr)

    -- Widgets that are aligned to the upper right
    local right_layout_toggle = true
    local function right_layout_add (...)
       local arg = {...}
       if right_layout_toggle then
            right_layout:add(arrl_ld)
            for i, n in pairs(arg) do
                right_layout:add(wibox.container.background(n, beautiful.bg_focus))
            end
       else
            right_layout:add(arrl_dl)
            for i, n in pairs(arg) do
                right_layout:add(n)
            end
       end
       right_layout_toggle = not right_layout_toggle
    end

    right_layout = wibox.layout.fixed.horizontal()
    right_layout:add(wibox.widget.systray())
    right_layout:add(spr)
    right_layout:add(arrl)
    right_layout_add(weathericon,weatherwidget.widget)
    right_layout_add(cpuicon, cpuwidget.widget)
    right_layout_add(tempicon, tempwidget.widget)
    right_layout_add(volicon, volumewidget.widget)
    right_layout_add(baticon, batwidget.widget)
    right_layout_add(kbdwidget)
    right_layout_add(mytextclock, spr)
    right_layout_add(s.mylayoutbox)

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_right(right_layout)

    -- Add widgets to the wibox
    s.mywibox:set_widget(layout)
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
              {description="show help", group="awesome"}),
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
              {description = "view previous", group = "tag"}),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
              {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end,
              {description = "show main menu", group = "awesome"}),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),

    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end,
              {description = "focus the previous screen", group = "screen"}),

    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
              {description = "quit awesome", group = "awesome"}),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)          end,
              {description = "increase master width factor", group = "layout"}),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)          end,
              {description = "decrease master width factor", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
              {description = "increase the number of master clients", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
              {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end,
              {description = "increase the number of columns", group = "layout"}),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end,
              {description = "decrease the number of columns", group = "layout"}),
    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
              {description = "select next", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
              {description = "select previous", group = "layout"}),

    awful.key({ modkey, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  -- Focus restored client
                  if c then
                      client.focus = c
                      c:raise()
                  end
              end,
              {description = "restore minimized", group = "client"}),

    -- Prompt
    awful.key({ modkey },            "r",     function () awful.screen.focused().mypromptbox:run() end,
              {description = "run prompt", group = "launcher"}),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run {
                    prompt       = "Run Lua code: ",
                    textbox      = awful.screen.focused().mypromptbox.widget,
                    exe_callback = awful.util.eval,
                    history_path = awful.util.get_cache_dir() .. "/history_eval"
                  }
              end,
              {description = "lua execute prompt", group = "awesome"}),

  --{{{ Custom
    -- Widgets popups
    awful.key({ altkey,           }, "c",   function () lain.widget.calendar:show(4) end),

    -- ALSA volume control
    awful.key({ }, "XF86AudioRaiseVolume", function ()
        os.execute(string.format("pactl set-sink-volume %d +1%%", volumewidget.sink))
        volumewidget.update()
    end),
    awful.key({ }, "XF86AudioLowerVolume",  function ()
        os.execute(string.format("pactl set-sink-volume %d -1%%", volumewidget.sink))
        volumewidget.update()
    end),
    awful.key({ }, "XF86AudioMute", function ()
        os.execute(string.format("pactl set-sink-mute %d toggle", volumewidget.sink))
        volumewidget.update()
    end),

    -- via not multimedia keys
    awful.key({ altkey }, "Up", function ()
        os.execute(string.format("pactl set-sink-volume %d +1%%", volumewidget.sink))
        volumewidget.update()
    end),

    awful.key({ altkey }, "Down", function ()
        os.execute(string.format("pactl set-sink-volume %d -1%%", volumewidget.sink))
        volumewidget.update()
    end),

    awful.key({ altkey }, "m", function ()
        os.execute(string.format("pactl set-sink-mute %d toggle", volumewidget.sink))
      volumewidget.update()
    end),

    -- backlight control
    awful.key({ }, "XF86MonBrightnessUp", function ()
        awful.util.spawn("xbacklight -inc 10")
    end),
    awful.key({ }, "XF86MonBrightnessDown", function ()
        awful.util.spawn("xbacklight -dec 10")
    end),


    -- Copy to clipboard
    awful.key({ modkey }, "c", function () awful.util.spawn("xsel -p -o | xsel -i -b") end),

    -- User programs
    awful.key({ modkey }, "q", function () awful.util.spawn(browser) end),
    awful.key({ modkey }, "g", function () awful.util.spawn(fm) end),

    -- Widgets popup
    awful.key({ altkey }, "e",      function () yawn.show(2) end),

    -- Take a screenshot
    awful.key({ altkey }, "p", function () awful.util.spawn("scrot") end),

    -- Lock the screen
    awful.key({ altkey }, "l", function () awful.util.spawn("slimlock") end)
-- }}}
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
              {description = "toggle floating", group = "client"}),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "move to master", group = "client"}),
    awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
              {description = "move to screen", group = "client"}),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
              {description = "toggle keep on top", group = "client"}),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end ,
        {description = "minimize", group = "client"}),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {description = "maximize", group = "client"})
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {

    -- All clients will match this rule.
    { rule = { },
        properties = { border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = clientkeys,
            buttons = clientbuttons,
            screen = awful.screen.preferred,
            placement = awful.placement.no_overlap+awful.placement.no_offscreen,
            size_hints_honor = false
        }
    },

    -- Floating clients.
    { rule_any = {
        instance = {
            "DTA",
            "copyq",
        },
        class = {
            "Arandr",
            "Gpick",
            "Kruler",
            "MessageWin",
            "Sxiv",
            "Wpa_gui",
            "pinentry",
            "veromix",
            "xtightvncviewer"
        },
        name = {
            "Event Tester",
        },
        role = {
            "AlarmWindow",
            "pop-up",
        }
    },
    properties = { floating = true }},

  { rule = { class = "URxvt" },
    properties = { opacity = 0.99 }},

  { rule = { class = "Firefox" },
    properties = { screen = 1, tag = "1:web" }},

  { rule = { instance = "plugin-container" },
    properties = { screen = 1, tag = "1:web" }},

  { rule = { class = "smplayer" },
    properties = { screen = 1, tag = "4:media" }}
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup and
      not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
        and awful.client.focus.filter(c) then
        client.focus = c
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
