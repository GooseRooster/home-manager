-- Port of the LazyVim setup's 'files/nvim/lua/plugins/referencer.lua'.
Config.later(function()
  vim.pack.add({ 'https://github.com/romus204/referencer.nvim' })
  require('referencer').setup()
end)
