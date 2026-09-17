-- Code-annotation plugin (ChmaraX/herdr-nvim).
--
-- herdr-nvim registers its own keymaps (prefix `<leader>a`: n-mode
-- `ac`/`al`/`as`/`aS` plus x-mode `ac`) but knows nothing about mini.clue —
-- without a group clue here, pressing `<Leader>a` shows an anonymous
-- "+4 entries" popup instead of a labelled group. So register the group
-- ourselves, same pattern as 'cairn.lua'.
Config.later(function()
  vim.pack.add({ 'https://github.com/ChmaraX/herdr-nvim' })
  require('herdr-nvim').setup({})

  table.insert(
    Config.leader_group_clues,
    { mode = 'n', keys = '<Leader>a', desc = '+herdr (annotations)' }
  )
  table.insert(
    Config.leader_group_clues,
    { mode = 'x', keys = '<Leader>a', desc = '+herdr (annotations)' }
  )
end)
