require "nvchad.options"

-- add yours here!

-- local o = vim.o
-- o.cursorlineopt ='both' -- to enable cursorline!

vim.opt.number = true

-- Treesitter-based folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()" -- needs Neovim 0.10+
vim.opt.foldtext = "" -- show fold's first line with normal syntax highlighting
vim.opt.foldlevel = 99 -- start fully unfolded
vim.opt.foldlevelstart = 99 -- ...on every new buffer
vim.opt.foldenable = true
vim.opt.fillchars:append { fold = " " }
