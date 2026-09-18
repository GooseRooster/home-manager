-- Small helper for buffer-scoped mini.clue group/description labels — the
-- mini.clue equivalent of which-key's `wk.add({ ..., buffer = bufnr })`.
--
-- Needed (rather than each caller setting `vim.b[bufnr].miniclue_config`
-- directly) because more than one `FileType` autocmd can target the same
-- buffer (e.g. both 'markdown.lua' and 'zk.lua' fire on `FileType markdown`)
-- — a plain assignment would let whichever fires last clobber the other's
-- clues. mini.clue's own config resolution *concatenates*
-- `vim.b.miniclue_config.clues` with the global clue list (see mini.clue's
-- `H.get_config`, which uses `H.list_concat` rather than overriding), so
-- appending here is exactly what it expects — verified against the source
-- in mini.nvim's own 'lua/mini/clue.lua'.
local M = {}

-- Cosmetic icon prefixes for buffer-local group clues, same convention as
-- the global-clue equivalent in 'plugin/50-custom/mini-clue-icons.lua'
-- (glyphs as `\xXX` UTF-8 byte escapes, not literal characters — several
-- editors/terminals silently drop or mangle raw Private-Use-Area bytes on
-- save, so escapes are the only way to guarantee the exact bytes land in
-- the file). Applied here, at `add_buf` call time, rather than via a single
-- global loop: buffer-local clues live on `vim.b[bufnr]`, so there's no one
-- table to loop over the way `Config.leader_group_clues` works, and the
-- buffer a given group applies to may not exist yet at `Config.later()`
-- time anyway.
local icons = {
  ['<Leader>R'] = '\xEF\x83\xAC', -- U+F0EC exchange (kulala: Rest)
  ['<Leader>r'] = '\xEF\x85\x84', -- U+F144 play-circle (easy-dotnet: dotnet)
  ['<Leader>u'] = '\xEF\x83\x83', -- U+F0C3 flask (easy-dotnet: test, buffer)
  ['<Leader>z'] = '\xEF\x89\x89', -- U+F249 sticky-note (zk: notes)
  ['<Leader>M'] = '\xEF\x83\xB6', -- U+F0F6 file-text (markdown)
}

--- Add one or more buffer-local clue specs (`{ mode, keys, desc }`).
---@param bufnr integer
---@param clues table[]
function M.add_buf(bufnr, clues)
  local existing = vim.b[bufnr].miniclue_config or { clues = {} }
  for _, clue in ipairs(clues) do
    local icon = icons[clue.keys]
    if icon and clue.desc and not clue.desc:find(icon, 1, true) then
      clue.desc = icon .. ' ' .. clue.desc
    end
    table.insert(existing.clues, clue)
  end
  vim.b[bufnr].miniclue_config = existing
end

return M
