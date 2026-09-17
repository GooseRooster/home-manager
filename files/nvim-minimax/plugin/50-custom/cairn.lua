-- File arena/quick-jump plugin (GooseRooster/cairn.nvim).
--
-- Keymaps landed on `<Leader>c*` (matching the plugin's own name) after two
-- collisions with cairn's own `<leader>m*` defaults: MiniMax's stock
-- 'plugin/20_keymaps.lua' claims `<Leader>m` for 'mini.map', and
-- `herdr-nvim` owns `<Leader>a` by its own default prefix. No hard keymap
-- clash in either spot (different exact leaf sequences), but two unrelated
-- plugins sharing one mini.clue group prefix is exactly the ambiguity to
-- avoid.
--
-- The global group clue is appended onto `Config.leader_group_clues` (read
-- by '30_mini.lua's `later()`-deferred `MiniClue.setup()`; the nested list
-- is re-flattened at query time, so later appends are seen).
Config.later(function()
  vim.pack.add({ 'https://github.com/GooseRooster/cairn.nvim' })

  require('cairn').setup({
    track_cursor = true,
    keymaps = {
      add = '<Leader>ca',
      remove = '<Leader>cd',
      picker = '<Leader>cm',
      -- index_prefix = '' disables cairn's bare `<Leader>1..<Leader>N`
      -- arena-slot jump maps (its own `init.lua` skips registration when the
      -- prefix is empty). Deliberate: bare `<Leader><digit>` was
      -- which-key/clue-free noise here, and the picker (`<Leader>cm`) covers
      -- quick jumps.
      index_prefix = '',
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
