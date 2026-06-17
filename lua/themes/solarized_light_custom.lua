-- NvChad base46 theme: Solarized Light
-- Ported from the official VSCode Solarized Light color theme
-- Place this file at: ~/.config/nvim/lua/themes/solarized_light.lua
-- Then set in chadrc.lua:
--   M.base46 = { theme = "solarized_light" }

---@type Base46Table
local M = {}

-- Solarized palette reference:
--   base03  #002B36  darkest bg (terminal)
--   base02  #073642  dark bg highlights
--   base01  #586E75  comments / secondary content
--   base00  #657B83  body text
--   base0   #839496  (unused in light)
--   base1   #93A1A1  optional emphasized content
--   base2   #EEE8D5  background highlights
--   base3   #FDF6E3  main background
--   yellow  #B58900
--   orange  #CB4B16
--   red     #DC322F
--   magenta #D33682
--   violet  #6C71C4
--   blue    #268BD2
--   cyan    #2AA198
--   green   #859900

M.base_30 = {
  white          = "#657B83",   -- base00: default fg / "white" in light context
  black          = "#FDF6E3",   -- base3:  main editor background
  darker_black   = "#EEE8D5",   -- base2:  slightly darker bg (sidebar, statusline)
  black2         = "#F5EFD6",   -- between base3 and base2
  one_bg         = "#E8E2CE",   -- used for panels / nvimtree bg
  one_bg2        = "#DDD6C1",   -- tab bar, borders
  one_bg3        = "#D3CBB7",   -- inactive tabs
  grey           = "#93A1A1",   -- base1:  tag brackets, subtle ui
  grey_fg        = "#839496",   -- base0
  grey_fg2       = "#7A9099",
  light_grey     = "#657B83",   -- base00: line numbers etc.
  red            = "#DC322F",
  baby_pink      = "#E06C75",
  pink           = "#D33682",   -- magenta
  line           = "#DDD6C1",   -- separator lines
  green          = "#859900",
  vibrant_green  = "#6AAF11",
  nord_blue      = "#268BD2",   -- blue
  blue           = "#268BD2",
  seablue        = "#2AA198",   -- cyan
  yellow         = "#B58900",
  sun            = "#CB4B16",   -- orange
  purple         = "#6C71C4",   -- violet
  dark_purple    = "#5A5FAE",
  teal           = "#2AA198",
  orange         = "#CB4B16",
  cyan           = "#2AA198",
  statusline_bg  = "#EEE8D5",   -- base2
  lightbg        = "#E8E2CE",
  pmenu_bg       = "#268BD2",   -- blue highlight for completion menu
  folder_bg      = "#268BD2",
}

M.base_16 = {
  base00 = "#FDF6E3",   -- default bg
  base01 = "#EEE8D5",   -- lighter bg (status bar)
  base02 = "#DDD6C1",   -- selection bg
  base03 = "#93A1A1",   -- comments, invisibles
  base04 = "#839496",   -- dark fg (status bar)
  base05 = "#657B83",   -- default fg
  base06 = "#586E75",   -- light fg (not often used)
  base07 = "#073642",   -- light bg (for contrast)
  base08 = "#DC322F",   -- red    – variables, tags
  base09 = "#CB4B16",   -- orange – integers, booleans, constants
  base0A = "#B58900",   -- yellow – classes, markup bold
  base0B = "#859900",   -- green  – strings, inherited class
  base0C = "#2AA198",   -- cyan   – support, regex
  base0D = "#268BD2",   -- blue   – functions, methods, headings
  base0E = "#6C71C4",   -- violet – keywords, storage
  base0F = "#D33682",   -- magenta – deprecated, embedded
}

M.type = "light"

return M
