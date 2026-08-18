-- Commit staged changes from a buffer: <leader>gc opens a scratch buffer
-- prefilled the way `git commit` prefills its editor, and writing the buffer
-- (:w) makes the commit. Leaving without writing aborts, like quitting git's
-- editor does.
--
-- The message is piped to `git commit -F -` rather than written to
-- <gitdir>/COMMIT_EDITMSG: git rewrites that file as part of committing, so a
-- buffer backed by it would sit on a changed-on-disk prompt after a rejected
-- message.

local M = {}

-- Run a git command in `cwd`. Returns trimmed stdout, or nil plus git's error
-- output. (gh_url.lua and git_diff.lua keep their own runners the same way.)
local function git(args, cwd)
  local res = vim.system(vim.list_extend({ "git" }, args), { cwd = cwd }):wait()
  if res.code ~= 0 then
    return nil, vim.trim(res.stderr or "")
  end
  return vim.trim(res.stdout or "")
end

-- An empty first line to type on, then the status as comments -- the same
-- shape git uses. advice.statusHints=false drops the "(use git restore ...)"
-- lines, as git's own template does.
local function template(root)
  local lines = {
    "",
    "# Please enter the commit message for your changes. Lines starting with",
    "# '#' will be ignored, and an empty message aborts the commit.",
    "#",
  }
  local status = git({ "-c", "advice.statusHints=false", "status" }, root) or ""
  for _, line in ipairs(vim.split(status, "\n")) do
    lines[#lines + 1] = vim.trim("# " .. line)
  end
  return lines
end

function M.commit()
  local file = vim.api.nvim_buf_get_name(0)
  local cwd = file ~= "" and vim.fn.fnamemodify(file, ":h") or vim.fn.getcwd()

  local root, root_err = git({ "rev-parse", "--show-toplevel" }, cwd)
  if not root then
    return vim.notify("Not a git repository: " .. (root_err or "unknown"), vim.log.levels.ERROR)
  end

  local staged = git({ "diff", "--cached", "--name-only" }, root)
  if staged == "" then
    return vim.notify("Nothing staged -- stage files with <leader>gd, then <Tab>", vim.log.levels.WARN)
  end

  vim.cmd "botright new"
  local bufnr = vim.api.nvim_get_current_buf()

  -- No swap file: nothing backs this buffer, and one named COMMIT_EDITMSG
  -- left behind by an earlier session would greet the next commit with a
  -- swap-file prompt.
  vim.bo[bufnr].swapfile = false
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, template(root))

  -- acwrite: the buffer has no file behind it, so :w is ours to carry out.
  vim.bo[bufnr].buftype = "acwrite"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].filetype = "gitcommit"
  vim.bo[bufnr].modified = false
  pcall(vim.api.nvim_buf_set_name, bufnr, "COMMIT_EDITMSG")
  vim.api.nvim_win_set_height(0, 15)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })

  -- --cleanup=strip is what drops the comment lines; -F on its own would keep
  -- them verbatim. A rejected message (empty, or a commit-msg hook saying no)
  -- leaves the buffer modified and open, to fix and write again.
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = bufnr,
    desc = "Commit the message in this buffer",
    callback = function()
      local msg = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
      local res = vim.system({ "git", "commit", "--cleanup=strip", "-F", "-" }, { cwd = root, stdin = msg }):wait()

      if res.code ~= 0 then
        local err = vim.trim((res.stderr or "") .. (res.stdout or ""))
        vim.notify("git commit: " .. err, vim.log.levels.ERROR)
        -- Not `return vim.notify(...)`: a callback that returns truthy (which
        -- noice's notify does) deletes the autocommand, and the next :w would
        -- do nothing at all.
        return
      end

      vim.bo[bufnr].modified = false
      vim.notify(vim.split(vim.trim(res.stdout or ""), "\n")[1])
      vim.schedule(function()
        pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
      end)
    end,
  })
end

return M
