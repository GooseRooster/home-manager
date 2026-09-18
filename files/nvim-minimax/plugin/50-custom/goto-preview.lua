-- LSP "peek" floats: preview a definition/type-definition/implementation/
-- declaration in a floating window without leaving the current buffer or
-- cursor position (ported from the LazyVim side's
-- 'files/nvim/lua/plugins/peek.lua', which wraps the same plugin).
--
-- Global, not filetype-scoped — it works with any attached LSP client — so
-- this follows 'inc-rename.lua's pattern (`Config.later` + `vim.pack.add` +
-- plain `vim.keymap.set`) rather than the FileType-autocmd + buffer-local
-- pattern used by stack-specific integrations like
-- 'easy-dotnet.lua'/'kulala.lua'.
--
-- Slotted into the existing "+Language" group (`<Leader>l`, defined in
-- vendor's '20_keymaps.lua') as uppercase siblings of the jump-to actions
-- already there (`ls`/`lt`/`li` jump the cursor; `lS`/`lT`/`lI` peek instead,
-- same mnemonic letter). `lD` (peek declaration) is free since `ld` is
-- already claimed by diagnostics, not declaration, on this stack.
Config.later(function()
  vim.pack.add({
    'https://github.com/rmagatti/goto-preview',
    'https://github.com/rmagatti/logger.nvim',
  })
  local preview = require('goto-preview')
  preview.setup({
    default_mappings = false,
    resizing_mappings = true,
  })

  vim.keymap.set(
    'n',
    '<Leader>lS',
    preview.goto_preview_definition,
    { desc = 'Peek definition' }
  )
  vim.keymap.set(
    'n',
    '<Leader>lT',
    preview.goto_preview_type_definition,
    { desc = 'Peek type definition' }
  )
  vim.keymap.set(
    'n',
    '<Leader>lI',
    preview.goto_preview_implementation,
    { desc = 'Peek implementation' }
  )
  vim.keymap.set(
    'n',
    '<Leader>lD',
    preview.goto_preview_declaration,
    { desc = 'Peek declaration' }
  )
  vim.keymap.set(
    'n',
    '<Leader>lq',
    preview.close_all_win,
    { desc = 'Close preview windows' }
  )
end)
