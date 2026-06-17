vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"

-- load plugins
require("zig_context").setup()

require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
  },

  { import = "plugins" },
}, lazy_config)

-- load theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require "options"
require "autocmds"

vim.schedule(function()
  require "mappings"
end)

vim.opt.guicursor = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20"

-- Force cursor and visual colors for Solarized Light
-- Must run after base46 loads highlights
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    -- Cursor: dark on light bg
    vim.api.nvim_set_hl(0, "Cursor",      { bg = "#002B36", fg = "#FDF6E3" })
    vim.api.nvim_set_hl(0, "CursorIM",    { bg = "#002B36", fg = "#FDF6E3" })
    vim.api.nvim_set_hl(0, "TermCursor",  { bg = "#002B36", fg = "#FDF6E3" })

    -- Visual: dark bg so selected text is clearly visible
    vim.api.nvim_set_hl(0, "Visual",      { bg = "#93A1A1", fg = "#FDF6E3" })
    vim.api.nvim_set_hl(0, "VisualNOS",   { bg = "#93A1A1", fg = "#FDF6E3" })
  end,
})

-- Also apply immediately on startup (ColorScheme won't fire on first load)
vim.api.nvim_set_hl(0, "Cursor",      { bg = "#002B36", fg = "#FDF6E3" })
vim.api.nvim_set_hl(0, "CursorIM",    { bg = "#002B36", fg = "#FDF6E3" })
vim.api.nvim_set_hl(0, "TermCursor",  { bg = "#002B36", fg = "#FDF6E3" })
vim.api.nvim_set_hl(0, "Visual",      { bg = "#93A1A1", fg = "#FDF6E3" })
vim.api.nvim_set_hl(0, "VisualNOS",   { bg = "#93A1A1", fg = "#FDF6E3" })

-- Let Neovim control cursor color (overrides terminal setting)
vim.opt.termguicolors = true
vim.cmd("set guicursor=n-v-c:block-Cursor,i:ver25-Cursor,r:hor20-Cursor")
