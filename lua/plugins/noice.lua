return {
  {
    "folke/noice.nvim",
    lazy = false,
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    opts = {
      lsp = {
        signature = {
          auto_open = { enabled = false },
        },
      },

      cmdline = {
        view = "cmdline_popup",
      },

      views = {
        cmdline_popup = {
          relative = "editor",

          position = {
            row = 2,
            col = "90%", -- valid in Noice
          },

          size = {
            width = "40%", -- better than fixed 80 for responsiveness
            height = "auto",
          },

          border = {
            style = "rounded",
          },
        },
      },
    },
  },
}
