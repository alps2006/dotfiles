---------------------------
-- Vern's awesome theme  --
---------------------------
local gears  = require("gears")
local lain   = require("lain")
local awful  = require("awful")
local wibox  = require("wibox")

theme = {}

theme.default_dir       = require("awful.util").get_themes_dir() .. "default"
theme.home_dir          = os.getenv("HOME") .. "/.config/awesome/theme/"
theme.font              = "DejaVu Sans 9"
theme.taglist_font      = "DejaVu Sans 9"
theme.tasklist_font     = "Envy Code R 10"
theme.fg_normal         = "#aaaaaa"
theme.fg_focus          = "#ffffff"
theme.bg_focus          = "#535d6c"
theme.bg_normal         = "#222222"
theme.fg_urgent         = "#ffffff"
theme.bg_urgent         = "#ff0000"
theme.fg_minimize       = "#ffffff"
theme.bg_minimize       = "#444444"
theme.border_normal     = "#d5d5d5"
theme.border_focus      = "#000000"
theme.border_width      = 1
theme.menu_height       = 15
theme.menu_width        = 100
theme.tasklist_plain_task_name  = false
theme.tasklist_disable_icon     = false
theme.useless_gap               = 0
theme.wallpaper                 = theme.home_dir .. "light_wp.png"
theme.awesome_icon              = theme.home_dir .. "debian-logo.png"
theme.taglist_squares_sel       = theme.home_dir .. "taglist_squares_sel.png"
theme.taglist_squares_unsel     = theme.home_dir .. "taglist_squares_unsel.png"
-- You can use your own layout icons like this:
-- http://ni.fr.eu.org/blog/awesome_icons/
-- mkicons --fg trans --bg '#222222' --fg '#aaaaaa' --size 20x20 --margin-top 2 --margin-bottom 2 --margin-left 2 --margin-right 2
theme.layout_fairh              = theme.home_dir .. "layout_fairh.png"
theme.layout_fairv              = theme.home_dir .. "layout_fairv.png"
theme.layout_floating           = theme.home_dir .. "layout_floating.png"
theme.layout_magnifier          = theme.home_dir .. "layout_magnifier.png"
theme.layout_max                = theme.home_dir .. "layout_max.png"
theme.layout_fullscreen         = theme.home_dir .. "layout_fullscreen.png"
theme.layout_tilebottom         = theme.home_dir .. "layout_tilebottom.png"
theme.layout_tileleft           = theme.home_dir .. "layout_tileleft.png"
theme.layout_tile               = theme.home_dir .. "layout_tile.png"
theme.layout_tiletop            = theme.home_dir .. "layout_tiletop.png"
theme.layout_spiral             = theme.home_dir .. "layout_spiral.png"
theme.layout_cornernw           = theme.home_dir .. "layout_floating.png"
theme.layout_cornerne           = theme.home_dir .. "layout_floating.png"
theme.layout_cornersw           = theme.home_dir .. "layout_floating.png"
theme.layout_cornerse           = theme.home_dir .. "layout_floating.png"
theme.tasklist_floating_icon    = theme.home_dir .. "mark.png"


-- Create a promodoro widget {{{3
-- TODO @2017.08
-- pomodoro = wibox.widget.progressbar()
-- pomodoro:set_width(1)
-- pomodoro:set_max_value(100)
-- pomodoro:set_background_color(theme.bg_normal)
-- pomodoro:set_color('#AECF96')
-- pomodoro:set_color({ type = "linear", from = { 0, 0 }, to = { 100, 0 }, stops = { { 0, '#AECF96' }, { 0.25, "#88A175" }, { 1, "#FF5656" } }})
-- pomodoro:set_ticks(true) -- false:平滑的整体，true:间隙的个体
-- }}}

function theme.at_screen_connect(s)
    -- Quake application
    s.quake = lain.util.quake({ app = awful.util.terminal })

    -- If wallpaper is a function, call it with the screen
    local wallpaper = theme.wallpaper
    if type(wallpaper) == "function" then
        wallpaper = wallpaper(s)
    end
    gears.wallpaper.tiled(wallpaper, s)

    -- Each screen has its own tag table.
    awful.tag(awful.util.tagnames, s, awful.layout.layouts[1])

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

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons)

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "bottom", screen = s })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            mylauncher,
            s.mytaglist,
            s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            mykeyboardlayout,
            wibox.widget.systray(),
            mytextclock,
            s.mylayoutbox,
        },
    }
end

return theme
-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80