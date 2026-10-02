# f5-runner.nvim

Press **F5** to save and run the current file in Neovim. Output opens in a bottom terminal split, interactive input works, and **Esc** closes the output and returns to your code.

A small Lua plugin for single-file programs. No Snacks, ToggleTerm, or other plugin dependency.

## Requirements

- Neovim **0.11 or newer**.
- The interpreter/compiler for the language you want to run.
- Linux/macOS with Bash for the compiled-language commands. Tested locally on Linux with Neovim 0.12.5; macOS has not been tested.

## Installation



With lazy.nvim:

```lua
{
  "AhmadRun/f5-runner.nvim",
  opts = {},
}
```

Or put the plugin on your runtime path and call:

```lua
require("f5_runner").setup()
```

Set `vim.g.mapleader = " "` before setup if you want Space+r.

## Controls

| Control | Action |
|---|---|
| F5 | Save and run, in Normal or Insert mode |
| Leader+r | Save and run, in Normal mode |
| F6 | Stop the current process, in Normal mode |
| `:F5Run` | Run the current file |
| `:F5Stop` | Stop the current process |
| Esc in output | Hide output and return to code |
| q in output Normal mode | Close output |
| Ctrl+c in terminal input mode | Interrupt the program |

Closing output **does not stop a running program**. Use F6 or `:F5Stop` after returning to your code. Another run is rejected while the current process is running.

## Languages

| Filetype | Executable / behavior |
|---|---|
| Python | `python3`, preferring a nearby `.venv/bin/python` or `venv/bin/python` |
| C++ | `g++ -std=c++17 -Wall -Wextra`, then run if compilation succeeds |
| C | `gcc -std=c17 -Wall -Wextra`, then run if compilation succeeds |
| Rust | `rustc`, then run if compilation succeeds |
| JavaScript | `node` |
| TypeScript | `tsx` — install separately |
| Shell | `bash` |
| Go | `go run` |
| Lua | `lua` |
| Ruby | `ruby` |
| PHP | `php` |

Missing runtimes produce a message; the plugin does not install language tools. Python, C++, C, JavaScript, and Bash were tested locally. Other built-in commands have not been tested with their runtimes.

## Configuration

```lua
require("f5_runner").setup({
  height = 12,
  keymaps = true,
  winbar = false, -- opt in: replaces your global winbar with a clickable Run button
  filetypes = {
    -- Extend or override runners with a function returning an argv list.
    python = function(file)
      return { "python3", "-u", file }
    end,
  },
})
```

Run and stop are also available as `require("f5_runner").run()` and `.stop()`. With `keymaps = false`, define your own bindings.

To make the optional Run bar use your terminal background:

```lua
vim.api.nvim_set_hl(0, "WinBar", { bg = "NONE" })
vim.api.nvim_set_hl(0, "WinBarNC", { bg = "NONE" })
```

A colorscheme change may reset these highlights.

## Behavior and limits

- Saves the current file before execution; unnamed files must be saved with a filename first.
- Runs from the file's directory; it does not automatically build an entire project.
- Build output is stored under Neovim's cache directory, in `f5-runner/`.
- Compiler paths are shell-escaped; interpreted languages use argv lists.
- No debugger, multi-file CMake/Cargo integration, or runtime installation.
- Only run code you intend to execute. Programs run with your user permissions, without a sandbox.
- An F5 key captured by your terminal or desktop must be rebound there or replaced using custom mappings.

## Tests

From the repository root, with Python 3, GCC, G++, Node.js, and Bash installed:

```sh
nvim --headless -u NONE -l integration.lua
```

Tests cover actual execution, interactive Python input, compiler failure, filenames with spaces and quotes, Escape output closing, and stopping a running program.

## العربية

إضافة بسيطة لتشغيل الملف الحالي بواسطة **F5**. تحفظ الملف وتفتح النتائج في Terminal أسفل Neovim، وتدعم إدخال البيانات مثل `input()` و`cin`. اضغط **Esc** لإخفاء النتائج والعودة للكود، و**F6** لإيقاف برنامج ما زال يعمل. تحتاج أدوات اللغة مثبتة؛ تشغيل المشاريع متعددة الملفات يحتاج أوامر مخصصة.
