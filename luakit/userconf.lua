---
local downloads = require "downloads"
local settings = require "settings"
local modes = require "modes"

downloads.default_dir = os.getenv("HOME") .. "/downloads"

settings.window.default_search_engine = "duckduckgo"
settings.window.home_page = "luakit://bookmarks"

-- settings.tablist.visibility = "always"

settings.webview.default_font_family = "Liberation Sans"
settings.webview.monospace_font_family = "Liberation Mono"
settings.webview.sans_serif_font_family = "Liberation Sans"
settings.webview.serif_font_family = "Liberation Serif"

settings.webview.default_charset = "utf-8"
settings.webview.default_font_size = 14
settings.webview.default_monospace_font_size = 14

settings.webview.zoom_level = 150

settings.webview.enable_java = false
settings.webview.enable_smooth_scrolling = true
settings.webview.hardware_acceleration_policy = "always"


settings.window.close_with_last_tab = false

modes.add_binds("normal", {
    { "<Control-c>", "Copy selected text.", function ()
        luakit.selection.clipboard = luakit.selection.primary
    end},
})
