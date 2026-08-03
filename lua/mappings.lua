require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })

map("n", "<leader><leader>", "<cmd>Telescope find_files<cr>", { desc = "Telescope find files" })

-- Live grep with inline ripgrep args, e.g.  foo -g '*.lua'  or  foo -tpython
map("n", "<leader>fW", function()
  require("telescope").extensions.live_grep_args.live_grep_args()
end, { desc = "Live grep (with path/glob args)" })
map("i", "jk", "<ESC>")

map("n", "<leader>fp", function()
  local path = vim.fn.expand("%:.")
  vim.fn.setreg("+", path)
  vim.notify("Copied: " .. path)
end, { desc = "Copy relative path" })

-- Copy a GitHub permalink (pinned to HEAD's commit SHA) for the current line
map("n", "<leader>gy", function()
  require("gh_url").copy()
end, { desc = "Copy GitHub permalink to line" })

-- Visual mode: permalink spanning the selected range
map("x", "<leader>gy", function()
  local first = vim.fn.line("v")
  local last = vim.fn.line(".")
  if first > last then
    first, last = last, first
  end
  require("gh_url").copy({ first = first, last = last })
end, { desc = "Copy GitHub permalink to selection" })

-- Git blame for the current line (full commit info in a popup)
map("n", "<leader>gb", function()
  require("gitsigns").blame_line { full = true }
end, { desc = "Git blame line" })

-- Toggle inline blame at end of every line
map("n", "<leader>gB", function()
  require("gitsigns").toggle_current_line_blame()
end, { desc = "Git blame toggle inline" })

-- Open the commit that last touched the current line on GitHub
map("n", "<leader>go", function()
  require("gh_url").open_commit()
end, { desc = "Git open blame commit in browser" })

-- Centered scroll/search + line motions
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up (centered)" })
map("n", "n", "nzzzv", { desc = "Next search result (centered)" })
map("n", "N", "Nzzzv", { desc = "Prev search result (centered)" })

map({ "n", "x", "o" }, "H", "^", { desc = "First non-blank character" })
map({ "n", "x", "o" }, "L", "$", { desc = "End of line" })

-- Move by visual line when wrapped (counts still use real lines)
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

map("n", "gF", function()
  vim.cmd("edit " .. vim.fn.expand "<cfile>")
end, { desc = "Open or create file under cursor" })

map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Folding (treesitter-based, see options.lua)
map("n", "<leader>ft", "za", { desc = "Fold toggle under cursor" })
map("n", "<leader>fe", "zR", { desc = "Fold expand (open all)" })
map("n", "<leader>fc", "zM", { desc = "Fold collapse (close all)" })
map("n", "<leader>fj", "zj", { desc = "Fold jump to next" })
map("n", "<leader>fk", "zk", { desc = "Fold jump to previous" })

-- Treesitter-aware: fold only functions in the file (structs/blocks stay open)
map("n", "<leader>fF", function()
  require("folding").fold_all_functions()
end, { desc = "Fold all functions" })

-- Split the current file vertically
map("n", "<leader>sv", "<cmd>vsplit<cr>", { desc = "Split window vertically" })

-- Markdown: toggle rendered view (see plugins/markdown.lua)
map("n", "<leader>mr", "<cmd>RenderMarkdown buf_toggle<cr>", { desc = "Markdown render toggle" })

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
