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

-- Close the current window with `q`. Deliberate trade-off: this gives up the
-- normal-mode macro recorder (`qq`, `q:`/`q/`/`q?` cmdline windows included)
-- and any plugin relying on a *global* `q`; buffer-local `q` bindings
-- (mini.files, mini.pick, help windows, ...) still win over this. As the
-- only window there's nothing to close, so it falls back to deleting the
-- current buffer (mini.bufremove refuses on modified buffers instead of
-- losing changes).
vim.keymap.set('n', 'q', function()
  if vim.fn.winnr('$') > 1 then
    vim.cmd('close')
  else
    require('mini.bufremove').delete(0)
  end
end, { desc = 'Close window (or buffer when last)' })

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
-- In a terminal → close the split (`:hide` keeps the buffer and its running
-- shell alive), else → open a horizontal split terminal (Neovim 0.12's
-- `:horizontal` modifier + `:term`; same invocation as MiniMax's stock
-- `<Leader>tT`). Mapped in both Normal and Terminal modes, and under both
-- `<C-/>` and `<C-_>` since terminals disagree on which they send.
--
-- Every toggle-terminal shares ONE buffer, found by the `minimax_term`
-- buffer-local marker: reopening shows the same buffer (scrollback and
-- running shell preserved) instead of piling up a new one per press. Dead
-- markers (shell exited) are deleted and replaced on the next toggle. The
-- buffer is unlisted, so it never shows up in 'mini.tabline' as a tab —
-- only the toggle ever brings it up.
--
-- Both open paths end in Terminal mode (`startinsert`), so the toggle is
-- immediately typeable. mini.basics already does this via its `TermOpen`
-- autocmd, but only for *fresh* terminals — reused buffers don't re-fire
-- that event, so this is done explicitly here.
local toggle_horizontal_term = function()
  if vim.bo.buftype == 'terminal' then
    -- `:hide` fails on the last window; with nothing left to show, the
    -- single-buffer invariant makes deleting the buffer the right close.
    if vim.fn.winnr('$') == 1 then
      vim.api.nvim_buf_delete(vim.api.nvim_get_current_buf(), { force = true })
    else
      vim.cmd('hide')
    end
    return
  end

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buftype == 'terminal' and vim.b[buf].minimax_term then
      -- Liveness: a terminal buffer's `channel` job answers `jobpid()` while
      -- running and errors (E900) once its shell exited.
      local channel = vim.bo[buf].channel
      if type(channel) == 'number' and channel > 0 and pcall(vim.fn.jobpid, channel) then
        vim.cmd(('horizontal sbuffer %d'):format(buf))
        vim.cmd('startinsert')
        return
      else
        -- Stale marker (shell exited since last use): clean it up so the
        -- single-buffer invariant holds, then fall through to a fresh one.
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
  end

  vim.cmd('horizontal term')
  vim.b.minimax_term = true
  vim.bo.buflisted = false
  vim.cmd('startinsert')
end
for _, mode in ipairs({ 'n', 't' }) do
  vim.keymap.set(mode, '<C-/>', toggle_horizontal_term, { desc = 'Toggle terminal (horizontal)' })
  vim.keymap.set(mode, '<C-_>', toggle_horizontal_term, { desc = 'Toggle terminal (horizontal)' })
end
