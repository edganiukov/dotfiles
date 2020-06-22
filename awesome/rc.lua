--[[
-- Awesome WM main config
--]]

-- {{{ Required libraries
local awesome, client, mouse, screen, tag = awesome, client, mouse, screen, tag
local ipairs, string, os, table, tostring, tonumber, type = ipairs, string, os, table, tostring, tonumber, type

local gears         = require("gears")
local awful         = require("awful")
                      require("awful.autofocus")
local wibox         = require("wibox")
local beautiful     = require("beautiful")
local naughty       = require("naughty")
local lain          = require("lain")
local hotkeys_popup = require("awful.hotkeys_popup").widget
                      require("awful.hotkeys_popup.keys")
local table         = awful.util.table or gears.table -- 4.{0,1} compatibility
local dpi           = require("beautiful.xresources").apply_dpi

local wibar = require("wibar")
local theme = require("theme")
-- }}}

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({
        preset = naughty.config.presets.critical,
        title = "Oops, there were errors during startup!",
        text = awesome.startup_errors,
    })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        if in_error then return end
        in_error = true

        naughty.notify({
            preset = naughty.config.presets.critical,
            title = "Oops, an error happened!",
            text = tostring(err),
        })
        in_error = false
    end)
end
-- }}}

-- {{{ Autostart headless processes

-- This function will run once every time Awesome is started
local function run_once(cmd_arr)
    for _, cmd in ipairs(cmd_arr) do
        awful.spawn.with_shell(string.format("pgrep -u $USER -fx '%s' > /dev/null || (%s)", cmd, cmd))
    end
end

run_once({
}) -- entries must be separated by commas

-- }}}

