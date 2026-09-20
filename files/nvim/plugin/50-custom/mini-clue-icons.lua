-- Icon-prefixes the global leader-group clues (`Config.leader_group_clues`,
-- defined in vendor's '20_keymaps.lua' and appended to by 'dap.lua',
-- 'cairn.lua', 'herdr-nvim.lua', etc.) using the single shared icon table
-- in 'lua/config/clue.lua' — also used for buffer-local groups via
-- `add_buf`, so there's one icon table and one prefix implementation for
-- every clue group in this config, regardless of how it was registered.
--
-- Safe to mutate `Config.leader_group_clues` entries here: per the comments
-- in '45_keymaps_extra.lua' and 'cairn.lua', mini.clue re-flattens/reads
-- this list at query time (when a clue popup actually opens), not once at
-- `MiniClue.setup()` time — so it doesn't matter that some group-adding
-- files (e.g. 'dap.lua', 'herdr-nvim.lua', 'cairn.lua') load alphabetically
-- after this one.
Config.later(function()
  require('config.clue').apply_icons(Config.leader_group_clues)
end)
