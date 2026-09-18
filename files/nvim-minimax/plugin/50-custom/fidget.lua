-- Animated LSP-progress spinner in a corner (j-hui/fidget.nvim), layered on
-- top of the existing mini.notify setup rather than replacing it — fidget's
-- own notification subsystem stays at its default (not overriding
-- `vim.notify`), so `vim.notify` keeps routing through mini.notify
-- ('notify.lua', feeds `<Leader>en` history) and fidget only renders
-- `$/progress` spinners.
Config.later(function()
  vim.pack.add({ 'https://github.com/j-hui/fidget.nvim' })
  require('fidget').setup()
end)
