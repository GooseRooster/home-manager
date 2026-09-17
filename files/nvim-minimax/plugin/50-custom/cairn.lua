-- Port of the LazyVim setup's 'files/nvim/lua/plugins/cairn.lua'.
--
-- Dropped: the original's `{ "akinsho/bufferline.nvim", enabled = false }`
-- stanza — MiniMax uses 'mini.tabline' and never had bufferline in the first
-- place, so there's nothing to disable.
--
-- Remapped off cairn's own `<leader>m*` defaults twice now:
--   1. MiniMax's stock 'plugin/20_keymaps.lua' claims `<Leader>m` for
--      'mini.map' (`mf`/`mr`/`ms`/`mt`) — first move was to `<Leader>a`
--      ("arena").
--   2. `<Leader>a` turned out already taken too: `herdr-nvim.lua` uses
--      herdr-nvim's own *default* `prefix = "<leader>a"` — unmodified, so
--      it's the one your primary LazyVim setup already has as established
--      muscle memory (`files/nvim/lua/plugins/herdr-nvim.lua` doesn't
--      override it either). No hard keymap clash either time (different
--      exact leaf sequences — herdr uses `ac`/`al`/`as`/`aS`, cairn used
--      `aa`/`ad`/`am`), but two unrelated plugins sharing one `mini.clue`
--      group prefix is exactly the ambiguity flagged the first time around.
--   Landed on `<Leader>c` ("cairn", matching the plugin's own name) — fully
--   unclaimed by MiniMax stock, herdr, or anything else in this overlay.
--
-- which-key's global `wk.add({ { "<leader>m", group = "cairn", ... } })` is
-- translated to an append onto `Config.leader_group_clues` (read by
-- '30_mini.lua's `later()`-deferred `MiniClue.setup()`).
Config.later(function()
  vim.pack.add({ 'https://github.com/GooseRooster/cairn.nvim' })

  require('cairn').setup({
    track_cursor = true,
    keymaps = {
      add = '<Leader>ca',
      remove = '<Leader>cd',
      picker = '<Leader>cm',
      -- index_prefix left at cairn's own default ("<Leader>", i.e. bare
      -- <Leader>1..<Leader>N for arena slots) — nothing else in this config
      -- binds bare <Leader><digit>, and keeping these as short as possible
      -- matters for a frequently-used quick-jump feature.
    },
    arena = {
      enabled = true,
      max_items = 10,
      persist = true, -- persist per-workspace to <key>_arena.json
      scope_to_workspace = true, -- hide entries tracked in other workspaces
      algorithm = {
        recency_factor = 0.5, -- weight given to how recently a file was visited
        frequency_factor = 1, -- weight given to how often a file was visited
      },
    },
  })

  table.insert(
    Config.leader_group_clues,
    { mode = 'n', keys = '<Leader>c', desc = '+cairn (arena)' }
  )
end)
