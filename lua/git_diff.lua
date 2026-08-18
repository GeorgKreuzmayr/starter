-- Telescope picker over `git diff HEAD`: the changed files on the left, the
-- unified diff of the highlighted one in the preview pane. <CR> opens that
-- diff full-width in its own buffer (q closes it) rather than opening the
-- file; the file is one click -- or <CR> -- away from any line of either
-- view, which lands on the line that line of the diff belongs to.
--
-- Every diff is rendered by git's own pager, so it looks exactly like
-- `git diff` in a shell, delta config and all.
--
-- NvChad binds <leader>gt to Telescope's git_status, which lists `git status`
-- (so also untracked files) and previews with `git diff HEAD`. This lists
-- exactly what `git diff HEAD` reports, so the file list and the preview
-- always agree.

local M = {}

-- Run a git command from the directory of the current file (falling back to
-- cwd) so the picker follows whichever repo the buffer lives in. Returns raw
-- stdout, or nil plus git's error output.
--
-- vim.system rather than vim.fn.system: `--name-status -z` separates records
-- with NUL bytes, which Vim strings cannot hold -- vim.fn.system silently
-- rewrites every one of them to \1.
local function git(args, cwd)
  local file = vim.api.nvim_buf_get_name(0)
  local dir = cwd or (file ~= "" and vim.fn.fnamemodify(file, ":h") or vim.fn.getcwd())
  local res = vim.system(vim.list_extend({ "git" }, args), { cwd = dir }):wait()
  if res.code ~= 0 then
    return nil, vim.trim(res.stderr or "")
  end
  return res.stdout or ""
end

