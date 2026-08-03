return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- Disable the cmp documentation popup (the function description that
  -- covers the line while you're typing arguments).
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      opts.window = opts.window or {}
      opts.window.documentation = false
      return opts
    end,
  },

  -- lazy.nvim merges opts index-by-index, so this list replaces NvChad's
  -- positionally -- its "luadoc" and "printf" have to be repeated here or they
  -- are silently dropped.
  --
  -- On nvim-treesitter's `main` branch `ensure_installed` is not a real option
  -- (setup() only takes install_dir); NvChad reads it from the merged opts in
  -- its :TSInstallAll command, which only runs from the plugin's build step.
  -- Adding a language here therefore needs a :TSInstall <lang> or :Lazy build
  -- nvim-treesitter to take effect.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "lua", "luadoc", "printf", "vim", "vimdoc",
        "html", "css", "zig",
      },
    },
  },

  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },

  -- {
  -- 	"nvim-treesitter/nvim-treesitter",
  -- 	opts = {
  -- 		ensure_installed = {
  -- 			"vim", "lua", "vimdoc",
  --      "html", "css"
  -- 		},
  -- 	},
  -- },
}
