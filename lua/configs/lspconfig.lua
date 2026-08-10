require("nvchad.configs.lspconfig").defaults()

local servers = { "html", "cssls" }
vim.lsp.enable(servers)

local zls_path = vim.fn.exepath("zls")
if zls_path ~= "" then
  vim.lsp.config("zls", {
    cmd = { zls_path },
    filetypes = { "zig", "zir" },
    root_markers = { "build.zig", "build.zig.zon", ".git" },
    on_init = function() end,  -- keep NvChad from stripping zls semantic tokens
    settings = {
      zls = {
        enable_inlay_hints = true,
        enable_snippets = true,
        warn_style = false, -- our project uses snake_case fns; zls only knows std's camelCase rule
      },
    },
  })

  vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*.zig",
    callback = function()
      vim.lsp.buf.format { async = false }
    end,
  })

  vim.lsp.enable("zls")
end
-- read :h vim.lsp.config for changing options of lsp servers
