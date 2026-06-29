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
          width = 0.95,          -- 95% of screen width
          height = 0.95,         -- 95% of screen height
          prompt_position = "top",

          horizontal = {
            preview_cutoff = 0,
          },
        },

        sorting_strategy = "ascending",
      },

      -- Live grep where you can append raw ripgrep flags to the query,
      -- e.g.  foo -g '*.lua'  or  foo -tpython  or  foo -g '!*_test.go'
      extensions_list = { "live_grep_args" },
      extensions = {
        live_grep_args = {
          auto_quoting = true,
        },
      },
    },
  },
}
