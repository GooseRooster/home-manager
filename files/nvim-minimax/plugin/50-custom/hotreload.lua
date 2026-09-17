-- Live-reload config files on save (diogo464/hotreload.nvim); uses
-- fs_event watchers by default.
Config.later(function()
  vim.pack.add({ 'https://github.com/diogo464/hotreload.nvim' })
  -- Uses fs_event watchers by default.
  require('hotreload').setup({})
end)
