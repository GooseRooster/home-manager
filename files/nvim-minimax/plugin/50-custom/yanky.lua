-- Port of LazyVim's `lazyvim.plugins.extras.coding.yanky` extra.
--
-- The yank-history picker keymap originally branched on which picker
-- (telescope/snacks) LazyVim.pick resolved to, falling back to yanky's own
-- built-in `:YankyRingHistory` UI otherwise. MiniMax has neither telescope
-- nor snacks — always use yanky's own UI directly (no picker-integration
-- loss versus the fallback path the original already had).
--
-- Two real, worth-flagging overlaps with MiniMax's own stock bindings:
--   - `[p`/`]p`: 'vendor/minimax/plugin/20_keymaps.lua' already binds these
--     to a simple linewise put-above/below. Yanky's versions (put *indented*
--     linewise before/after cursor) are a strict superset of the same
--     conceptual action, so this intentionally shadows the stock mapping
--     rather than picking different keys.
--   - `[y`/`]y`: 'mini.bracketed's own "yank" target (`:h MiniBracketed.yank`,
--     active by default in '30_mini.lua') already claims these for a
--     different mechanism (replace latest put region with an older/newer
--     yank-history entry, using its own history store). Yanky's cycle-
--     forward/backward is conceptually similar but uses yanky's own ring —
--     this intentionally shadows mini.bracketed's version too. If you want
--     mini.bracketed's `[y`/`]y` back, rebind yanky's cycle keys elsewhere.
Config.later(function()
  vim.pack.add({ 'https://github.com/gbprod/yanky.nvim' })
  require('yanky').setup({
    system_clipboard = {
      sync_with_ring = not vim.env.SSH_CONNECTION,
    },
    highlight = { timer = 150 },
  })

  vim.keymap.set(
    { 'n', 'x' },
    '<Leader>p',
    '<Cmd>YankyRingHistory<CR>',
    { desc = 'Open Yank History' }
  )

  -- stylua: ignore
  local plug_maps = {
    { { 'n', 'x' }, 'y',  '<Plug>(YankyYank)',                       'Yank Text' },
    { { 'n', 'x' }, 'p',  '<Plug>(YankyPutAfter)',                   'Put Text After Cursor' },
    { { 'n', 'x' }, 'P',  '<Plug>(YankyPutBefore)',                  'Put Text Before Cursor' },
    { { 'n', 'x' }, 'gp', '<Plug>(YankyGPutAfter)',                  'Put Text After Selection' },
    { { 'n', 'x' }, 'gP', '<Plug>(YankyGPutBefore)',                 'Put Text Before Selection' },
    { 'n',          '[y', '<Plug>(YankyCycleBackward)',              'Cycle Backward Through Yank History' },
    { 'n',          ']y', '<Plug>(YankyCycleForward)',               'Cycle Forward Through Yank History' },
    { 'n',          '[p', '<Plug>(YankyPutIndentBeforeLinewise)',    'Put Indented Before Cursor (Linewise)' },
    { 'n',          ']p', '<Plug>(YankyPutIndentAfterLinewise)',     'Put Indented After Cursor (Linewise)' },
    { 'n',          '[P', '<Plug>(YankyPutIndentBeforeLinewise)',    'Put Indented Before Cursor (Linewise)' },
    { 'n',          ']P', '<Plug>(YankyPutIndentAfterLinewise)',     'Put Indented After Cursor (Linewise)' },
    { 'n',          '<p', '<Plug>(YankyPutIndentAfterShiftLeft)',    'Put and Indent Left' },
    { 'n',          '>p', '<Plug>(YankyPutIndentAfterShiftRight)',   'Put and Indent Right' },
    { 'n',          '<P', '<Plug>(YankyPutIndentBeforeShiftLeft)',   'Put Before and Indent Left' },
    { 'n',          '>P', '<Plug>(YankyPutIndentBeforeShiftRight)',  'Put Before and Indent Right' },
    { 'n',          '=p', '<Plug>(YankyPutAfterFilter)',             'Put After Applying a Filter' },
    { 'n',          '=P', '<Plug>(YankyPutBeforeFilter)',            'Put Before Applying a Filter' },
  }
  for _, m in ipairs(plug_maps) do
    vim.keymap.set(m[1], m[2], m[3], { desc = m[4] })
  end
end)
