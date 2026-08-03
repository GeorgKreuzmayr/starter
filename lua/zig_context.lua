-- zig_context.lua
-- Shows the current Zig struct / function scope in the winbar.
-- Place this file at:  ~/.config/nvim/lua/zig_context.lua
-- Then add to your init.lua or options.lua:
--   require("zig_context").setup()

local M = {}

-- ── helpers ──────────────────────────────────────────────────────────────────

-- Container nodes that take their name from whatever declares them. The old
-- tree-sitter-zig grammar rolled all of these into a single `ContainerDecl`.
local container_types = {
  struct_declaration = true,
  enum_declaration = true,
  union_declaration = true,
  opaque_declaration = true,
  error_set_declaration = true,
}

--- Text of a node's `name:` field. `function_declaration` has one; container
--- and variable declarations do not.
local function field_name(node)
  local field = node:field("name")[1]
  return field and vim.treesitter.get_node_text(field, 0) or nil
end

--- First identifier child, for nodes without a `name:` field.
local function first_identifier(node)
  for child in node:iter_children() do
    if child:type() == "identifier" then
      return vim.treesitter.get_node_text(child, 0)
    end
  end
end

--- The name a container is declared under: `const <Name> = struct { … }`.
--- A container returned from a generic fn (`fn F(...) type { return struct { … } }`)
--- gets no name of its own — the enclosing function_declaration is already
--- picked up by the walker, so naming it here would just repeat it.
local function container_name(container)
  local parent = container:parent()
  if parent and parent:type() == "variable_declaration" then
    return first_identifier(parent)
  end
end

--- Name of a test_declaration: `test "some name"` or `test some_decl`.
local function test_name(testdecl)
  for child in testdecl:iter_children() do
    local t = child:type()
    if t == "string" then
      -- string_content is the text inside the quotes
      for grandchild in child:iter_children() do
        if grandchild:type() == "string_content" then
          return vim.treesitter.get_node_text(grandchild, 0)
        end
      end
      local raw = vim.treesitter.get_node_text(child, 0)
      return raw:match '^"(.*)"$' or raw
    elseif t == "identifier" then
      return vim.treesitter.get_node_text(child, 0)
    end
  end
  return "<test>"
end

--- Walk up the tree and collect the full scope chain as a list of strings,
--- innermost first. E.g. { "some_fn", "SomeName", "ReplicaType" }
local function get_zig_context()
  local ok, parser = pcall(vim.treesitter.get_parser, 0, "zig")
  if not ok or not parser then return {} end

  local trees = parser:parse()
  if not trees or not trees[1] then return {} end

  local root = trees[1]:root()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1

  local node = root:named_descendant_for_range(row, col, row, col)
  if not node then return {} end

  local chain = {}
  local current = node

  -- The signature line and the body are both inside function_declaration, so a
  -- single walk up from the cursor hits each enclosing declaration exactly once.
  while current do
    local kind = current:type()

    if kind == "function_declaration" then
      local name = field_name(current)
      if name then
        table.insert(chain, { kind = "fn", name = name })
      end

    elseif kind == "test_declaration" then
      table.insert(chain, { kind = "test", name = test_name(current) })

    elseif container_types[kind] then
      local name = container_name(current)
      if name then
        table.insert(chain, { kind = "struct", name = name })
      end
    end

    current = current:parent()
  end

  return chain
end

-- ── winbar rendering ─────────────────────────────────────────────────────────
local function update_winbar()
  local rel = vim.fn.expand("%:~:.")

  -- non-zig: just show path, no icon
  if vim.bo.filetype ~= "zig" then
    vim.wo.winbar = "%#WinBarZigSep#" .. rel .. "%*"
    return
  end

  local chain = get_zig_context()
  local path_prefix = "%#WinBarZigIcon#  󰚊  %*%#WinBarZigSep#" .. rel .. "%*"

  if #chain == 0 then
    vim.wo.winbar = path_prefix
    return
  end

  -- chain is innermost-first; reverse so outermost is on the left
  local reversed = {}
  for i = #chain, 1, -1 do
    table.insert(reversed, chain[i])
  end

  local parts = {}
  for i, entry in ipairs(reversed) do
    if i > 1 then
      table.insert(parts, "%#WinBarZigSep#::")
    end
    if entry.kind == "struct" then
      table.insert(parts, "%#WinBarZigStruct#" .. entry.name)
    elseif entry.kind == "test" then
      table.insert(parts, "%#WinBarZigTest#" .. entry.name)
    else
      table.insert(parts, "%#WinBarZigFn#" .. entry.name)
    end
  end

  vim.wo.winbar = path_prefix .. "%#WinBarZigSep#::%*" .. table.concat(parts, "") .. "%#WinBarZigSep# %*"
end

-- ── highlight groups ─────────────────────────────────────────────────────────

local function define_highlights()
  -- Solarized "base2" — the same tone the statusline uses, so the winbar
  -- reads as a light-grey bar instead of a black strip.
  --
  -- NOTE: we deliberately do *not* read Normal's bg here. setup() runs before
  -- base46 loads its highlights (see init.lua), so at that point Normal is
  -- undefined and the read returns "NONE" (a transparent bar that shows the
  -- terminal's dark background through it). An explicit colour avoids that.
  local bg = "#EEE8D5"

  vim.api.nvim_set_hl(0, "WinBar",          { bg = bg,   bold = false })
  vim.api.nvim_set_hl(0, "WinBarNC",        { bg = bg,   bold = false })
  vim.api.nvim_set_hl(0, "WinBarZigIcon",   { fg = "#CB4B16", bg = bg, bold = true  })
  vim.api.nvim_set_hl(0, "WinBarZigStruct", { fg = "#657B83", bg = bg, bold = true  })
  vim.api.nvim_set_hl(0, "WinBarZigSep",    { fg = "#93A1A1", bg = bg, bold = false })
  vim.api.nvim_set_hl(0, "WinBarZigFn",     { fg = "#268BD2", bg = bg, bold = true  })
  vim.api.nvim_set_hl(0, "WinBarZigTest",   { fg = "#859900", bg = bg, bold = true  })
end

-- ── public setup ─────────────────────────────────────────────────────────────

function M.setup(opts)
  opts = opts or {}

  define_highlights()

  -- base46 loads its highlights via dofile *after* setup() runs and never
  -- fires the ColorScheme event, so re-apply on the next tick to make sure our
  -- WinBar colours win over base46's defaults.
  vim.schedule(define_highlights)

  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = define_highlights,
  })

  local uv = vim.uv or vim.loop
  local timer = uv.new_timer()

  local function schedule_update()
    timer:stop()
    timer:start(80, 0, vim.schedule_wrap(update_winbar))
  end

  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufEnter", "WinEnter" }, {
    pattern  = "*.zig",
    callback = schedule_update,
  })

  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    pattern  = "*",
    callback = function()
      if vim.bo.filetype ~= "zig" then
        vim.wo.winbar = ""
      end
    end,
  })
end

return M
