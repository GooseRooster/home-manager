-- In-buffer diff overlay (cvlmtg/inline-diff.nvim).
Config.later(function()
  vim.pack.add({ 'https://github.com/cvlmtg/inline-diff.nvim' })
  require('inline-diff').setup({})
end)
