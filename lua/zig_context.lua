-- zig_context.lua
-- Shows the current Zig struct / function scope in the winbar.
-- Place this file at:  ~/.config/nvim/lua/zig_context.lua
-- Then add to your init.lua or options.lua:
--   require("zig_context").setup()

local M = {}

-- ── helpers ──────────────────────────────────────────────────────────────────

--- Extract the IDENTIFIER name from a FnProto node.
local function fn_name(fnproto)
  for i = 0, fnproto:named_child_count() - 1 do
    local child = fnproto:named_child(i)
    if child:type() == "IDENTIFIER" then
      return vim.treesitter.get_node_text(child, 0)
    end
  end
end

--- Extract the IDENTIFIER name from a VarDecl node.
local function var_name(vardecl)
  for i = 0, vardecl:named_child_count() - 1 do
    local child = vardecl:named_child(i)
    if child:type() == "IDENTIFIER" then
      return vim.treesitter.get_node_text(child, 0)
    end
  end
end

--- Given a ContainerDecl node, find the name that owns it.
--- Returns a string or nil.
local function container_name(container)
  local ancestor = container:parent()
  while ancestor do
    local atype = ancestor:type()
    if atype == "VarDecl" then
      -- pub const <Name> = struct { … }
      return var_name(ancestor)
    elseif atype == "Decl" then
      -- fn <Name>(...) { return struct { … } }
      for i = 0, ancestor:named_child_count() - 1 do
        local sibling = ancestor:named_child(i)
        if sibling:type() == "FnProto" then
          return fn_name(sibling)
        end
      end
      return nil
    elseif atype == "source_file" then
      return nil
    end
    ancestor = ancestor:parent()
  end
end

--- Extract the string literal or identifier name from a TestDecl node.
local function test_name(testdecl)
  for i = 0, testdecl:named_child_count() - 1 do
    local child = testdecl:named_child(i)
    local t = child:type()
    if t == "STRINGLITERALSINGLE" or t == "StringLiteral" or t == "string_literal" then
      local raw = vim.treesitter.get_node_text(child, 0)
      -- strip surrounding quotes
      return raw:match('^"(.*)"$') or raw
    elseif t == "IDENTIFIER" then
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

  while current do
    local kind = current:type()

    if kind == "Block" then
      -- Collect the function this Block belongs to
      local decl = current:parent()
      if decl and decl:type() == "Decl" then
        for i = 0, decl:named_child_count() - 1 do
          local sibling = decl:named_child(i)
          if sibling:type() == "FnProto" then
            local name = fn_name(sibling)
            if name then
              table.insert(chain, { kind = "fn", name = name })
            end
            break
          end
        end
      end

    elseif kind == "FnProto" then
      -- Cursor is sitting directly on the fn signature line
      local name = fn_name(current)
      if name then
        -- Only add if not already added by the Block handler
        local already = false
        for _, entry in ipairs(chain) do
          if entry.kind == "fn" and entry.name == name then
            already = true; break
          end
        end
        if not already then
          table.insert(chain, { kind = "fn", name = name })
        end
      end

    elseif kind == "TestDecl" then
      -- Cursor is inside a test block
      local name = test_name(current)
      table.insert(chain, { kind = "test", name = name })

    elseif kind == "ContainerDecl" then
      -- Collect the struct/fn that owns this container
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
