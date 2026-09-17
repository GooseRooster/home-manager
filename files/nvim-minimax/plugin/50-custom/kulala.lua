-- REST client (mistweaverco/kulala.nvim) for .http files. Always on —
-- stack-agnostic, independent of the language features in
-- 'lua/config/profile.lua'.
--
-- All keymaps below are registered globally: kulala's own functions no-op or
-- error gracefully outside an .http buffer, and a couple of them
-- (scratchpad, replay) are meant to be reachable from anywhere anyway. The
-- `<Leader>R` group clue is appended to `Config.leader_group_clues` (read by
-- '30_mini.lua's `later()`-deferred `MiniClue.setup()`).
vim.filetype.add({
  extension = {
    ['http'] = 'http',
  },
})

Config.later(function()
  vim.pack.add({ 'https://github.com/mistweaverco/kulala.nvim' })
  require('kulala').setup({})

  local map = function(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { desc = desc }) end

  map('<Leader>Rb', function() require('kulala').scratchpad() end, 'Open scratchpad')
  map('<Leader>Rc', function() require('kulala').copy() end, 'Copy as cURL')
  map('<Leader>RC', function() require('kulala').from_curl() end, 'Paste from curl')
  map(
    '<Leader>Re',
    function() require('kulala').set_selected_env() end,
    'Set environment'
  )
  map(
    '<Leader>Rg',
    function() require('kulala').download_graphql_schema() end,
    'Download GraphQL schema'
  )
  map(
    '<Leader>Ri',
    function() require('kulala').inspect() end,
    'Inspect current request'
  )
  map(
    '<Leader>Rn',
    function() require('kulala').jump_next() end,
    'Jump to next request'
  )
  map(
    '<Leader>Rp',
    function() require('kulala').jump_prev() end,
    'Jump to previous request'
  )
  map('<Leader>Rq', function() require('kulala').close() end, 'Close window')
  map(
    '<Leader>Rr',
    function() require('kulala').replay() end,
    'Replay the last request'
  )
  map('<Leader>Rs', function() require('kulala').run() end, 'Send the request')
  map('<Leader>RS', function() require('kulala').show_stats() end, 'Show stats')
  map(
    '<Leader>Rt',
    function() require('kulala').toggle_view() end,
    'Toggle headers/body'
  )

  table.insert(
    Config.leader_group_clues,
    { mode = 'n', keys = '<Leader>R', desc = '+Rest' }
  )

  -- Treesitter parsers for .http files (and embedded GraphQL request
  -- bodies) — matches the ensure_installed pattern MiniMax's own
  -- '40_plugins.lua' uses for its baseline parsers.
  local languages = { 'http', 'graphql' }
  local isnt_installed = function(lang)
    return #vim.api.nvim_get_runtime_file('parser/' .. lang .. '.*', false) == 0
  end
  local to_install = vim.tbl_filter(isnt_installed, languages)
  if #to_install > 0 then require('nvim-treesitter').install(to_install) end

  Config.new_autocmd(
    'FileType',
    'http',
    function(ev) vim.treesitter.start(ev.buf) end,
    'Start tree-sitter for .http'
  )
end)
