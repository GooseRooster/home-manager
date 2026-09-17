-- Port of the LazyVim setup's 'files/nvim/lua/plugins/diff.lua'.
Config.later(function()
  vim.pack.add({ 'https://github.com/cvlmtg/inline-diff.nvim' })
  require('inline-diff').setup({})
end)
