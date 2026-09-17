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
Config.later(function()
  vim.pack.add({ 'https://github.com/dstein64/vim-startuptime' })
  vim.g.startuptime_tries = 10

  local starter = require('mini.starter')
  starter.setup({
    items = {
      function()
        if _G.MiniSessions == nil then return {} end
        return starter.sections.sessions(5, true)()
      end,
      starter.sections.recent_files(5, false, false),
      starter.sections.builtin_actions(),
      { name = 'Startup time', action = 'StartupTime', section = 'Utilities' },
    },
  })
end)
