-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
---- Window navigation — all Alt
vim.keymap.set("n", "<A-h>", "<C-w>h", { desc = "Go to left window" })
vim.keymap.set("n", "<A-j>", "<C-w>j", { desc = "Go to lower window" })
vim.keymap.set("n", "<A-k>", "<C-w>k", { desc = "Go to upper window" })
vim.keymap.set("n", "<A-l>", "<C-w>l", { desc = "Go to right window" })

-- Half-page scroll
vim.keymap.set("n", "<C-j>", "<C-d>", { desc = "Scroll down half page", noremap = true, silent = true })
vim.keymap.set("n", "<C-k>", "<C-u>", { desc = "Scroll up half page", noremap = true, silent = true })
