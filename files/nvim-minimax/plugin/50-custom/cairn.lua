-- Port of the LazyVim setup's 'files/nvim/lua/plugins/cairn.lua'.
--
-- Dropped: the original's `{ "akinsho/bufferline.nvim", enabled = false }`
-- stanza — MiniMax uses 'mini.tabline' and never had bufferline in the first
-- place, so there's nothing to disable.
--
-- Remapped off cairn's own `<leader>m*` defaults: MiniMax's stock
-- 'plugin/20_keymaps.lua' already claims `<Leader>m` for 'mini.map'
-- (`mf`/`mr`/`ms`/`mt`). Nothing would actually break — cairn's default
-- `<leader>ma`/`md`/`mm` are different exact sequences from mini.map's, Vim
-- keymaps don't "claim" a whole prefix — but 'mini.clue' would end up with
-- two different group *descriptions* registered for the same `<Leader>m`
-- (see 'plugin/45_keymaps_extra.lua' for how the clue table works), which is
-- ambiguous. `<Leader>a` ("arena") is free in MiniMax's own group list.
--
-- which-key's global `wk.add({ { "<leader>m", group = "cairn", ... } })` is
-- translated to an append onto `Config.leader_group_clues` (read by
-- '30_mini.lua's `later()`-deferred `MiniClue.setup()`).
Config.later(function()
  vim.pack.add({ 'https://github.com/GooseRooster/cairn.nvim' })

  require('cairn').setup({
    track_cursor = true,
    keymaps = {
      add = '<Leader>aa',
      remove = '<Leader>ad',
      picker = '<Leader>am',
      -- index_prefix left at cairn's own default ("<Leader>", i.e. bare
      -- <Leader>1..<Leader>N for arena slots) — MiniMax doesn't bind any
      -- <Leader><digit> combos, so no collision there.
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
    { mode = 'n', keys = '<Leader>a', desc = '+arena (cairn)' }
  )
end)
