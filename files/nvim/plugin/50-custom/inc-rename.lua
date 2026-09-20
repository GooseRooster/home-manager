-- Incremental rename with live LSP preview (smjonas/inc-rename.nvim).
--
-- Deliberately registered on MiniMax's own stock `<Leader>lr` (plain
-- `vim.lsp.buf.rename()` in '20_keymaps.lua') rather than a new key: this is
-- a strict upgrade of the exact same action (adds the live command
-- preview). Worst case with no attached client / no rename capability:
-- `:IncRename <word>` fails gracefully with an LSP error, same as the stock
-- mapping would.
Config.later(function()
  vim.pack.add({ 'https://github.com/smjonas/inc-rename.nvim' })
  require('inc_rename').setup({})

  vim.keymap.set('n', '<Leader>lr', function()
    local inc_rename = require('inc_rename')
    return ':' .. inc_rename.config.cmd_name .. ' ' .. vim.fn.expand('<cword>')
  end, { expr = true, desc = 'Rename (inc-rename.nvim)' })
end)
