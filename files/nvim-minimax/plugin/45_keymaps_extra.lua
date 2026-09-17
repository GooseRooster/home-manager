-- ┌──────────────────────────────┐
-- │ Custom keymaps (extra layer) │
-- └──────────────────────────────┘
--
-- Additions on top of MiniMax's stock 'plugin/20_keymaps.lua'. Kept in a
-- separate file (rather than editing the vendored copy) so 'vendor/minimax/'
-- stays a pure upstream mirror and easy to diff against
-- (see 'scripts/update-minimax.sh').
--
-- Runs after '20_keymaps.lua' (numeric prefix 45 > 20). That ordering isn't
-- actually load-bearing for `Config.leader_group_clues` appends elsewhere
-- (see 'plugin/50-custom/*.lua'): those run synchronously during `plugin/`
-- sourcing, strictly before MiniMax's own `later()`-deferred
-- `MiniClue.setup()` call fires — so append order doesn't matter, only that
-- it happens before mini.clue's setup runs, which it always does.

-- Muscle-memory carried over from the LazyVim setup (snacks picker
-- defaults). Additive: MiniMax's own <Leader>ff / <Leader>fg keep working.
vim.keymap.set(
  'n',
  '<Leader><Leader>',
  '<Cmd>Pick files<CR>',
  { desc = 'Find files' }
)
vim.keymap.set('n', '<Leader>/', '<Cmd>Pick grep_live<CR>', { desc = 'Grep live' })
