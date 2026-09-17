-- Picker navigation rebinds (mini.pick, which 'mini.extra' pickers share).
--
-- Mutating `MiniPick.config.mappings` after the stock setup (same pattern as
-- 'mini-clue-tweaks.lua'): `H.get_config()` re-reads `MiniPick.config` fresh
-- on every picker start, so post-setup changes apply from the next pick.
--
-- move_down/move_up are rebound from `<C-n>`/`<C-p>` to `<C-j>`/`<C-k>` —
-- replaced, not added (mini.pick keys action keys by single chars, so the
-- defaults are gone; `<Up>`/`<Down>` keep working). No conflict with
-- mini.snippets' global insert-mode `<C-j>` (snippet expand): while a picker
-- is active its main loop reads keys through `getcharstr()`, which bypasses
-- real mappings, so the expand mapping never fires inside a picker — and
-- everywhere else C-j still expands snippets.
Config.later(function()
  local pick = require('mini.pick')
  pick.config.mappings.move_down = '<C-j>'
  pick.config.mappings.move_up = '<C-k>'
end)
