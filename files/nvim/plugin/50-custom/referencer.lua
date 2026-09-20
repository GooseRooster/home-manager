-- LSP reference counts inline (romus204/referencer.nvim).
Config.later(function()
  vim.pack.add({ 'https://github.com/romus204/referencer.nvim' })
  require('referencer').setup()
end)
