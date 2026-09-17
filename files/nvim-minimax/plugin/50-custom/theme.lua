-- Port of the LazyVim setup's 'files/nvim/lua/plugins/theme.lua' — minus the
-- lualine/noice stanzas (MiniMax uses `mini.statusline` instead of lualine,
-- and doesn't have noice.nvim at all).
--
-- Overrides MiniMax's stock default colorscheme (`vim.cmd('colorscheme
-- miniwinter')` in `vendor/minimax/plugin/30_mini.lua`, `now()`-applied).
-- Left untouched there on purpose (vendor stays a pure upstream mirror) —
-- this file runs later in the same synchronous `now()` phase and simply
-- repaints over it (`osc-colors.apply()` does `:highlight clear` first), so
-- there's no flash of `miniwinter`: nothing actually reaches the screen
-- until all of `plugin/*.lua` finishes sourcing, `now()` or not.
--
-- `use_lazy_specs` explicitly off: that option merges `highlights` tables
-- from lazy.nvim plugin specs, which don't exist here (it's already a safe
-- no-op without lazy.nvim installed — wrapped in its own `pcall(require,
-- "lazy.core.config")` — but there's nothing for it to ever find in this
-- config, so being explicit is clearer than relying on the no-op).
-- `highlights.integrations.mini` needs no explicit `true` here — it's been
-- on by default upstream since osc-colors gained mini.nvim support.
Config.now(function()
  vim.pack.add({ 'https://github.com/GooseRooster/osc-colors.nvim' })
  require('osc-colors').setup({
    highlights = {
      use_lazy_specs = false,
    },
  })
end)
