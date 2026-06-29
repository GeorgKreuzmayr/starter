return {
  {
    "gbprod/yanky.nvim",
    -- Load early so the TextYankPost hook is registered and yanks start
    -- getting recorded into the ring before you first paste.
    event = "VeryLazy",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      require("yanky").setup {}

      -- Browse the yank ring with Telescope.
      pcall(require("telescope").load_extension, "yank_history")

      local map = vim.keymap.set

      -- Yanky-aware paste (records into / reads from the ring).
      map({ "n", "x" }, "p", "<Plug>(YankyPutAfter)", { desc = "Paste after" })
      map({ "n", "x" }, "P", "<Plug>(YankyPutBefore)", { desc = "Paste before" })
      map({ "n", "x" }, "gp", "<Plug>(YankyGPutAfter)", { desc = "Paste after (move cursor)" })
      map({ "n", "x" }, "gP", "<Plug>(YankyGPutBefore)", { desc = "Paste before (move cursor)" })

      -- After pasting, cycle through older / newer entries in the ring.
      -- (<C-n> is left to NvChad's nvim-tree toggle, so "newer" lives on <M-n>.)
      map("n", "<C-p>", "<Plug>(YankyPreviousEntry)", { desc = "Cycle to older yank" })
      map("n", "<M-n>", "<Plug>(YankyNextEntry)", { desc = "Cycle to newer yank" })

      -- Paste from clipboard (unnamedplus -> "+ is the unnamed register).
      map({ "n", "x" }, "<leader>p", "<Plug>(YankyPutAfter)", { desc = "Paste from clipboard" })
      -- Visual paste that keeps the yanked text (deletes selection to black hole).
      map("x", "<leader>P", '"_dP', { desc = "Paste over selection (keep register)" })

      -- Open the yank-ring history picker.
      map("n", "<leader>yh", "<cmd>Telescope yank_history<CR>", { desc = "Yank history" })
    end,
  },
}
