# runner-nvim

A simple and lightweight Neovim plugin to run commands in a floating terminal. It remembers the last command executed per project (current working directory), making it easy to repeat build or test commands.

## Features

- **Floating Terminal**: meaningful terminal window toggling.
- **Project-specific History**: Remembers the last command run for each directory.
- **Quick Repeat**: Easily run the last command again with a single keybinding.
- **Interactive Prompt**: Simple floating input to type your command.

## Installation

Install using your favorite package manager. Here is an example with [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "TheLazyCat00/runner-nvim",
    opts = {}, -- This is required to call setup()
    keys = {
        { "<leader>r", function () require("runner-nvim").runLast() end, desc = "Run last cmd" },
        { "<leader>o", function () require("runner-nvim").run() end, desc = "Run cmd" },
        { "<leader>t", function () require("runner-nvim").toggle() end, desc = "Toggle terminal"},
    }
}
```

## Usage

- **Run Command**: Trigger the run command keybinding (e.g., `<leader>o`). A prompt will appear. Type your shell command (e.g., `npm test`, `cargo build`, `make`) and press Enter.
- **Run Last Command**: Trigger the run last command keybinding (e.g., `<leader>r`). The plugin will execute the last command used in the current working directory. If no command is found, it will prompt you for one.
- **Toggle Terminal**: Use the toggle keybinding (e.g., `<leader>t`) to show or hide the terminal window.
- **Close Terminal**: Press `q` in Normal mode inside the terminal window to close it.
