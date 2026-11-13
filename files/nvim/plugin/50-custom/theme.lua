-- Colorscheme, picked per target by 'lua/config/theme_backend.lua' (generated
-- by modules/nvim.nix from `home.modules.tinty`):
--
--   "tinted"  tinted-nvim, following tinty's current scheme (wsl, silver-hour)
--   "osc"     osc-colors.nvim, reading the terminal's live palette (container)
--
-- Both run after MiniMax's own stock colorscheme (`vim.cmd('colorscheme
-- miniwinter')` in 'vendor/nvim/plugin/30_mini.lua', `now()`-applied; left
-- untouched there on purpose so 'vendor/nvim/' stays a pure upstream
-- mirror). This file runs later in the same synchronous `now()` phase and
-- simply repaints over it, so there's no flash of `miniwinter`: nothing
-- actually reaches the screen until all of `plugin/*.lua` finishes sourcing,
-- `now()` or not.
--
-- tinted-nvim is loaded from tinty's own clone, not `vim.pack`: tinty builds
-- custom schemes (the ChromaLeon tinted8 one, the files/gnomad base16 ones)
-- into that clone's `lua/tinted-nvim/palettes/`, which a GitHub copy would
-- never have. The selector watches tinty's current_scheme, so `tinty apply`
-- retints running instances. Before tinty's first sync/apply (no clone or no
-- current_scheme yet) the "tinted" backend falls back to osc-colors.
--
-- `use_lazy_specs` explicitly off for both: that option merges `highlights`
-- tables from lazy.nvim plugin specs, which don't exist in this config (it's
-- already a safe no-op — wrapped in its own `pcall(require,
-- "lazy.core.config")` — but there's nothing for it to ever find here, so
-- being explicit is clearer than relying on the no-op).
-- `highlights.integrations.mini` needs no explicit `true` for osc-colors —
-- it's been on by default upstream since osc-colors gained mini.nvim support.
Config.now(function()
  local tinty = vim.fn.expand('~/.local/share/tinted-theming/tinty')
  local tinted_nvim = tinty .. '/repos/tinted-nvim'
  local current_scheme = tinty .. '/artifacts/current_scheme'

  if
    require('config.theme_backend') == 'tinted'
    and vim.uv.fs_stat(tinted_nvim)
    and vim.uv.fs_stat(current_scheme)
  then
    vim.opt.rtp:prepend(tinted_nvim)
    require('tinted-nvim').setup({
      selector = {
        enabled = true,
        mode = 'file',
        -- tinty 0.35 keeps current_scheme under artifacts/, not the
        -- tinty/ root tinted-nvim defaults to.
        path = current_scheme,
        watch = true,
      },
      highlights = {
        use_lazy_specs = false,
      },
    })
    return
  end

  vim.pack.add({ 'https://github.com/GooseRooster/osc-colors.nvim' })
  require('osc-colors').setup({
    highlights = {
      use_lazy_specs = false,
    },
  })
end)
