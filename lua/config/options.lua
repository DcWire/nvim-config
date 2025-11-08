-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
-- Python-specific options
vim.g.python3_host_prog = vim.fn.expand("~/.pyenv/shims/python3")

-- Set tab width for Python
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- Better search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Line numbers
vim.opt.relativenumber = true
vim.opt.number = true

-- Clipboard
vim.opt.clipboard = "unnamedplus"

-- Better completion
vim.opt.completeopt = "menu,menuone,noselect"
