-- cwd-scoped mini.sessions helpers.
--
-- mini.sessions keeps all global sessions in one flat directory, so the
-- "which directory is this session for" information is encoded into the
-- on-disk session name: `<cwd with path separators as %>%<short name>`, e.g.
-- `%home%cam%proj%refactor-auth`. The prefix is hidden everywhere this layer
-- shows a session (starter dashboard), so you only ever type/see the short
-- name. Local sessions (`Session.vim` in the cwd) are inherently scoped and
-- left untouched.

local M = {}

--- Prefix that marks sessions belonging to the current working directory.
function M.prefix()
  return (vim.fn.getcwd():gsub('[/\\]', '%%')) .. '%'
end

--- Sessions for the cwd as `{ { label = short, name = on-disk-name }, ... }`
--- sorted by label. Local sessions are included under their own name.
function M.list()
  if _G.MiniSessions == nil then return {} end
  local prefix = M.prefix()
  local items = {}
  for name, s in pairs(MiniSessions.detected) do
    if s.type == 'local' then
      table.insert(items, { label = name, name = name })
    elseif vim.startswith(name, prefix) then
      table.insert(items, { label = name:sub(#prefix + 1), name = name })
    end
  end
  table.sort(items, function(a, b) return a.label < b.label end)
  return items
end

--- Prompt for a short name and write a session scoped to the cwd.
function M.new()
  vim.ui.input({ prompt = 'Session name: ' }, function(input)
    if input == nil or input == '' then return end
    MiniSessions.write(M.prefix() .. input)
  end)
end

return M
