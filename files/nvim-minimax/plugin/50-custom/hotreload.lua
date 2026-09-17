-- Port of the LazyVim setup's 'files/nvim/lua/plugins/hotreload.lua'.
Config.later(function()
  vim.pack.add({ 'https://github.com/diogo464/hotreload.nvim' })
  -- Uses fs_event watchers by default.
  require('hotreload').setup({})
end)
