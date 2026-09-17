-- Trimmed port of the LazyVim setup's 'files/nvim/lua/plugins/dap.lua'.
--
-- Middle ground between "no UI at all" and the full multi-pane dap-ui layout
-- (see e.g. ~/repos/CSPWeb's `.nvim.lua` for what the latter looks like: a
-- 45-col left inspector + a 40-col right REPL/console column + a bottom
-- perfmon row — plenty of screen real estate for a project that wants it,
-- but too much to be a sane *default* here):
--   - A single, narrower left column (scopes + breakpoints + repl) is always
--     shown — "current variables and scope, repl, and breakpoints", per the
--     roadmap discussion. No separate stacks/watches/console panes, no
--     right column.
--   - The bottom easy-dotnet profiler row (CPU/mem) is added to the layout
--     dynamically, only for sessions actually driven by easy-dotnet's own
--     DAP adapter — not shown (and not just empty/useless) for other
--     languages' debug sessions.
--
-- Still dropped entirely (vs. the original LazyVim `dap.lua`):
--   - nvim-dap-virtual-text — inline value hints; add back if wanted.
--   - mason-nvim-dap — no Mason in this config at all (see the roadmap);
--     debug adapters (codelldb, netcoredbg, js-debug, ...) are expected on
--     PATH via the environment (pkgs/base.nix / project devshells), same as
--     LSP servers will be once Phase 5 lands.
--
-- Per-language `dap.adapters.*`/`dap.configurations.*` wiring (codelldb for
-- rust/clang, js-debug for typescript, ...) is Phase 5 territory, alongside
-- the LSP layer. easy-dotnet registers its own adapter/configuration itself
-- (`debugger.auto_register_dap = true` in 'easy-dotnet.lua'), so dotnet
-- debugging already works without anything here.
--
-- A project can still fully override this (different layout, more panes,
-- whatever) via its own `.nvim.lua` calling `require('dapui').setup({...})`
-- again — exactly the CSPWeb precedent above; this file just changes what
-- the *default*, unconfigured baseline looks like.
Config.later(function()
  if not require('config.profile').any_lang() then return end

  vim.pack.add({
    'https://github.com/mfussenegger/nvim-dap',
    'https://github.com/rcarriga/nvim-dap-ui',
    'https://github.com/nvim-neotest/nvim-nio',
  })

  local dap = require('dap')
  local dapui = require('dapui')

  vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Start/continue debugging' })
  vim.keymap.set('n', '<F10>', dap.step_over, { desc = 'Step over' })
  vim.keymap.set('n', '<F11>', dap.step_into, { desc = 'Step into' })
  vim.keymap.set('n', '<F12>', dap.step_out, { desc = 'Step out' })
  vim.keymap.set(
    'n',
    '<Leader>db',
    dap.toggle_breakpoint,
    { desc = 'Toggle breakpoint' }
  )
  vim.keymap.set('n', '<Leader>dO', dap.step_over, { desc = 'Step over (alt)' })
  vim.keymap.set('n', '<Leader>dC', dap.run_to_cursor, { desc = 'Run to cursor' })
  vim.keymap.set('n', '<Leader>dr', dap.repl.toggle, { desc = 'Toggle DAP REPL' })
  vim.keymap.set('n', '<Leader>dj', dap.down, { desc = 'Go down stack frame' })
  vim.keymap.set('n', '<Leader>dk', dap.up, { desc = 'Go up stack frame' })
  vim.keymap.set('n', '<Leader>dq', function()
    dap.terminate()
    dap.clear_breakpoints()
  end, { desc = 'Terminate and clear breakpoints' })

  table.insert(
    Config.leader_group_clues,
    { mode = 'n', keys = '<Leader>d', desc = '+Debug' }
  )

  -- Always-on left column: variables/scope, breakpoints, repl. Narrower than
  -- CSPWeb's 45-col inspector-only column since repl shares the space here.
  local base_layout = {
    elements = {
      { id = 'scopes', size = 0.5 },
      { id = 'breakpoints', size = 0.2 },
      { id = 'repl', size = 0.3 },
    },
    size = 42,
    position = 'left',
  }

  -- Bottom row: easy-dotnet's CPU/mem widgets. Only meaningful (and only
  -- registered as dap-ui "elements" at all) when easy-dotnet's own debugger
  -- is driving the session — see 'easy-dotnet.lua's `mem_cpu_usage = true`.
  local dotnet_profiler_layout = {
    elements = {
      { id = 'easy-dotnet_cpu', size = 0.5 },
      { id = 'easy-dotnet_mem', size = 0.5 },
    },
    size = 15,
    position = 'bottom',
  }

  -- easy-dotnet registers its DAP adapter under this exact type name (see
  -- its 'lua/easy-dotnet/constants.lua' `debug_adapter_name` +
  -- `lua/easy-dotnet/init.lua`'s `auto_register_dap`) — the reliable way to
  -- tell "this session is an easy-dotnet one" apart from any other adapter.
  local function is_easy_dotnet_session(session)
    return session ~= nil
      and session.config ~= nil
      and session.config.type == 'easy-dotnet'
  end

  --- Reconfigure dap-ui's layout for the session about to open, then open it.
  ---@param session table|nil
  local function open_dapui(session)
    local layouts = { base_layout }
    if is_easy_dotnet_session(session) then
      table.insert(layouts, dotnet_profiler_layout)
    end
    ---@diagnostic disable-next-line: missing-fields
    dapui.setup({ layouts = layouts })
    dapui.open({ reset = true })
  end

  dap.listeners.before.attach.dapui_config = function(session) open_dapui(session) end
  dap.listeners.before.launch.dapui_config = function(session) open_dapui(session) end
  dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
  dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

  vim.api.nvim_create_autocmd('VimResized', {
    desc = 'Reflow dap-ui layout after terminal resize',
    callback = function()
      if dap.session() then
        dapui.close()
        vim.schedule(function() dapui.open({ reset = true }) end)
      end
    end,
  })
end)
