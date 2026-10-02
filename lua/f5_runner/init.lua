local M = {}
local state = {}
local options = { height = 12, winbar = false, keymaps = true, filetypes = {} }
local function quote(s) return vim.fn.shellescape(s) end
function M.command(file, ft)
  if options.filetypes[ft] then
    local custom = options.filetypes[ft](file)
    if type(custom) ~= 'table' or type(custom[1]) ~= 'string' then return nil, 'Custom runner must return an argv list' end
    if vim.fn.executable(custom[1]) ~= 1 then return nil, 'Missing executable: ' .. custom[1] end
    return custom
  end
  local dir = vim.fs.dirname(file)
  local python = 'python3'
  local root = vim.fs.root(dir, { '.venv', 'venv', 'pyproject.toml', '.git' }) or dir
  for _, name in ipairs({ '.venv', 'venv' }) do
    local candidate = root .. '/' .. name .. '/bin/python'
    if vim.fn.executable(candidate) == 1 then python = candidate; break end
  end
  local commands = {
    python = { python, file }, javascript = { 'node', file },
    sh = { 'bash', file }, bash = { 'bash', file },
    lua = { 'lua', file }, ruby = { 'ruby', file }, php = { 'php', file },
    go = { 'go', 'run', file }, typescript = { 'tsx', file },
  }
  if ft == 'c' or ft == 'cpp' or ft == 'rust' then
    local tool = ft == 'cpp' and 'g++' or ft == 'c' and 'gcc' or 'rustc'
    if vim.fn.executable(tool) ~= 1 then return nil, 'Missing compiler: ' .. tool end
    local build = vim.fn.stdpath('cache') .. '/f5-runner'
    vim.fn.mkdir(build, 'p')
    if vim.fn.has('win32') == 1 or vim.fn.executable('bash') ~= 1 then return nil, 'Compiled runners require a Unix shell (bash)' end
    local bin = build .. '/' .. vim.fn.sha256(file):sub(1, 16) .. '-' .. vim.fn.getpid()
    local flags = ft == 'cpp' and ' -std=c++17 -Wall -Wextra' or ft == 'c' and ' -std=c17 -Wall -Wextra' or ''
    return { 'bash', '-c', tool .. flags .. ' ' .. quote(file) .. ' -o ' .. quote(bin) .. ' && ' .. quote(bin) }
  end
  local cmd = commands[ft]
  if not cmd then return nil, 'No single-file runner for: ' .. ft end
  if vim.fn.executable(cmd[1]) ~= 1 then return nil, 'Install runtime first: ' .. cmd[1] end
  return cmd
end
function M.run()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].buftype ~= '' then vim.notify('Open a code file first', vim.log.levels.WARN); return end
  local file = vim.api.nvim_buf_get_name(buf)
  if file == '' then vim.notify('Save the file with a name first (:w filename)', vim.log.levels.WARN); return end
  local cmd, err = M.command(file, vim.bo[buf].filetype)
  if not cmd then vim.notify(err, vim.log.levels.WARN); return end
  local saved, save_err = pcall(vim.cmd, 'update')
  if not saved then vim.notify(tostring(save_err), vim.log.levels.ERROR); return end
  if state.job and vim.fn.jobwait({ state.job }, 0)[1] == -1 then
    vim.notify('Code is already running. Use :F5Stop first.', vim.log.levels.WARN); return
  end
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then vim.api.nvim_buf_delete(state.buf, { force = true }) end
  vim.cmd('botright ' .. options.height .. 'new')
  state.buf = vim.api.nvim_get_current_buf()
  vim.bo[state.buf].bufhidden = 'hide'
  vim.wo.winbar = ' Output — ' .. vim.fn.fnamemodify(file, ':t') .. ' | Ctrl+C: interrupt | Esc: close'
  local function close_output()
    vim.cmd('stopinsert')
    if vim.api.nvim_get_current_buf() == state.buf then vim.cmd('close') end
  end
  vim.keymap.set({ 't', 'n' }, '<Esc>', close_output, { buffer = state.buf, desc = 'Close Run output' })
  vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = state.buf, desc = 'Close output' })
  state.exit = nil
  state.job = vim.fn.jobstart(cmd, {
    term = true, cwd = vim.fs.dirname(file),
    on_exit = function(_, code)
      state.exit = code
      vim.schedule(function() vim.notify('Run finished — exit code ' .. code, code == 0 and vim.log.levels.INFO or vim.log.levels.WARN) end)
    end,
  })
  if state.job <= 0 then
    vim.notify('Failed to start runner', vim.log.levels.ERROR)
    return
  end
  vim.cmd('startinsert')
end
function M.stop()
  if state.job and vim.fn.jobwait({state.job}, 0)[1] == -1 then vim.fn.jobstop(state.job) end
end
M.state = state
function M.setup(opts)
  options = vim.tbl_deep_extend('force', options, opts or {})
  assert(type(options.height) == 'number' and options.height >= 1 and options.height % 1 == 0, 'height must be a positive integer')
  if options.keymaps then
    vim.keymap.set({'n', 'i'}, '<F5>', M.run, {desc = 'Run current file'})
    vim.keymap.set('n', '<leader>r', M.run, {desc = 'Run current file (F5)'})
    vim.keymap.set('n', '<F6>', M.stop, {desc = 'Stop running code'})
  end
  vim.api.nvim_create_user_command('F5Run', M.run, {force = true})
  vim.api.nvim_create_user_command('F5Stop', M.stop, {force = true})
  if options.winbar then
    _G.F5RunnerClick = M.run
    vim.opt.winbar = '%=%@v:lua.F5RunnerClick@ ▶ Run [F5] %X'
  end
end
return M
