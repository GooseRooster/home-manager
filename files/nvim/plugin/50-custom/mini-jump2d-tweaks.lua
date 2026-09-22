-- Make mini.jump2d's default `<CR>` binding do a flash.nvim-style query jump
-- (type a search string, `<Enter>` to confirm, then pick a label if there's
-- more than one match) instead of its default word-start jump.
--
-- 'vendor/nvim/plugin/30_mini.lua' calls `require('mini.jump2d').setup()`
-- with no config, so `<CR>` (n/x modes, plus the operator-pending variant)
-- just calls `MiniJump2d.start()` bare (`lua/mini/jump2d.lua`), which falls
-- back to `MiniJump2d.default_spotter` (word starts) since
-- `MiniJump2d.config.spotter` is `nil`.
--
-- `MiniJump2d.builtin_opts.query` (`:h MiniJump2d.builtin_opts`) already
-- ships exactly this flow: prompts for a string via `vim.fn.input()`,
-- computes spots from every match of that string, and restricts spots to
-- non-blank/non-fold lines. Rather than reimplementing that (the previous
-- attempt at this file did, and got it wrong — see below), just pass it
-- straight to `MiniJump2d.start()` as `opts`, the same way the module's own
-- docs demonstrate for `builtin_opts.line_start`/`single_character`.
--
-- Why a plain `require('mini.jump2d').builtin_opts.query` reference has to
-- be reused (not re-fetched per keypress): its `hooks.before_start` mutates
-- its OWN `spotter` field in place right before `MiniJump2d.start()` reads
-- it (see the private `user_input_opts()` in 'lua/mini/jump2d.lua') — that
-- only works when the *same table instance* is passed to `start()` every
-- time, which is naturally satisfied here since `builtin_opts.query` is
-- itself a single table built once at module load and `local query_opts`
-- below just keeps referencing that one table.
--
-- Must run after MiniMax's own mini.jump2d `later()`-deferred setup() call
-- (which installs the default `<CR>` mapping we're overriding) — guaranteed
-- here since `later()` callbacks fire in registration order (see
-- 'plugin/45_keymaps_extra.lua' for the same reasoning), and this file sorts
-- after '30_mini.lua' alphabetically either way.
Config.later(function()
  local jump2d = require('mini.jump2d')
  local query_opts = jump2d.builtin_opts.query

  local start_query_jump = function() jump2d.start(query_opts) end

  vim.keymap.set('n', '<CR>', start_query_jump, { desc = 'Jump2d (query)' })
  vim.keymap.set('x', '<CR>', start_query_jump, { desc = 'Jump2d (query)' })

  -- Operator-pending needs a `<Cmd>...<CR>` string (not a Lua function ref)
  -- for correct dot-repeat — same constraint vendor's own mapping works
  -- around (see https://github.com/neovim/neovim/issues/23406), hence the
  -- global indirection.
  _G.MiniJump2dQueryStart = start_query_jump
  vim.keymap.set('o', '<CR>', '<Cmd>lua MiniJump2dQueryStart()<CR>', { desc = 'Jump2d (query)' })
end)
