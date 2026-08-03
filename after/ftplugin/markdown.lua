-- Prose-friendly wrapping. j/k already move by visual line (see mappings.lua),
-- so wrapped paragraphs navigate the way they read.
vim.opt_local.wrap = true
vim.opt_local.linebreak = true -- break at word boundaries, not mid-word
vim.opt_local.breakindent = true -- keep list/quote indentation on wrapped lines
vim.opt_local.showbreak = "  "
