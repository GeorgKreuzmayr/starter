return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-telescope/telescope-live-grep-args.nvim",
    },
    opts = {
      defaults = {
        layout_strategy = "horizontal",

        layout_config = {
          width = 0.85,          -- leaves the buffer visible around the picker
          height = 0.80,
          prompt_position = "top",

          horizontal = {
            preview_cutoff = 0,  -- always show the preview, however narrow
          },
        },

        sorting_strategy = "ascending",

        -- Rounded corners to match `winborder` and the noice cmdline popup.
        -- Order: top, right, bottom, left, then the four corners clockwise.
        borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
      },

      -- Live grep where you can append raw ripgrep flags to the query,
      -- e.g.  foo -g '*.lua'  or  foo -tpython  or  foo -g '!*_test.go'
      --
      -- NvChad registers "themes" and "terms" here; lazy.nvim merges opts
      -- index-by-index, so listing only live_grep_args would silently
      -- displace "themes". All three have to be named explicitly.
      extensions_list = { "themes", "terms", "live_grep_args" },
      extensions = {
        live_grep_args = {
          auto_quoting = true,
        },
      },
    },
  },
}
