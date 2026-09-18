-- Route `vim.notify()` through 'mini.notify'.
--
-- MiniMax's stock '30_mini.lua' sets up 'mini.notify' but deliberately
-- leaves `vim.notify` untouched (mini.notify's own default too) — so
-- notifications went through Neovim's default `:messages` handling and
-- never entered the history buffer. Assigning `vim.notify` here makes every
-- notification (errors, LSP progress, plugin notices) land in the history
-- `<Leader>en` (Notification history, stock keymap) shows.
--
-- Registered in a `later()` so this can't out-run the module's own setup;
-- any `vim.notify()` calls before that point keep the default behavior.
--
-- Hand-rolled instead of `require('mini.notify').make_notify()` (mini.notify's
-- own generic wrapper): that wrapper's signature is `function(msg, level)` —
-- it never reads a 3rd `opts` argument at all, so callers using the
-- nvim-notify/snacks "replace" convention (`vim.notify(msg, level, { id =
-- ..., replace = ... })`, e.g. easy-dotnet's job-progress spinner in
-- 'easy-dotnet.lua', which sends one call per 300ms animation frame) get a
-- brand-new stacked notification per call instead of one updating in place.
-- This wrapper keeps `make_notify()`'s exact default per-level
-- duration/highlight table (see `:h MiniNotify.make_notify()`), but
-- additionally recognizes `opts.id`/`opts.replace` and updates the matching
-- notification instead of adding a new one.
Config.later(function()
  local notify = require('mini.notify')

  --stylua: ignore
  local level_data = {
    ERROR = { duration = 5000, hl_group = 'DiagnosticError' },
    WARN  = { duration = 5000, hl_group = 'DiagnosticWarn' },
    INFO  = { duration = 5000, hl_group = 'DiagnosticInfo' },
    DEBUG = { duration = 0,    hl_group = 'DiagnosticHint' },
    TRACE = { duration = 0,    hl_group = 'DiagnosticOk' },
    OFF   = { duration = 0,    hl_group = 'MiniNotifyNormal' },
  }
  local level_names = {}
  for k, v in pairs(vim.log.levels) do
    level_names[v] = k
  end

  -- Maps a caller's `opts.id`/`opts.replace` key to the MiniNotify id it
  -- last resolved to, so the next call with the same key updates it in
  -- place instead of creating a new notification.
  local replace_ids = {}

  local function schedule_removal(id, key, duration)
    vim.defer_fn(function()
      if replace_ids[key] == id then replace_ids[key] = nil end
      notify.remove(id)
    end, duration)
  end

  vim.notify = vim.schedule_wrap(function(msg, level, opts)
    level = level or vim.log.levels.INFO
    local level_name = level_names[level]
    if level_name == nil then return end
    local data = level_data[level_name]
    if data.duration <= 0 then return end

    opts = opts or {}
    local key = opts.id or opts.replace
    if key ~= nil then
      local existing = replace_ids[key]
      if existing and pcall(notify.update, existing, { msg = msg, level = level_name }) then
        -- Push the removal deadline out on every update, so a long-running
        -- spinner (frames arriving well under `duration` apart) never gets
        -- force-removed mid-animation — it only disappears `duration` ms
        -- after the *last* frame.
        schedule_removal(existing, key, data.duration)
        return existing
      end
    end

    local id = notify.add(msg, level_name, data.hl_group, { source = 'vim.notify' })
    if key ~= nil then replace_ids[key] = id end
    schedule_removal(id, key, data.duration)
    return id
  end)
end)
