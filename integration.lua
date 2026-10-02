vim.opt.rtp:prepend(vim.fn.getcwd())
local r = require('f5_runner')
r.setup({keymaps=false})
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, 'p')
local function run(name, lines, expected, input, failure)
  local file = dir .. '/' .. name
  vim.fn.writefile(lines, file)
  vim.cmd('edit ' .. vim.fn.fnameescape(file))
  vim.bo.filetype = vim.filetype.match({filename=file})
  r.state.exit = nil
  r.run()
  if input then vim.fn.chansend(r.state.job, input .. '\n') end
  assert(vim.wait(15000, function() return r.state.exit ~= nil end, 50), 'Timeout: '..name)
  assert(failure and r.state.exit ~= 0 or not failure and r.state.exit == 0, 'Exit: '..name)
  local output = table.concat(vim.api.nvim_buf_get_lines(r.state.buf,0,-1,false), '\n')
  assert(output:find(expected, 1, true), output)
  print('PASS '..name)
  vim.cmd('stopinsert')
  local output = r.state.buf
  for _, map in ipairs(vim.api.nvim_buf_get_keymap(output, 't')) do
    if map.lhs == '<Esc>' then map.callback(); break end
  end
  assert(#vim.fn.win_findbuf(output) == 0, 'Escape did not close output')
end
run("hello ' python.py", {'print("Python OK")'}, 'Python OK')
run('input.py', {'print("Hello " + input("Name: "))'}, 'Hello Cruze', 'Cruze')
run("hello ' cpp.cpp", {'#include <iostream>', 'int main() { std::cout << "CPP OK" << std::endl; }'}, 'CPP OK')
run('broken.cpp', {'int main() { BROKEN }'}, 'error:', nil, true)
run('hello.c', {'#include <stdio.h>', 'int main(void) { puts("C OK"); }'}, 'C OK')
run('hello.js', {'console.log("JS OK")'}, 'JS OK')
run('hello.sh', {'echo "BASH OK"'}, 'BASH OK')
local wait_file = dir .. '/wait.py'
vim.fn.writefile({'import time', 'time.sleep(60)'}, wait_file)
vim.cmd('edit ' .. vim.fn.fnameescape(wait_file)); vim.bo.filetype = 'python'
r.run()
local job = r.state.job
assert(vim.fn.jobwait({job},0)[1] == -1)
r.stop()
assert(vim.wait(5000,function() return vim.fn.jobwait({job},0)[1] ~= -1 end,50))
print('PASS stopping running code')
local cmd, err = r.command(wait_file,'unsupported')
assert(not cmd and err)
r.setup({filetypes={custom=function(file) return {'python3',file} end}})
assert(r.command(wait_file,'custom')[1] == 'python3')
print('PASS custom runner and unsupported filetype')
print('All runner integration checks passed')

vim.fn.delete(dir, 'rf')
vim.cmd('qa!')
