return {
  {
    "nvim-telescope/telescope.nvim",
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
    },
  },
}
