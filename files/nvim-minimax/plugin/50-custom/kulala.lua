-- Port of LazyVim's own `lazyvim.plugins.extras.util.rest` extra — ported
-- close to verbatim per your call: kulala.nvim is stack-agnostic (was in
-- `core_extras` on the LazyVim side, not gated by any of the 13 language
-- features), so there's little to meaningfully rewrite here beyond the
-- lazy.nvim -> vim.pack/mini.clue mechanics.
--
-- Deviates from the original in one way: lazy.nvim's per-key `ft = "http"`
-- restriction (some of these keymaps only existed while in an .http buffer)
-- has no vim.pack equivalent, so every key is registered globally instead.
-- Harmless — kulala's own functions no-op/error gracefully outside an .http
-- buffer, and a couple of these (scratchpad, replay) are meant to be
-- reachable from anywhere anyway.
--
-- Not gated behind `config.profile` — like the LazyVim side's
-- `core_extras`, this is always on, independent of the 13 language features
-- Phase 5 otherwise gates.
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
