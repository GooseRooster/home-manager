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

--- Add one or more buffer-local clue specs (`{ mode, keys, desc }`).
---@param bufnr integer
---@param clues table[]
function M.add_buf(bufnr, clues)
  local existing = vim.b[bufnr].miniclue_config or { clues = {} }
  for _, clue in ipairs(clues) do
    table.insert(existing.clues, clue)
  end
  vim.b[bufnr].miniclue_config = existing
end

return M
