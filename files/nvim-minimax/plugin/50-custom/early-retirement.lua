-- Port of the LazyVim setup's 'files/nvim/lua/plugins/early-retirement.lua'.
Config.later(function()
  vim.pack.add({ 'https://github.com/chrisgrieser/nvim-early-retirement' })
  require('early-retirement').setup({})
end)
