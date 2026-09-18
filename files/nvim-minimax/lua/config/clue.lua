-- Small helper for buffer-scoped mini.clue group/description labels — the
-- mini.clue equivalent of which-key's `wk.add({ ..., buffer = bufnr })` —
-- plus the single shared icon table and prefix logic used for EVERY clue
-- group, global or buffer-local: `add_buf` (below) covers buffer-local
-- groups, and `apply_icons` covers the global `Config.leader_group_clues`
-- list (called from 'plugin/50-custom/mini-clue-icons.lua'). One table, one
-- prefix implementation, regardless of which registration path a group
-- came through — previously these lived as two separate, near-identical
-- copies.
--
-- `add_buf` needed (rather than each caller setting
-- `vim.b[bufnr].miniclue_config` directly) because more than one `FileType`
-- autocmd can target the same buffer (e.g. both 'markdown.lua' and 'zk.lua'
-- fire on `FileType markdown`) — a plain assignment would let whichever
-- fires last clobber the other's clues. mini.clue's own config resolution
-- *concatenates* `vim.b.miniclue_config.clues` with the global clue list
-- (see mini.clue's `H.get_config`, which uses `H.list_concat` rather than
-- overriding), so appending here is exactly what it expects — verified
-- against the source in mini.nvim's own 'lua/mini/clue.lua'.
local M = {}

-- Cosmetic icon prefixes for group clue descriptions ("+Debug", "+Rest",
-- ...). mini.clue itself has no icon rendering path at all (no `MiniIcons`
-- calls anywhere in its source) and mini.icons has no `diagnostic`-style
-- category for this either, so these are hand-picked Nerd Font glyphs
-- prepended as plain text — not a mini.icons integration, just pizazz.
--
-- Glyphs are written as `\xXX` UTF-8 byte escapes (each comment names the
-- codepoint) rather than literal characters in the source: several editors/
-- terminals silently drop or mangle raw Private-Use-Area bytes on save, so
-- escapes are the only way to guarantee the exact bytes land in the file.
--
-- Keyed by the literal `keys` string regardless of whether the group is
-- global (`Config.leader_group_clues`, e.g. `<Leader>d` "+Debug") or
-- buffer-local (`add_buf`, e.g. `<Leader>r` "+Run") — one namespace, so a
-- group's icon doesn't depend on which mechanism registered it.
local icons = {
  -- Global groups (Config.leader_group_clues)
  ['<Leader>a'] = '\xEF\x81\x80', -- U+F040 pencil (herdr: annotations)
  ['<Leader>b'] = '\xEF\x83\x85', -- U+F0C5 files-o (Buffer)
  ['<Leader>c'] = '\xEF\x82\x8D', -- U+F08D thumb-tack (cairn: arena)
  ['<Leader>d'] = '\xEF\x86\x88', -- U+F188 bug (Debug)
  ['<Leader>e'] = '\xEF\x81\xBC', -- U+F07C folder-open (Explore/Edit)
  ['<Leader>f'] = '\xEF\x80\x82', -- U+F002 search (Find)
  ['<Leader>g'] = '\xEF\x87\x93', -- U+F1D3 git (Git)
  ['<Leader>l'] = '\xEF\x84\xA1', -- U+F121 code (Language)
  ['<Leader>m'] = '\xEF\x83\xA8', -- U+F0E8 sitemap (Map)
  ['<Leader>o'] = '\xEF\x86\x92', -- U+F192 dot-circle (Other)
  ['<Leader>s'] = '\xEF\x83\x87', -- U+F0C7 floppy-o (Session)
  ['<Leader>t'] = '\xEF\x84\xA0', -- U+F120 terminal (Terminal)
  ['<Leader>v'] = '\xEF\x87\x9A', -- U+F1DA history (Visits)
  -- Buffer-local groups (add_buf)
  ['<Leader>R'] = '\xEF\x83\xAC', -- U+F0EC exchange (kulala: Rest)
  ['<Leader>r'] = '\xEF\x85\x84', -- U+F144 play-circle (Run group — see 'lua/config/run.lua')
  ['<Leader>u'] = '\xEF\x83\x83', -- U+F0C3 flask (Unit-test group — see 'lua/config/run.lua')
  ['<Leader>z'] = '\xEF\x89\x89', -- U+F249 sticky-note (zk: notes)
  ['<Leader>M'] = '\xEF\x83\xB6', -- U+F0F6 file-text (markdown)
}

--- Prefix `clue.desc` with its icon (if one is registered for `clue.keys`),
--- in place. No-op if there's no matching icon, no desc, or the icon is
--- already present (idempotent — safe to call more than once on the same
--- clue table).
---@param clue table `{ mode, keys, desc }`
function M.apply_icon(clue)
  local icon = icons[clue.keys]
  if icon and clue.desc and not clue.desc:find(icon, 1, true) then
    clue.desc = icon .. ' ' .. clue.desc
  end
end

--- Icon-prefix every clue in a list, in place. Used for the global
--- `Config.leader_group_clues` list — see
--- 'plugin/50-custom/mini-clue-icons.lua'.
---@param clues table[]
function M.apply_icons(clues)
  for _, clue in ipairs(clues) do
    M.apply_icon(clue)
  end
end

--- Add one or more buffer-local clue specs (`{ mode, keys, desc }`),
--- icon-prefixed via the same table as global groups.
---@param bufnr integer
---@param clues table[]
function M.add_buf(bufnr, clues)
  local existing = vim.b[bufnr].miniclue_config or { clues = {} }
  for _, clue in ipairs(clues) do
    M.apply_icon(clue)
    table.insert(existing.clues, clue)
  end
  vim.b[bufnr].miniclue_config = existing
end

return M
