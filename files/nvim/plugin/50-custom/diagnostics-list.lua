-- Populate the location list / quickfix list with LSP diagnostics.
--
-- Slotted into the existing "+Language" group (`<Leader>l`, defined in
-- vendor's '20_keymaps.lua') alongside `ld` (floating diagnostic popup,
-- current cursor position only). `x`/`X` are free in that group.
--
-- - `<Leader>lx` -> location list, current buffer only
--   (`vim.diagnostic.setloclist()` defaults to the current buffer/window --
--   window-local list, doesn't clobber the quickfix list).
-- - `<Leader>lX` -> quickfix list, every buffer
--   (`vim.diagnostic.setqflist()` has no buffer filter). This is the
--   closest built-in equivalent to "workspace-wide": diagnostics only exist
--   for buffers an LSP client has actually published against, so it covers
--   every open/loaded buffer rather than a fresh disk scan of the cwd.
Config.later(function()
  vim.keymap.set('n', '<Leader>lx', function()
    vim.diagnostic.setloclist({ open = true })
  end, { desc = 'Diagnostics to loclist (buffer)' })

  vim.keymap.set('n', '<Leader>lX', function()
    vim.diagnostic.setqflist({ open = true })
  end, { desc = 'Diagnostics to quickfix (workspace)' })
end)
