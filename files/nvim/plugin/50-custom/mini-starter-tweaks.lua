-- Startup-time profiling (dstein64/vim-startuptime) hooked into the
-- existing mini.starter dashboard.
--
-- 'mini.starter' has no "append one item" API — `MiniStarter.config.items`
-- stays `nil` unless explicitly set (mini.starter falls back to its own
-- private default item list only at buffer-render time, per
-- 'lua/mini/starter.lua's `H.default_items`). So this replicates that exact
-- default composition (sessions + recent files + builtin actions — the
-- same three sections MiniMax's stock, argument-less
-- `require('mini.starter').setup()` call in '30_mini.lua' already renders)
-- via the same public `MiniStarter.sections.*` generators upstream uses
-- internally, plus one new item. Calling `.setup()` again is a normal,
-- supported way to reconfigure a mini.nvim module.
--
-- Must be `Config.now`, not `Config.later`: MiniMax's stock
-- `require('mini.starter').setup()` (`30_mini.lua`) is itself a `now()`
-- call, and mini.starter opens its dashboard on `VimEnter` — which fires
-- once all of `plugin/*.lua` has sourced, well before the `later()` queue
-- (drained one entry per event-loop tick, starting only once the event
-- loop gets a turn) has a chance to run. A `later()`-registered `setup()`
-- here would land after that first auto-open already rendered mini.starter's
-- own bare internal default items, so the cwd-scoped recent-files section
-- and the "Startup time" utility item would silently never appear on the
-- dashboard you actually see on launch (same fix `theme.lua` needed for the
-- same reason — its colorscheme must also apply before the first frame).
Config.now(function()
  vim.pack.add({ 'https://github.com/dstein64/vim-startuptime' })
  vim.g.startuptime_tries = 10

  local starter = require('mini.starter')
  starter.setup({
    items = {
      function()
        if _G.MiniSessions == nil then return {} end
        return starter.sections.sessions(5, true)()
      end,
      -- Second arg (`current_dir`) scopes `v:oldfiles` to the cwd and its
      -- subdirectories — see 'MiniStarter.sections.recent_files'.
      starter.sections.recent_files(5, true, false),
      starter.sections.builtin_actions(),
      { name = 'Startup time', action = 'StartupTime', section = 'Utilities' },
    },
  })
end)
