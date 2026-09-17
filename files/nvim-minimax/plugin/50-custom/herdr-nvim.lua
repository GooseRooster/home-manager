-- Port of the LazyVim setup's 'files/nvim/lua/plugins/herdr-nvim.lua'.
Config.later(function()
  vim.pack.add({ 'https://github.com/ChmaraX/herdr-nvim' })
  require('herdr-nvim').setup({})
end)
