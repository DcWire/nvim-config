-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = vim.keymap.set

-- Quick run Python file
map("n", "<leader>rp", "<cmd>!python %<cr>", { desc = "Run Python file" })

-- Format with black
map("n", "<leader>fb", "<cmd>!black %<cr>", { desc = "Format with Black" })

-- Quick import sorting
map("n", "<leader>fi", "<cmd>!isort %<cr>", { desc = "Sort imports" })

-- Open Python REPL quickly
map("n", "<leader>ri", "<cmd>terminal ipython<cr>", { desc = "Open IPython" })

-- Jupyter shortcuts (if using jupytext)
map("n", "<leader>jc", "<cmd>!jupytext --to ipynb %<cr>", { desc = "Convert to .ipynb" })
map("n", "<leader>jp", "<cmd>!jupytext --to py:percent %<cr>", { desc = "Convert to .py" })
