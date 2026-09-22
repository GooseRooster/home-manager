-- Show 'mini.map' by default everywhere except the 'mini.starter' dashboard,
-- instead of it starting hidden until manually toggled with `<Leader>mt`
-- ('vendor/nvim/plugin/30_mini.lua').
--
-- Must be `Config.now`, not `Config.later`: 'mini.starter' (opened with no
-- file arguments) renders its dashboard on `VimEnter`, and the `later()`
-- queue that sets up 'mini.map' itself doesn't even start draining until
-- well after `VimEnter` (see 'mini-starter-tweaks.lua' for the full
-- explanation of that ordering). A `later()`-registered autocmd here would
-- miss the whole startup sequence.
--
-- For the same reason this calls `require('mini.map')` directly rather than
-- going through the `_G.MiniMap` global: that global is only assigned inside
-- `.setup()` (`lua/mini/map.lua`), which hasn't run yet the first time our
-- autocmd can fire. `.open()`/`.close()` don't need `.setup()` to have run —
-- they just use the module's own built-in defaults until the vendored
-- `later()` block's `.setup()` call replaces `MiniMap.config` with the
-- customized symbols/integrations.
Config.now(function()
  local map = require('mini.map')

  -- Covers every *ordinary* buffer/tab switch during the session, including
  -- 'mini.starter' being reopened manually mid-session (e.g. via
  -- `MiniStarter.open()`) — that path fires normal autocmds, unlike the
  -- auto-open-on-startup path handled below.
  Config.new_autocmd(
    { 'BufEnter', 'TabEnter' },
    '*',
    function()
      if vim.bo.filetype == 'ministarter' then
        map.close()
      else
        map.open()
      end
    end,
    'Sync mini.map visibility with the current buffer'
  )

  -- Startup special case: when Neovim opens with no file arguments,
  -- 'mini.starter' auto-opens its dashboard on `VimEnter` by replacing the
  -- initial buffer via `vim.cmd('noautocmd lua MiniStarter.open()')`
  -- (`lua/mini/starter.lua`) — `noautocmd` suppresses `BufEnter`/`FileType`
  -- for that swap entirely, so the handler above never sees it, and by the
  -- time it *does* run (for the transient empty buffer Neovim starts with,
  -- before `VimEnter` even fires) it has already opened the map.
  --
  -- 'mini.starter' itself provides the fix: once `MiniStarter.open()`
  -- finishes populating the buffer (filetype included), it fires a
  -- `User MiniStarterOpened` event — deliberately `vim.schedule_wrap`-deferred
  -- specifically because the rest of that call is `noautocmd` (see the
  -- `trigger_event` logic right after `H.apply_buffer_options()` in
  -- 'lua/mini/starter.lua'). That's the one reliable signal "the startup
  -- dashboard is now actually showing" — everything above already handles
  -- undoing the premature open once it fires.
  Config.new_autocmd('User', 'MiniStarterOpened', function() map.close() end, 'Hide mini.map on Starter buffer')
end)
