-- REST client (mistweaverco/kulala.nvim) for .http files. Always installed —
-- stack-agnostic, independent of the language features in
-- 'lua/config/profile.lua' — but fully scoped to .http buffers: every keymap
-- (and the `<Leader>R` group clue) is registered buffer-local on
-- `FileType http` via 'lua/config/clue.lua's buffer mechanism, so they only
-- exist where they apply. Scratchpad and replay are reachable only from an
-- .http buffer too (kulala's scratchpad opens one anyway).
vim.filetype.add({
  extension = {
    ['http'] = 'http',
  },
})

-- Registered both from a persistent autocmd (future .http buffers) and once
-- directly for the buffer that triggered this callback — a freshly
-- registered autocmd doesn't retroactively apply to the event currently
-- being processed.
local setup_buf = function(bufnr)
  -- Idempotent: direct call + autocmd can target the same buffer if the
  -- event fires again (e.g. `:doautocmd FileType`).
  if vim.b[bufnr].kulala_setup then return end
  vim.b[bufnr].kulala_setup = true

  local map = function(lhs, rhs, desc)
    vim.keymap.set('n', lhs, rhs, { buffer = bufnr, desc = desc })
  end

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
  map('<Leader>Ri', function() require('kulala').inspect() end, 'Inspect current request')
  map('<Leader>Rn', function() require('kulala').jump_next() end, 'Jump to next request')
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

  require('config.clue').add_buf(
    bufnr,
    { { mode = 'n', keys = '<Leader>R', desc = '+Rest' } }
  )

  -- tree-sitter for .http (and embedded GraphQL request bodies)
  pcall(vim.treesitter.start, bufnr)
end

Config.on_filetype('http', function()
  vim.pack.add({ 'https://github.com/mistweaverco/kulala.nvim' })
  require('kulala').setup({})

  -- tree-sitter parsers for .http files (and embedded GraphQL request
  -- bodies) — same not-already-installed pattern as '40_plugins.lua'.
  local languages = { 'http', 'graphql' }
  local isnt_installed = function(lang)
    return #vim.api.nvim_get_runtime_file('parser/' .. lang .. '.*', false) == 0
  end
  local to_install = vim.tbl_filter(isnt_installed, languages)
  if #to_install > 0 then require('nvim-treesitter').install(to_install) end

  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('kulala_http_buf', { clear = true }),
    pattern = 'http',
    callback = function(args) setup_buf(args.buf) end,
  })

  -- Cover the buffer that already triggered this callback (see header)
  if vim.bo.filetype == 'http' then
    setup_buf(vim.api.nvim_get_current_buf())
  end
end)