-- Parse `--name-status -z` output. Records are NUL-separated: a status record
-- followed by its path, except renames/copies (R100, C75) which carry two
-- paths, source then destination.
local function parse_name_status(out)
  local records = vim.split(out, "\0", { plain = true })
  local files = {}
  local i = 1

  while records[i] and records[i] ~= "" do
    local status = records[i]
    i = i + 1
    local path = records[i]
    i = i + 1
    local from = nil

    if status:match("^[RC]") and records[i] and records[i] ~= "" then
      from, path = path, records[i]
      i = i + 1
    end

    if path and path ~= "" then
      files[#files + 1] = { status = status, path = path, from = from }
    end
  end

  return files
end

-- Paths reported by a `git diff` invocation, as a set. `--name-only -z` names
-- the destination of a rename, which is the path entries are keyed by.
local function path_set(root, args)
  local out = git(vim.list_extend({ "diff" }, args), root)
  local set = {}
  for _, path in ipairs(vim.split(out or "", "\0", { plain = true })) do
    if path ~= "" then
      set[path] = true
    end
  end
  return set
end

-- Delta wraps every line number (and the file header) in an OSC 8 hyperlink
-- when delta.hyperlinks is on. We ask it for the same nvim://<path>:<line>
-- URI that ~/.config/fish/functions/zigtest.fish emits, and then consume the
-- links here rather than letting them reach the host terminal: outside a
-- picker that URI is handled by NvimHandler.app -> nvim-open-handler, which
-- tmux send-keys ":e +<line> <path>" into the nvim pane -- and typing that
-- into a telescope prompt would just filter the list. Inside nvim the jump is
-- ours to make directly.
--
-- Strip the escapes out of one rendered line and report which display columns
-- each hyperlink covered. Returns the cleaned line and its spans.
local function extract_links(line)
  if not line:find("\27]8;;", 1, true) then
    return line, {}
  end

  local out, spans = {}, {}
  local col, url, from = 0, nil, nil
  local i, n = 1, #line

  local function text(run)
    out[#out + 1] = run
    col = col + vim.fn.strdisplaywidth(run)
  end

  while i <= n do
    local esc = line:find("\27", i, true)
    if not esc then
      text(line:sub(i))
      break
    end
    if esc > i then
      text(line:sub(i, esc - 1))
      i = esc
    end

    -- delta terminates with ST (ESC backslash); BEL is the other legal one.
    local uri, after = line:match("^\27%]8;;(.-)\27\\()", i)
    if not uri then
      uri, after = line:match("^\27%]8;;(.-)\7()", i)
    end
    if uri then
      if url then
        spans[#spans + 1] = { from = from, to = col - 1, url = url }
      end
      url = uri ~= "" and uri or nil
      from = col
      i = after
    else
      -- Any other escape sequence (colours, mostly): keep it, it has no width.
      local _, last = line:find("^\27%[[%d;:?]*[ -/]*[@-~]", i)
      last = last or math.min(i + 1, n)
      out[#out + 1] = line:sub(i, last)
      i = last + 1
    end
  end

  if url then
    spans[#spans + 1] = { from = from, to = col - 1, url = url }
  end

  return table.concat(out), spans
end

-- nvim:///abs/path:42 -> "/abs/path", 42
local function link_target(url)
  local path, lnum = url:match("^nvim://(/.-):(%d+)$")
  if not path then
    return nil
  end
  path = path:gsub("%%(%x%x)", function(hex)
    return string.char(tonumber(hex, 16))
  end)
  return path, tonumber(lnum)
end

-- The link a click landed on: the span under the cursor, else the nearest one
-- to its left, else the row's first. Delta hyperlinks only the line-number
-- cells, so this is what makes a click anywhere along a diff row work.
local function link_at(bufnr, spans, pos)
  local line = vim.api.nvim_buf_get_lines(bufnr, pos.line - 1, pos.line, false)[1] or ""
  -- pos.column is a byte index, and 0 when the click is past end of line.
  local col = pos.column > 0 and vim.fn.strdisplaywidth(line:sub(1, pos.column - 1)) or math.huge

  local best
  for _, span in ipairs(spans) do
    if col >= span.from and col <= span.to then
      return span.url
    end
    if col > span.to and (not best or span.to > best.to) then
      best = span
    end
  end
  return (best or spans[1]).url
end

-- The git arguments that produce an entry's diff: a commit for the log
-- picker, a path against HEAD for the working-tree one. A rename needs both
-- of its paths, or git -- given only the destination -- reports a fresh file.
local function diff_args(entry)
  if entry.sha then
    return { "show", entry.sha }
  end

  local args = { "diff", "HEAD", "--" }
  if entry.from then
    args[#args + 1] = entry.from
  end
  args[#args + 1] = entry.value
  return args
end

-- Render an entry's diff into `bufnr` through git's own pager, sized to
-- `winid`, and record each row's hyperlink spans in `rows`.
--
-- git only pipes to core.pager when its stdout is a tty, so the job runs on
-- a pty; its width is what delta lays the side-by-side columns out to, hence
-- the window's width. The raw bytes are replayed into a terminal channel on
-- the buffer, which is what turns delta's ANSI escapes into real colours.
-- Going through nvim_open_term rather than a termopen previewer keeps this an
-- ordinary buffer: no "[Process exited 0]" line, and window scrolling (which
-- is also telescope's preview scrolling) still works.
--
-- PAGER/DELTA_PAGER=cat stop the pager from starting *its* pager (less) at
-- the far end of that pty, where it would sit waiting for keys.
local function render_diff(bufnr, winid, root, entry, rows)
  -- hyperlinks are forced on (and pinned to a URI we can parse) so following
  -- them does not depend on delta.hyperlinks in ~/.gitconfig.
  local cmd = vim.list_extend({
    "git",
    "-c",
    "delta.hyperlinks=true",
    "-c",
    "delta.hyperlinks-file-link-format=nvim://{path}:{line}",
  }, diff_args(entry))

  local chan = vim.api.nvim_open_term(bufnr, {})
  local row, pending = 0, ""

  -- Feed complete lines only: an OSC 8 sequence may straddle two chunks.
  local function render(chunk, flush)
    if flush and pending == "" then
      return -- output ended on a newline, nothing left over
    end
    pending = pending .. chunk[1]
    local out = {}
    for i = 2, #chunk + (flush and 1 or 0) do
      local clean, spans = extract_links(pending)
      row = row + 1
      if #spans > 0 then
        rows[row] = spans
      end
      out[#out + 1] = clean
      pending = chunk[i] or ""
    end
    if #out > 0 then
      pcall(vim.api.nvim_chan_send, chan, table.concat(out, "\n") .. "\n")
    end
  end

  return vim.fn.jobstart(cmd, {
    cwd = root,
    pty = true,
    width = vim.api.nvim_win_get_width(winid),
    height = vim.api.nvim_win_get_height(winid),
    env = { PAGER = "cat", DELTA_PAGER = "cat", TERM = "xterm-256color", COLORTERM = "truecolor" },
    on_stdout = function(_, data)
      -- jobstart splits the pty stream on \n; the separators are put back in
      -- render(), which also lifts the hyperlinks out of the text.
      render(data, false)
    end,
    -- A terminal leaves the cursor after the last line written, so the view
    -- would open showing the tail of the diff. Rewind it once the output is
    -- in; buffers are kept, so this runs only on the first render.
    on_exit = function()
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(bufnr) then
          render({ "" }, true)
          vim.api.nvim_buf_call(bufnr, function()
            vim.cmd "normal! gg"
          end)
        end
      end)
    end,
  })
end

-- The file and line a position in a rendered diff points at, or nil.
local function resolve(bufnr, rows, pos)
  local spans = rows[pos.line]
  if not spans then
    return nil -- hunk box or blank row: nothing to jump to
  end
  return link_target(link_at(bufnr, spans, pos))
end

-- Show one file's diff in the current window -- the same rendering as the
-- preview, at full width -- instead of opening the file itself.
local function open_diff(root, entry)
  local winid = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_create_buf(false, true)

  -- Name it before it becomes a terminal buffer, so the statusline says what
  -- this is. A second view of the same file would collide, hence the pcall.
  pcall(vim.api.nvim_buf_set_name, bufnr, "git diff " .. (entry.sha or entry.value))
  vim.api.nvim_win_set_buf(winid, bufnr)

  local rows = {}
  render_diff(bufnr, winid, root, entry, rows)
  vim.bo[bufnr].bufhidden = "wipe"

  local function follow(pos)
    local path, lnum = resolve(bufnr, rows, pos)
    if path then
      vim.cmd(string.format("edit +%d %s", lnum, vim.fn.fnameescape(path)))
    end
  end

  vim.keymap.set("n", "q", "<cmd>bdelete!<cr>", { buffer = bufnr, desc = "Close diff view" })
  vim.keymap.set("n", "<CR>", function()
    local lnum, col = unpack(vim.api.nvim_win_get_cursor(0))
    follow { line = lnum, column = col + 1 }
  end, { buffer = bufnr, desc = "Open file at this diff line" })
  vim.keymap.set("n", "<LeftMouse>", function()
    local pos = vim.fn.getmousepos()
    if pos.winid ~= 0 and vim.api.nvim_win_get_buf(pos.winid) == bufnr then
      follow(pos)
    end
  end, { buffer = bufnr, desc = "Open file at the clicked diff line" })
end

-- The previewer both pickers use: each entry's diff, rendered by delta.
-- Returns it together with the bufnr -> rows map the click handling reads.
local function diff_previewer(root)
  local previewers = require "telescope.previewers"
  local jobs = {}
  local links = {} -- bufnr -> row -> hyperlink spans, filled while rendering

  local previewer = previewers.new_buffer_previewer {
    title = "Git Diff Preview",

    get_buffer_by_name = function(_, entry)
      return entry.sha or entry.value
    end,

    teardown = function()
      for _, id in ipairs(jobs) do
        vim.fn.jobstop(id)
      end
      jobs, links = {}, {}
    end,

    define_preview = function(self, entry)
      -- Cached buffer from a previous visit: the diff is already rendered.
      if vim.bo[self.state.bufnr].buftype == "terminal" then
        return
      end

      local rows = {}
      links[self.state.bufnr] = rows
      jobs[#jobs + 1] = render_diff(self.state.bufnr, self.state.winid, root, entry, rows)
    end,
  }

  return previewer, links
end

-- Mappings shared by both pickers: <CR> opens the diff full-width instead of
-- the file, and a click in the preview follows that line into the file.
local function attach_common(prompt_bufnr, root, links)
  local actions = require "telescope.actions"
  local state = require "telescope.actions.state"

  actions.select_default:replace(function()
    local entry = state.get_selected_entry()
    actions.close(prompt_bufnr)
    if entry then
      open_diff(root, entry)
    end
  end)

  -- nvim owns the mouse (see 'mouse'), so the click never reaches the host
  -- terminal's own hyperlink handling -- which is what we want, since the
  -- jump is into this very editor.
  vim.keymap.set({ "i", "n" }, "<LeftMouse>", function()
    local pos = vim.fn.getmousepos()
    local buf = pos.winid ~= 0 and vim.api.nvim_win_get_buf(pos.winid)
    local spans = buf and links[buf]

    if not spans then
      -- Not the preview. Re-feeding <LeftMouse> is not an option: a
      -- synthesized click carries no position and lands outside the floats,
      -- which drops focus and tears the picker down. Place the cursor when
      -- the click was in the prompt, swallow it otherwise.
      if pos.winid == vim.api.nvim_get_current_win() then
        local text = vim.api.nvim_get_current_line()
        local col = pos.column > 0 and pos.column - 1 or #text
        pcall(vim.api.nvim_win_set_cursor, pos.winid, { pos.line, col })
      end
      return
    end

    local path, lnum = resolve(buf, spans, pos)
    if not path then
      return
    end

    actions.close(prompt_bufnr)
    vim.cmd(string.format("edit +%d %s", lnum, vim.fn.fnameescape(path)))
  end, { buffer = prompt_bufnr })
end

local status_hl = {
  A = "DiffAdd",
  D = "DiffDelete",
  R = "DiffChange",
  C = "DiffChange",
}

function M.pick()
  local root, root_err = git { "rev-parse", "--show-toplevel" }
  if not root then
    return vim.notify("Not a git repository: " .. (root_err or "unknown"), vim.log.levels.ERROR)
  end
  root = vim.trim(root)

  -- Re-run after staging. Usually only the markers change -- a staged file
  -- still differs from HEAD -- but unstaging a rename drops its destination
  -- off the list, since that path goes back to being untracked.
  local function collect()
    local out, err = git({ "diff", "HEAD", "--name-status", "-z" }, root)
    if not out then
      return nil, err
    end

    local staged = path_set(root, { "--cached", "--name-only", "-z" })
    local dirty = path_set(root, { "--name-only", "-z" })

    local files = parse_name_status(out)
    for _, file in ipairs(files) do
      file.staged = staged[file.path] or false
      file.dirty = dirty[file.path] or false
    end
    return files
  end

  local files, err = collect()
  if not files then
    return vim.notify("git diff failed: " .. (err or "unknown"), vim.log.levels.ERROR)
  end
  if #files == 0 then
    return vim.notify("No changes against HEAD", vim.log.levels.INFO)
  end

  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local entry_display = require "telescope.pickers.entry_display"
  local conf = require("telescope.config").values

  local displayer = entry_display.create {
    separator = " ",
    items = { { width = 1 }, { width = 4 }, { remaining = true } },
  }

  -- Staging marker: filled when the whole change is in the index, half when
  -- only part of it is (staged, then edited again).
  local function marker(file)
    if not file.staged then
      return { " " }
    elseif file.dirty then
      return { "◐", "DiffChange" }
    end
    return { "●", "DiffAdd" }
  end

  -- Entry paths stay relative to the repo root, which is where the preview
  -- job runs git; the picker's cwd matches so <CR> opens the right file.
  local opts = { cwd = root }

  local entry_maker = function(file)
    local label = file.from and (file.from .. " -> " .. file.path) or file.path
    return {
      value = file.path,
      path = root .. "/" .. file.path,
      status = file.status,
      from = file.from,
      staged = file.staged,
      dirty = file.dirty,
      ordinal = label,
      display = function()
        return displayer {
          marker(file),
          { file.status, status_hl[file.status:sub(1, 1)] or "DiffChange" },
          label,
        }
      end,
    }
  end

  local function finder(results)
    return finders.new_table { results = results, entry_maker = entry_maker }
  end

  local previewer, links = diff_previewer(root)

  pickers
    .new(opts, {
      prompt_title = "Git Diff (working tree vs HEAD)",
      finder = finder(files),
      previewer = previewer,
      sorter = conf.file_sorter(opts),

      attach_mappings = function(prompt_bufnr, map)
        attach_common(prompt_bufnr, root, links)

        -- <Tab> stages the file under the cursor, as it does in Telescope's
        -- git_status; on an already fully staged one it unstages instead. A
        -- half-staged file stages the rest, which is the reading of "toggle"
        -- that gets you to a clean state in one keystroke.
        map({ "i", "n" }, "<Tab>", function()
          local state = require "telescope.actions.state"
          local entry = state.get_selected_entry()
          if not entry then
            return
          end

          local paths = { entry.value }
          if entry.from then
            table.insert(paths, 1, entry.from) -- a rename needs both sides
          end

          local unstage = entry.staged and not entry.dirty
          local args = unstage and { "restore", "--staged", "--" } or { "add", "--" }
          local _, git_err = git(vim.list_extend(args, paths), root)
          if git_err and git_err ~= "" then
            vim.notify("git " .. (unstage and "restore" or "add") .. ": " .. git_err, vim.log.levels.ERROR)
            return
          end

          local results, collect_err = collect()
          if not results then
            vim.notify("git diff failed: " .. (collect_err or "unknown"), vim.log.levels.ERROR)
            return
          end

          -- Refresh in place: same list, new markers, cursor where it was.
          local picker = state.get_current_picker(prompt_bufnr)
          local row = picker:get_selection_row()
          local callbacks = { unpack(picker._completion_callbacks) }
          picker:register_completion_callback(function(self)
            self:set_selection(row)
            self._completion_callbacks = callbacks
          end)
          picker:refresh(finder(results), { reset_prompt = false })
        end)

        return true
      end,
    })
    :find()
end

-- The commit log, previewing each commit with `git show` through the same
-- renderer -- what NvChad's <leader>cm (Telescope git_commits) shows, only
-- with delta doing the diff.
function M.log()
  local root, root_err = git { "rev-parse", "--show-toplevel" }
  if not root then
    vim.notify("Not a git repository: " .. (root_err or "unknown"), vim.log.levels.ERROR)
    return
  end
  root = vim.trim(root)

  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local entry_display = require "telescope.pickers.entry_display"
  local conf = require("telescope.config").values

  local displayer = entry_display.create {
    separator = " ",
    items = { { width = 8 }, { remaining = true } },
  }

  -- \31 (unit separator) keeps the fields apart; %s is single-line, so one
  -- commit per output line.
  local entry_maker = function(line)
    local sha, subject, when = unpack(vim.split(line, "\31", { plain = true }))
    if not sha then
      return nil
    end
    return {
      value = sha,
      sha = sha,
      ordinal = sha .. " " .. (subject or ""),
      display = function()
        return displayer {
          { sha, "DiffChange" },
          (subject or "") .. " " .. (when or ""),
        }
      end,
    }
  end

  -- Read in one go rather than streamed: telescope makes its first selection
  -- before a streaming finder has produced anything, and previews that empty
  -- selection -- leaving the preview blank until you move. `git log` costs
  -- ~100ms on a 12k-commit repo, which is a fair price for a preview that is
  -- there when the picker opens.
  local out, log_err = git({ "log", "--pretty=format:%h\31%s\31%ar" }, root)
  if not out then
    vim.notify("git log failed: " .. (log_err or "unknown"), vim.log.levels.ERROR)
    return
  end
  local log = vim.split(out, "\n", { plain = true })

  local previewer, links = diff_previewer(root)

  pickers
    .new({ cwd = root }, {
      prompt_title = "Git Log",
      -- Streamed, not collected: a long history should not stall the picker.
      finder = finders.new_table { results = log, entry_maker = entry_maker },
      previewer = previewer,
      sorter = conf.generic_sorter {},

      attach_mappings = function(prompt_bufnr)
        attach_common(prompt_bufnr, root, links)
        return true
      end,
    })
    :find()
end

return M
