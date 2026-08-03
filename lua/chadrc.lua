-- ~/.config/nvim/lua/chadrc.lua
-- Solarized Light – faithful port of the VSCode token colors

---@type ChadrcConfig
local M = {}

-- Disable NvChad's LSP signature-help popup that appears when typing
-- a function call's opening paren (e.g. `std.log.info(`).
M.lsp = { signature = false }

M.base46 = {
  theme = "solarized_light_custom",

  -- Fine-tune syntax groups to match VSCode token colors exactly.
  -- All colour names below refer to the palette in solarized_light.lua.
  hl_override = {

    -- ── Editor chrome ────────────────────────────────────────────────
    Normal         = { bg = "black",        fg = "white" },
    NormalFloat    = { bg = "darker_black",  fg = "white" },
    LineNr         = { fg = "grey_fg" },
    CursorLineNr   = { fg = "light_grey",   bold = true },
    CursorLine     = { bg = "darker_black" },
    SignColumn     = { bg = "black" },
    WinSeparator   = { fg = "line" },

    -- ── Comments  (#93A1A1, italic) ──────────────────────────────────
    Comment        = { fg = "grey",  italic = true },
    ["@comment"]   = { fg = "grey",  italic = true },

    -- ── Strings  (#2AA198) ───────────────────────────────────────────
    String         = { fg = "cyan" },
    ["@string"]    = { fg = "cyan" },

    -- ── Numbers / booleans  (#D33682) ────────────────────────────────
    Number         = { fg = "pink" },
    Boolean        = { fg = "pink" },
    Float          = { fg = "pink" },
    ["@number"]    = { fg = "pink" },
    ["@boolean"]   = { fg = "pink" },

    -- ── Keywords  (#859900) ──────────────────────────────────────────
    Keyword        = { fg = "green" },
    Conditional    = { fg = "green" },
    Repeat         = { fg = "green" },
    Exception      = { fg = "green" },
    Operator       = { fg = "green" },
    ["@keyword"]   = { fg = "green" },
    ["@operator"]  = { fg = "green" },

    -- ── Storage (bold, #586E75) ──────────────────────────────────────
    StorageClass   = { fg = "light_grey", bold = true },
    Type           = { fg = "light_grey", bold = true },
    ["@type"]      = { fg = "light_grey", bold = true },
    ["@storageclass"] = { fg = "light_grey", bold = true },

    -- ── Functions / methods  (#268BD2) ──────────────────────────────
    Function       = { fg = "blue" },
    ["@function"]  = { fg = "blue" },
    ["@method"]    = { fg = "blue" },
    ["@function.call"]   = { fg = "blue" },
    ["@method.call"]     = { fg = "blue" },

    -- ── Variables  (#268BD2) ─────────────────────────────────────────
    Identifier     = { fg = "blue" },
    ["@variable"]  = { fg = "blue" },
    ["@parameter"] = { fg = "white" },   -- variable.parameter has no special colour in VSCode

    -- ── Class / type names  (#CB4B16) ────────────────────────────────
    ["@type.definition"]  = { fg = "orange" },
    ["@namespace"]        = { fg = "orange" },
    Structure      = { fg = "orange" },

    -- ── Constants  (#CB4B16) ─────────────────────────────────────────
    Constant       = { fg = "yellow" },  -- constant.language → #B58900
    ["@constant"]  = { fg = "yellow" },
    ["@constant.builtin"] = { fg = "yellow" },

    -- ── Inherited class / violet  (#6C71C4) ──────────────────────────
    ["@type.builtin"] = { fg = "purple" },

    -- ── Support / library functions  (#268BD2) ───────────────────────
    Special        = { fg = "blue" },
    ["@function.builtin"] = { fg = "blue" },

    -- ── Tags  (#268BD2) ──────────────────────────────────────────────
    Tag            = { fg = "blue" },
    ["@tag"]       = { fg = "blue" },
    ["@tag.attribute"] = { fg = "grey" },    -- entity.other.attribute-name → #93A1A1
    ["@tag.delimiter"] = { fg = "grey" },    -- punctuation.definition.tag  → #93A1A1

    -- ── Markup (markdown/rst) ────────────────────────────────────────
    ["@markup.heading"]   = { fg = "blue",   bold = true },
    ["@markup.strong"]    = { fg = "pink",   bold = true },
    ["@markup.italic"]    = { fg = "pink",   italic = true },
    ["@markup.raw"]       = { fg = "cyan" },
    ["@markup.list"]      = { fg = "yellow" },
    ["@markup.quote"]     = { fg = "green" },
    ["@markup.link"]      = { fg = "blue" },

    -- ── Diff ─────────────────────────────────────────────────────────
    DiffAdd        = { fg = "green" },
    DiffDelete     = { fg = "red" },
    DiffChange     = { fg = "orange" },
    DiffText       = { fg = "blue",  italic = true },

    -- ── Diagnostics ──────────────────────────────────────────────────
    DiagnosticError = { fg = "red" },
    DiagnosticWarn  = { fg = "yellow" },
    DiagnosticInfo  = { fg = "blue" },
    DiagnosticHint  = { fg = "cyan" },

    -- ── Cursor / selection ───────────────────────────────────────────
    -- Dark cursor, and a selection strong enough to read on cream.
    -- `guicursor` binds the Cursor group explicitly (see init.lua),
    -- otherwise the terminal keeps its own cursor colour.
    Cursor         = { bg = "#002B36", fg = "#FDF6E3" },
    Visual         = { bg = "#93A1A1", fg = "#FDF6E3" },
    VisualNOS      = { bg = "#93A1A1", fg = "#FDF6E3" },

    -- ── Dashboard ────────────────────────────────────────────────────
    -- base46 defaults the footer to red, which shouts on a light bg.
    NvDashFooter   = { fg = "grey" },
  },

  -- hl_override only reaches groups base46 already defines, and silently
  -- drops the rest. CursorIM / TermCursor aren't in base46's defaults, so
  -- they have to be *added* rather than overridden.
  hl_add = {
    CursorIM   = { bg = "#002B36", fg = "#FDF6E3" },
    TermCursor = { bg = "#002B36", fg = "#FDF6E3" },
  },
}

M.ui = {
  statusline = {
    theme = "default",
    separator_style = "round",
  },

  -- Bordered so the picker reads as a panel floating over the buffer
  -- instead of a full-screen wash of the same cream (see plugins/telescope.lua
  -- for the matching rounded border characters and reduced size).
  telescope = { style = "bordered" },
}

M.nvdash = {
  load_on_startup = true,

  header = {
    "                                 ",
    "███╗   ██╗██╗   ██╗██╗███╗   ███╗",
    "████╗  ██║██║   ██║██║████╗ ████║",
    "██╔██╗ ██║██║   ██║██║██╔████╔██║",
    "██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║",
    "██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║",
    "╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝",
    "                                 ",
  },

  -- Keys match this config's actual mappings, not NvChad's defaults.
  buttons = {
    { txt = "  Find File", keys = "<leader><leader>", cmd = "Telescope find_files" },
    { txt = "  Recent Files", keys = "<leader>fo", cmd = "Telescope oldfiles" },
    { txt = "󰈭  Live Grep", keys = "<leader>fw", cmd = "Telescope live_grep" },
    {
      txt = "󰺯  Grep (rg args)",
      keys = "<leader>fW",
      cmd = "lua require('telescope').extensions.live_grep_args.live_grep_args()",
    },
    -- No `keys`: there's no global mapping for this, and nvdash would try to
    -- register an empty LHS. Still reachable with <CR> on the line.
    { txt = "  Config", cmd = "edit " .. vim.fn.stdpath "config" .. "/lua/chadrc.lua" },
    { txt = "󱥚  Themes", keys = "<leader>th", cmd = "lua require('nvchad.themes').open()" },
    { txt = "  Mappings", keys = "<leader>ch", cmd = "NvCheatsheet" },

    { txt = "─", hl = "NvDashFooter", no_gap = true, rep = true },

    {
      txt = function()
        local stats = require("lazy").stats()
        return ("  %d/%d plugins in %d ms"):format(
          stats.loaded,
          stats.count,
          math.floor(stats.startuptime)
        )
      end,
      hl = "NvDashFooter",
      no_gap = true,
      content = "fit",
    },

    { txt = "─", hl = "NvDashFooter", no_gap = true, rep = true },
  },
}

return M
