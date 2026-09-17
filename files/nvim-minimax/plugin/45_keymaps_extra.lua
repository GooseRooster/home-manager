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

-- Picker keys alongside MiniMax's own <Leader>ff / <Leader>fg (which keep
-- working).
vim.keymap.set(
  'n',
  '<Leader><Leader>',
  '<Cmd>Pick files<CR>',
  { desc = 'Find files' }
)
vim.keymap.set('n', '<Leader>/', '<Cmd>Pick grep_live<CR>', { desc = 'Grep live' })

-- Half-page scroll. Intentionally shadows mini.basics' `<C-j>`/`<C-k>`
-- window navigation (below/above window); the Alt block below restores the
-- lost direction keys. Registered synchronously: mini.basics' own setup
-- runs in `now()` (inside '30_mini.lua', sourced before this file), so it
-- has already mapped `<C-hjkl>` and these remaps win immediately.
vim.keymap.set('n', '<C-j>', '<C-d>', { desc = 'Scroll down half page' })
vim.keymap.set('n', '<C-k>', '<C-u>', { desc = 'Scroll up half page' })

-- Window navigation — all Alt. Intentionally shadows MiniMax's *stock*
-- `<A-hjkl>` normal-mode bindings: 'mini.move' (set up in a `later()` at
-- '30_mini.lua:622') uses them to move lines/selection. Registered in a
-- `later()` so it lands after mini.move's setup and wins — later()
-- callbacks fire in registration order, and 30 < 45 alphabetically. What's
-- lost: normal-mode Alt line-moving; Visual-mode `<M-hjkl>` (move
-- selection) and every non-shadowed mini.move target are untouched — if you
-- want the line-move back, rebind mini.move's keys (see
-- `:h MiniMove.config`) or drop this block.
--
-- mini.basics' `move_with_alt` only creates `<M-hjkl>` in Insert/Command
-- modes, so Normal mode is otherwise free for these.
Config.later(function()
  vim.keymap.set('n', '<A-h>', '<C-w>h', { desc = 'Go to left window' })
  vim.keymap.set('n', '<A-j>', '<C-w>j', { desc = 'Go to lower window' })
  vim.keymap.set('n', '<A-k>', '<C-w>k', { desc = 'Go to upper window' })
  vim.keymap.set('n', '<A-l>', '<C-w>l', { desc = 'Go to right window' })
end)

-- ┌─────────────────────────────────────────────────────┐
-- │ Terminal toggle (<C-/> / <C-_>)                     │
-- └─────────────────────────────────────────────────────┘
--
-- In a terminal → close the split (buffer survives via `:hide`), else →
-- open a horizontal split terminal (Neovim 0.12's `:horizontal` modifier +
-- `:term`; same invocation as MiniMax's stock `<Leader>tT`). Mapped in both
-- Normal and Terminal modes, and under both `<C-/>` and `<C-_>` since
-- terminals disagree on which they send.
local toggle_horizontal_term = function()
  if vim.bo.buftype == 'terminal' then
    vim.cmd('hide')
  else
    vim.cmd('horizontal term')
  end
end
for _, mode in ipairs({ 'n', 't' }) do
  vim.keymap.set(mode, '<C-/>', toggle_horizontal_term, { desc = 'Toggle terminal (horizontal)' })
  vim.keymap.set(mode, '<C-_>', toggle_horizontal_term, { desc = 'Toggle terminal (horizontal)' })
end
