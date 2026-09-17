-- Port of LazyVim's `lazyvim.plugins.extras.editor.inc-rename` extra.
--
-- The original registered its keymap (`<leader>cr`) via LazyVim's
-- lspconfig-integration convention (`servers['*'].keys`, gated on the
-- attached client's `rename` capability) — no equivalent here, so this is a
-- plain global keymap instead. Deliberately reuses MiniMax's own existing
-- `<Leader>lr` (its stock 'plugin/20_keymaps.lua' binds that to plain
-- `vim.lsp.buf.rename()`) rather than adding a new key: inc-rename is a
-- strict upgrade of the exact same action (adds a live command-preview),
-- same spirit as how dial.lua/yanky.lua override existing keys elsewhere in
-- this overlay. Worst case with no attached client / no rename capability:
-- `:IncRename <word>` fails gracefully with an LSP error, same as the
-- plain `vim.lsp.buf.rename()` it replaces would.
Config.later(function()
  vim.pack.add({ 'https://github.com/smjonas/inc-rename.nvim' })
  require('inc_rename').setup({})

  vim.keymap.set('n', '<Leader>lr', function()
    local inc_rename = require('inc_rename')
    return ':' .. inc_rename.config.cmd_name .. ' ' .. vim.fn.expand('<cword>')
  end, { expr = true, desc = 'Rename (inc-rename.nvim)' })
end)
