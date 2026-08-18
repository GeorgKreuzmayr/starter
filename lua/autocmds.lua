require "nvchad.autocmds"

-- The 100-column ruler (options.lua) marks a code line budget, so it shouldn't
-- be drawn through the dashboard, terminals, help or quickfix.
--
-- `colorcolumn` is window-local and windows outlive the buffers shown in them:
-- the dashboard's window is the one your first file opens into, so *clearing*
-- the ruler for a special buffer without putting it back leaves real code with
-- no guide. Set it explicitly in both directions instead of only clearing.
local ruler = vim.go.colorcolumn -- whatever options.lua asked for

vim.api.nvim_create_autocmd({ "BufWinEnter", "TermOpen" }, {
  group = vim.api.nvim_create_augroup("ColorColumnFileOnly", { clear = true }),
  callback = function(args)
    local win = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_get_buf(win) ~= args.buf then
      return
    end
    -- Window-scoped (`:setlocal`) so the global default stays intact for
    -- windows this autocmd hasn't reached yet.
    vim.api.nvim_set_option_value(
      "colorcolumn",
      vim.bo[args.buf].buftype == "" and ruler or "",
      { scope = "local", win = win }
    )
  end,
})
