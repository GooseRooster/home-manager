-- Auto-close unused buffers (chrisgrieser/nvim-early-retirement).
Config.later(function()
  vim.pack.add({ 'https://github.com/chrisgrieser/nvim-early-retirement' })
  require('early-retirement').setup({})
end)
