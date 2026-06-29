-- Treesitter-aware fold helpers.
-- The folds themselves come from `vim.treesitter.foldexpr()` (see options.lua);
-- these helpers selectively *close* folds that belong to a given node category.

local M = {}

-- Node types that represent a function definition, keyed by treesitter language.
local fn_node_types = {
  zig = { FnProto = true },
  lua = { function_declaration = true, function_definition = true },
  c = { function_definition = true },
  cpp = { function_definition = true },
  rust = { function_item = true },
  go = { function_declaration = true, method_declaration = true },
  python = { function_definition = true },
  javascript = { function_declaration = true, method_definition = true, arrow_function = true },
  typescript = { function_declaration = true, method_definition = true, arrow_function = true },
}

local function collect(node, types, acc)
  for child in node:iter_children() do
    if child:named() then
      if types[child:type()] then
        acc[#acc + 1] = child
      end
      collect(child, types, acc)
    end
  end
end

-- Close the fold at the first line of every function in the buffer, leaving
-- everything else (structs, top-level if-blocks, etc.) expanded.
function M.fold_all_functions()
  local ok, parser = pcall(vim.treesitter.get_parser, 0)
  if not ok or not parser then
    vim.notify("No treesitter parser for this buffer", vim.log.levels.WARN)
    return
  end

  local lang = parser:lang()
  local types = fn_node_types[lang]
  if not types then
    vim.notify("Function folding not configured for language: " .. lang, vim.log.levels.WARN)
    return
  end

  local root = parser:parse()[1]:root()
  local nodes = {}
  collect(root, types, nodes)

  vim.cmd "normal! zR" -- open everything first so only functions end up folded
  for _, node in ipairs(nodes) do
    local srow = node:start() -- 0-indexed row of the signature line
    pcall(vim.cmd, string.format("%dfoldclose", srow + 1))
  end
end

return M
