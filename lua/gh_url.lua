local M = {}

-- Run a git command in the directory of the current file. Returns trimmed
-- stdout, or nil plus an error message on failure.
local function git(args)
  local file = vim.api.nvim_buf_get_name(0)
  local dir = file ~= "" and vim.fn.fnamemodify(file, ":h") or vim.fn.getcwd()
  local out = vim.fn.systemlist({ "git", "-C", dir, unpack(args) })
  if vim.v.shell_error ~= 0 then
    return nil, table.concat(out, "\n")
  end
  return vim.trim(out[1] or "")
end

-- Turn a git remote (ssh or https) into an https://github.com/owner/repo base.
local function remote_to_https(url)
  url = url:gsub("%.git$", "")
  -- git@github.com:owner/repo  or  ssh://git@github.com/owner/repo
  local host, path = url:match("^git@([^:]+):(.+)$")
  if not host then
    host, path = url:match("^ssh://git@([^/]+)/(.+)$")
  end
  if not host then
    -- https://github.com/owner/repo  (strip any embedded credentials)
    host, path = url:match("^https?://[^@]*@?([^/]+)/(.+)$")
  end
  if not host then
    return nil
  end
  return "https://" .. host .. "/" .. path
end

-- Build a GitHub permalink to the current line(s), pinned to HEAD's commit SHA.
-- `range` is an optional { first, last } pair of line numbers.
function M.copy(range)
  local remote, err = git({ "config", "--get", "remote.origin.url" })
  if not remote then
    return vim.notify("No git remote: " .. (err or "unknown"), vim.log.levels.ERROR)
  end

  local base = remote_to_https(remote)
  if not base then
    return vim.notify("Unrecognized remote URL: " .. remote, vim.log.levels.ERROR)
  end

  local sha = git({ "rev-parse", "HEAD" })
  if not sha or sha == "" then
    return vim.notify("Could not resolve HEAD commit", vim.log.levels.ERROR)
  end

  local root = git({ "rev-parse", "--show-toplevel" })
  local file = vim.api.nvim_buf_get_name(0)
  local rel = file:sub(#root + 2) -- strip "<root>/"

  local first = range and range.first or vim.fn.line(".")
  local last = range and range.last or first
  local frag = "#L" .. first
  if last > first then
    frag = frag .. "-L" .. last
  end

  local url = base .. "/blob/" .. sha .. "/" .. rel .. frag
  vim.fn.setreg("+", url)
  vim.notify("Copied: " .. url)
end

-- Open the commit that last touched the current line on GitHub.
function M.open_commit()
  local remote, err = git({ "config", "--get", "remote.origin.url" })
  if not remote then
    return vim.notify("No git remote: " .. (err or "unknown"), vim.log.levels.ERROR)
  end

  local base = remote_to_https(remote)
  if not base then
    return vim.notify("Unrecognized remote URL: " .. remote, vim.log.levels.ERROR)
  end

  local file = vim.api.nvim_buf_get_name(0)
  local line = vim.fn.line(".")
  -- Porcelain blame: first token of the first line is the commit SHA.
  local out, gerr = git({ "blame", "-L", line .. "," .. line, "--porcelain", "--", file })
  if not out then
    return vim.notify("git blame failed: " .. (gerr or "unknown"), vim.log.levels.ERROR)
  end

  local sha = out:match("^(%x+)")
  if not sha then
    return vim.notify("Could not parse commit from blame", vim.log.levels.ERROR)
  end
  if sha:match("^0+$") then
    return vim.notify("Line is not committed yet", vim.log.levels.WARN)
  end

  local url = base .. "/commit/" .. sha
  vim.ui.open(url)
  vim.notify("Opening " .. sha:sub(1, 10) .. " in browser")
end

return M
