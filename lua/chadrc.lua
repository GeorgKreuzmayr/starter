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
    Visual         = { bg = "one_bg2" },
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

    -- Black cursor
    Cursor     = { bg = "#002B36", fg = "#FDF6E3" },
    CursorIM   = { bg = "#002B36", fg = "#FDF6E3" },
    TermCursor = { bg = "#002B36", fg = "#FDF6E3" },
  },
}

return M
