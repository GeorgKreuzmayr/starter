-- In-buffer markdown rendering: headings, code blocks, tables, lists and
-- checkboxes are drawn with virtual text instead of raw syntax.
-- Toggle with <leader>mr (see mappings.lua).

-- Solarized Light palette (matches lua/themes/solarized_light_custom.lua)
local base3 = "#FDF6E3" -- main background
local base2 = "#EEE8D5" -- background highlights
local base1 = "#93A1A1" -- subtle / secondary
local base00 = "#657B83" -- body text
local yellow = "#B58900"
local orange = "#CB4B16"
local magenta = "#D33682"
local violet = "#6C71C4"
local blue = "#268BD2"
local cyan = "#2AA198"
local green = "#859900"

-- Accents blended into base3 so heading bands stay readable on cream.
local h_bg = {
  "#D6E3E0", -- 1: blue
  "#DFDFAA", -- 2: green
  "#F0E2BA", -- 3: yellow
  "#F4D7BE", -- 4: orange
  "#F5D3D2", -- 5: magenta
  "#D9D5DB", -- 6: violet
}
local h_fg = { blue, green, yellow, orange, magenta, violet }

-- The plugin registers its groups with `default = true`, so these explicit
-- definitions win. Re-applied on ColorScheme since base46 rewrites highlights
-- whenever the theme is reloaded.
local function highlights()
  local hl = function(group, opts)
    vim.api.nvim_set_hl(0, "RenderMarkdown" .. group, opts)
  end

  for i = 1, 6 do
    hl("H" .. i, { fg = h_fg[i], bold = true })
    hl("H" .. i .. "Bg", { bg = h_bg[i] })
  end

  hl("Code", { bg = base2 })
  -- language label sits on the code block's header strip, so it needs its bg
  hl("CodeInfo", { fg = base1, bg = base2, italic = true })
  hl("CodeInline", { bg = base2, fg = cyan })
  hl("CodeFallback", { bg = base2, fg = base00 })

  hl("Bullet", { fg = yellow })
  hl("Dash", { fg = base1 })
  hl("Quote", { fg = green })
  hl("Math", { fg = violet })
  hl("Indent", { fg = "#E8E2CE" })

  hl("Link", { fg = blue, underline = true })
  hl("LinkTitle", { fg = blue })
  hl("WikiLink", { fg = blue, underline = true })

  hl("Unchecked", { fg = base1 })
  hl("Checked", { fg = green })
  hl("Todo", { fg = orange, bold = true })

  hl("TableHead", { fg = blue, bold = true })
  hl("TableRow", { fg = base00 })

  hl("Sign", { fg = base1, bg = base3 })
end

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    ft = { "markdown" },

    opts = {
      -- Rendered while reading; drops back to raw source the moment you insert.
      render_modes = { "n", "c", "t" },

      -- Show the raw text of whatever line the cursor is on, so editing a
      -- heading or link never fights the virtual text.
      anti_conceal = { enabled = true, above = 0, below = 0 },

      heading = {
        sign = false,
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
        width = "block",
        min_width = 50,
        left_pad = 0,
        right_pad = 2,
        border = false,
      },

      code = {
        sign = false,
        width = "block",
        min_width = 60,
        left_pad = 2,
        right_pad = 2,
        border = "thin",
        language_pad = 2,
        language_name = true,
        language_icon = true,
      },

      bullet = {
        icons = { "●", "○", "◆", "◇" },
      },

      checkbox = {
        unchecked = { icon = "󰄱 " },
        checked = { icon = "󰄲 " },
      },

      quote = { icon = "▎" },
      dash = { icon = "─" },

      pipe_table = { preset = "round" },

      link = {
        image = "󰥶 ",
        hyperlink = "󰌷 ",
      },

      sign = { enabled = false },
    },

    config = function(_, opts)
      require("render-markdown").setup(opts)
      highlights()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("RenderMarkdownSolarized", { clear = true }),
        callback = highlights,
      })
    end,
  },
}