-- {{{ Variable definitions
local modkey       = "Mod4"
local altkey       = "Mod1"
local terminal     = "st"
local editor       = os.getenv("EDITOR") or "vim"
local browser      = "firefox"
local scrlocker    = "i3lock -n -c 282828 -R 128"

awful.util.terminal = terminal
awful.util.tagnames = {" 1 ", " 2 ", " 3 ", " 4 " , " 5 ", " 6 ", " 7 ", " 8 ", " 9 "}
awful.layout.layouts = {
    -- awful.layout.suit.max,
    -- awful.layout.suit.tile.right,
    -- awful.layout.suit.tile.left,
    awful.layout.suit.fair,
    -- awful.layout.suit.fair.horizontal,
    -- awful.layout.suit.tile.top,
    -- awful.layout.suit.tile.bottom,
    -- awful.layout.suit.floating,
    -- awful.layout.suit.spiral,
    -- awful.layout.suit.spiral.dwindle,
    -- awful.layout.suit.max.fullscreen,
    -- awful.layout.suit.magnifier,
    -- awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
}

awful.util.taglist_buttons = table.join(
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

awful.util.tasklist_buttons = table.join(
    awful.button({ }, 1, function (c)
        if c == client.focus then
            c.minimized = true
        else
            --c:emit_signal("request::activate", "tasklist", {raise = true})

            -- Without this, the following
            -- :isvisible() makes no sense
            c.minimized = false
            if not c:isvisible() and c.first_tag then
                c.first_tag:view_only()
            end
            -- This will also un-minimize
            -- the client, if needed
            client.focus = c
            c:raise()
        end
    end),
    awful.button({ }, 2, function (c) c:kill() end),
    awful.button({ }, 3, function ()
        local instance = nil

        return function ()
            if instance and instance.wibox.visible then
                instance:hide()
                instance = nil
            else
                instance = awful.menu.clients({theme = {width = dpi(250)}})
            end
        end
    end),
    awful.button({ }, 4, function () awful.client.focus.byidx(1) end),
    awful.button({ }, 5, function () awful.client.focus.byidx(-1) end)
)

beautiful.init(theme)

-- }}}

-- {{{ Menu
local myawesomemenu = {
    { "hotkeys", function() return false, hotkeys_popup.show_help end },
    { "restart", awesome.restart },
    { "quit", function() awesome.quit() end },
}

awful.util.mymainmenu = awful.menu({ items = {
    { "awesome", myawesomemenu, beautiful.menu_awesome_icon},
    { " " },
    { "suspend", "systemctl suspend" },
    { "reboot", "systemctl reboot" },
    { "roweroff", "systemctl poweroff" },
}, width = 200})

mylauncher = awful.widget.launcher({ image = beautiful.menu_awesome_icon, menu = mymainmenu })

-- {{{ Screen
-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", function(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end)

-- No borders when rearranging only 1 non-floating or maximized client
screen.connect_signal("arrange", function (s)
    local only_one = #s.tiled_clients == 1
    for _, c in pairs(s.clients) do
        if only_one and not c.floating or c.maximized then
            c.border_width = 0
        else
            c.border_width = beautiful.border_width
        end
    end
end)

-- Create a wibox for each screen and add it
awful.screen.connect_for_each_screen(function(s) wibar.at_screen_connect(s) end)
-- }}}

-- {{{ Mouse bindings
root.buttons(table.join(
    awful.button({ }, 3, function () awful.util.mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = table.join(
    awful.key({ altkey }, "p", function() awful.spawn.with_shell("scrot") end,
        {description = "take a screenshot", group = "hotkeys"}),

    -- X screen locker
    awful.key({ modkey }, "m", function () awful.spawn.with_shell(scrlocker) end,
        {description = "lock screen", group = "hotkeys"}),

    -- Hotkeys
    awful.key({ modkey }, "s",      hotkeys_popup.show_help,
        {description = "show help", group="awesome"}),
    -- Tag browsing
    awful.key({ modkey }, "Left",   awful.tag.viewprev,
        {description = "view previous", group = "tag"}),
    awful.key({ modkey }, "Right",  awful.tag.viewnext,
        {description = "view next", group = "tag"}),
    awful.key({ modkey }, "Escape", awful.tag.history.restore,
        {description = "go back", group = "tag"}),

    -- Non-empty tag browsing
    awful.key({ altkey }, "Left", function () lain.util.tag_view_nonempty(-1) end,
        {description = "view  previous nonempty", group = "tag"}),
    awful.key({ altkey }, "Right", function () lain.util.tag_view_nonempty(1) end,
        {description = "view  previous nonempty", group = "tag"}),

    -- Default client focus
    awful.key({ modkey, "Shift" }, "j",
        function ()
            awful.client.focus.byidx( 1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ modkey , "Shift" }, "k",
        function ()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),

    -- By direction client focus
    awful.key({ modkey }, "j",
        function()
            awful.client.focus.global_bydirection("down")
            if client.focus then client.focus:raise() end
        end,
        {description = "focus down", group = "client"}),
    awful.key({ modkey }, "k",
        function()
            awful.client.focus.global_bydirection("up")
            if client.focus then client.focus:raise() end
        end,
        {description = "focus up", group = "client"}),
    awful.key({ modkey }, "h",
        function()
            awful.client.focus.global_bydirection("left")
            if client.focus then client.focus:raise() end
        end,
        {description = "focus left", group = "client"}),
    awful.key({ modkey }, "l",
        function()
            awful.client.focus.global_bydirection("right")
            if client.focus then client.focus:raise() end
        end,
        {description = "focus right", group = "client"}),
    awful.key({ modkey }, "w", function () awful.util.mymainmenu:show() end,
        {description = "show main menu", group = "awesome"}),

    -- Layout manipulation
    awful.key({ modkey, "Shift" }, "h", function () awful.client.swap.byidx(  1) end,
        {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift" }, "l", function () awful.client.swap.byidx( -1) end,
        {description = "swap with previous client by index", group = "client"}),

    awful.key({ modkey }, "u", awful.client.urgent.jumpto,
        {description = "jump to urgent client", group = "client"}),

    awful.key({ modkey }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),

    awful.key({ modkey }, "space", function () awful.layout.inc(1) end,
        {description = "select next", group = "layout"}),
    awful.key({ modkey, "Shift" }, "space", function () awful.layout.inc(-1) end,
        {description = "select previous", group = "layout"}),

    -- Screen
    awful.key({ altkey,         }, "h", function () awful.screen.focus_relative( 1) end,
        {description = "focus the next screen", group = "screen"}),
    awful.key({ altkey,         }, "l", function () awful.screen.focus_relative(-1) end,
        {description = "focus the previous screen", group = "screen"}),


    -- Show/Hide Wibox
    awful.key({ modkey }, "b",
        function ()
            for s in screen do
                s.mywibox.visible = not s.mywibox.visible
                if s.mybottomwibox then
                    s.mybottomwibox.visible = not s.mybottomwibox.visible
                end
            end
        end,
        {description = "toggle wibox", group = "awesome"}),

    -- Dynamic tagging
    awful.key({ modkey, "Shift" }, "n", function () lain.util.add_tag() end,
        {description = "add new tag", group = "tag"}),
    awful.key({ modkey, "Shift" }, "r", function () lain.util.rename_tag() end,
        {description = "rename tag", group = "tag"}),
    awful.key({ modkey, "Shift" }, "Left", function () lain.util.move_tag(-1) end,
        {description = "move tag to the left", group = "tag"}),
    awful.key({ modkey, "Shift" }, "Right", function () lain.util.move_tag(1) end,
        {description = "move tag to the right", group = "tag"}),
    awful.key({ modkey, "Shift" }, "d", function () lain.util.delete_tag() end,
        {description = "delete tag", group = "tag"}),

    -- Standard program
    awful.key({ modkey }, "Return", function () awful.spawn(terminal) end,
        {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
        {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift" }, "q", awesome.quit,
        {description = "quit awesome", group = "awesome"}),

    awful.key({ altkey, "Shift" }, "n",
        function ()
            local c = awful.client.restore()
            -- Focus restored client
            if c then
                client.focus = c
                c:raise()
            end
        end,
        {description = "restore minimized", group = "client"}),

    -- Widgets popups
    -- awful.key({ altkey }, "c", function () if beautiful.cal then beautiful.cal.show(7) end end,
    --     {description = "show calendar", group = "widgets"}),
    -- awful.key({ altkey }, "h", function () if beautiful.fs then beautiful.fs.show(7) end end,
    --     {description = "show filesystem", group = "widgets"}),
    -- awful.key({ altkey }, "w", function () if beautiful.weather then beautiful.weather.show(7) end end,
    --     {description = "show weather", group = "widgets"}),

    -- Brightness
    -- awful.key({ }, "XF86MonBrightnessUp", function () awful.spawn.with_shell("brightnessctl --device=acpi_video0 set 5%") end,
    --     {description = "+5%", group = "hotkeys"}),
    -- awful.key({ }, "XF86MonBrightnessDown", function () awful.spawn.with_shell("brightnessctl --device=acpi_video0 set 5%-") end,
    --     {description = "-5%", group = "hotkeys"}),

    -- PulseAudio volume control
    -- awful.key({ }, "XF86AudioRaiseVolume",
    --     function ()
    --         awful.spawn.with_shell(string.format("amixer set %s 5%%+", beautiful.volume.channel))
    --         beautiful.volume.update()
    --     end),
    -- awful.key({ }, "XF86AudioLowerVolume",
    --     function ()
    --         awful.spawn.with_shell(string.format("amixer set %s 5%%-", beautiful.volume.channel)))
    --         beautiful.volume.update("amixer set %s toggle", beautiful.volume.channel))
    --     end),
    -- awful.key({ }, "XF86AudioMute",
    --     function ()
    --         awful.spawn.with_whell(string.format("pactl set-sink-mute %s toggle", beautiful.volume.device))
    --         beautiful.volume.update()
    --     end),

    -- Dmenu
    -- awful.key({ modkey }, "r",
    --     function ()
    --         awful.spawn.with_shell("dmenu_run_recent")
    --     end,
    --     {description = "dmenu: run", group = "launcher"}),
    awful.key({ modkey }, "p",
        function ()
            awful.spawn.with_shell("gopass ls --flat | dmenu | xargs --no-run-if-empty gopass show -c")
        end,
        {description = "dmenu: gopass", group = "launcher"}),
    --
    -- Prompt
    awful.key({ modkey }, "r",
        function () awful.screen.focused().mypromptbox:run() end,
        {description = "run prompt", group = "launcher"})
    --

    -- awful.key({ modkey }, "x",
    --     function ()
    --         awful.prompt.run {
    --         prompt       = "Run Lua code: ",
    --         textbox      = awful.screen.focused().mypromptbox.widget,
    --         exe_callback = awful.util.eval,
    --         history_path = awful.util.get_cache_dir() .. "/history_eval"
    --         }
    --     end,
    --     {description = "lua execute prompt", group = "awesome"})
    --]]
)

clientkeys = table.join(
    awful.key({ modkey }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ modkey }, "q", function (c) c:kill() end,
        {description = "close", group = "client"}),
    awful.key({ altkey }, "space",  awful.client.floating.toggle,
        {description = "toggle floating", group = "client"}),
    awful.key({ altkey }, "Return", function (c) c:swap(awful.client.getmaster()) end,
        {description = "move to master", group = "client"}),
    awful.key({ altkey }, "o", function (c) c:move_to_screen() end,
        {description = "move to screen", group = "client"}),
    awful.key({ altkey }, "t", function (c) c.ontop = not c.ontop end,
        {description = "toggle keep on top", group = "client"}),
    awful.key({ altkey }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end,
        {description = "minimize", group = "client"}),
    awful.key({ altkey }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end,
        {description = "maximize", group = "client"})
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    -- Hack to only show tags 1 and 9 in the shortcut window (mod+s)
    local descr_view, descr_toggle, descr_move, descr_toggle_focus
    if i == 1 or i == 9 then
        descr_view = {description = "view tag #", group = "tag"}
        descr_toggle = {description = "toggle tag #", group = "tag"}
        descr_move = {description = "move focused client to tag #", group = "tag"}
        descr_toggle_focus = {description = "toggle focused client on tag #", group = "tag"}
    end
    globalkeys = table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
            function ()
                local screen = awful.screen.focused()
                local tag = screen.tags[i]
                if tag then
                    tag:view_only()
                end
            end,
            descr_view),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
            function ()
                local screen = awful.screen.focused()
                local tag = screen.tags[i]
                if tag then
                    awful.tag.viewtoggle(tag)
                end
            end,
            descr_toggle),

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
            descr_move),

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
            descr_toggle_focus)
    )
end

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
    end),
    awful.button({ modkey }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    {
        rule = { },
        properties = {
            border_width = beautiful.border_width,
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
    -- Titlebars
    {
        rule_any = { type = { "dialog", "normal" } },
        properties = { titlebars_enabled = false },
    },
    -- Set Firefox to always map on the first tag on screen 1.
    {
        rule = { class = "Firefox" },
        properties = { screen = 1, tag = awful.util.tagnames[1] },
    },
    {
        rule = { class = "vlc" },
        properties = { floating = true },
    },
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

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- Custom
    if beautiful.titlebar_fun then
        beautiful.titlebar_fun(c)
        return
    end

    -- Default
    -- buttons for the titlebar
    local buttons = table.join(
        awful.button({ }, 1, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 2, function() c:kill() end),
        awful.button({ }, 3, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c, {size = dpi(18)}) : setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", {raise = true})
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
