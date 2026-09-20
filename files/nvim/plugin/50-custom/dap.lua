-- Debug adapter UI (nvim-dap + nvim-dap-ui).
--
-- Layout is a deliberate single left column (scopes + breakpoints + repl):
-- narrow, always shown, no separate stacks/watches/console panes. dotnet
-- sessions (adapter type `"easy-dotnet"`) additionally get a bottom row with
-- the CPU/mem profiler widgets (`easy-dotnet.lua`'s `mem_cpu_usage = true`
-- samples them; see `open_dapui` below for where they're placed) — every
-- other stack keeps the left-only layout with nothing at the bottom.
--
-- Not included: nvim-dap-virtual-text (inline value hints; add back if
-- wanted); per-language `dap.adapters.*`/`dap.configurations.*` wiring
-- beyond the adapters below — debug adapters are expected on PATH via the
-- environment ('pkgs/base.nix' / project devshells), same as the LSP
-- servers. easy-dotnet registers its own adapter/configuration itself
-- (`debugger.auto_register_dap = true` in 'easy-dotnet.lua'), so dotnet
-- debugging works without anything here.
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

  -- ── Per-language adapters/configurations ─────────────────────────────
  -- Registered only when the feature is on AND the adapter binary is on
  -- PATH (same philosophy as 'lsp.lua' — missing tool, silently no adapter).
  -- dotnet needs nothing here: easy-dotnet registers its own adapter and
  -- configurations (`debugger.auto_register_dap` in 'easy-dotnet.lua').
  -- typescript's js-debug adapter is npm-only and deliberately not wired.
  local profile = require('config.profile')

  -- codelldb (vscode-lldb standalone; devshell templates put it on PATH)
  -- drives both rust and C/C++ sessions. Launch config points at the usual
  -- per-ecosystem build dir; a project `.nvim.lua` can add richer targets.
  if
    (profile.has('rust') or profile.has('clang'))
    and vim.fn.executable('codelldb') == 1
  then
    dap.adapters.codelldb = {
      type = 'server',
      port = '${port}',
      executable = {
        command = vim.fn.exepath('codelldb'),
        args = { '--port', '${port}' },
      },
    }

    local launch_config = function(build_dir)
      return {
        name = 'Launch (codelldb)',
        type = 'codelldb',
        request = 'launch',
        program = function()
          return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. build_dir, 'file')
        end,
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
      }
    end

    if profile.has('rust') then
      dap.configurations.rust = { launch_config('/target/debug/') }
    end
    if profile.has('clang') then
      dap.configurations.c = { launch_config('/build/') }
      dap.configurations.cpp = { launch_config('/build/') }
    end
  end

  -- python/debugpy: debugpy lives inside the project's env (pip/uv), not on
  -- PATH as a binary — probe it once asynchronously and only then register
  -- the adapter.
  if profile.has('python') then
    vim.system({ 'python3', '-c', 'import debugpy' }, {}, function(res)
      if res.code ~= 0 then return end
      vim.schedule(function()
        dap.adapters.python = {
          type = 'executable',
          command = 'python3',
          args = { '-m', 'debugpy.adapter' },
        }
        dap.configurations.python = {
          {
            name = 'Launch file',
            type = 'python',
            request = 'launch',
            program = '${file}',
            console = 'integratedTerminal',
          },
        }
      end)
    end)
  end

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

  -- dotnet-only bottom row: easy-dotnet registers these two dapui elements
  -- itself (`netcoredbg/sys_monitor_dap_ui.lua`) whenever `mem_cpu_usage =
  -- true`, but places them in no layout — do that here, gated on the fixed
  -- adapter type name easy-dotnet's `auto_register_dap` uses
  -- (`constants.lua`'s `debug_adapter_name`), so other stacks are unaffected.
  local dotnet_profiler_layout = {
    elements = {
      { id = 'easy-dotnet_cpu', size = 0.5 },
      { id = 'easy-dotnet_mem', size = 0.5 },
    },
    size = 15,
    position = 'bottom',
  }

  --- Open dap-ui with the base layout (plus the profiler row for dotnet sessions).
  local function open_dapui(session)
    local layouts = { base_layout }
    if session and session.config and session.config.type == 'easy-dotnet' then
      table.insert(layouts, dotnet_profiler_layout)
    end
    ---@diagnostic disable-next-line: missing-fields
    dapui.setup({ layouts = layouts })
    dapui.open({ reset = true })
  end

  dap.listeners.before.attach.dapui_config = function(session) open_dapui(session) end
  dap.listeners.before.launch.dapui_config = function(session) open_dapui(session) end
  dap.listeners.before.event_terminated.dapui_config = function()
    dapui.close()
    -- easy-dotnet's managed-terminal panel (debuggee log output) only
    -- auto-hides on a clean exit code; close it explicitly on termination
    -- regardless of exit status.
    pcall(function() require('easy-dotnet.terminal').hide() end)
  end
  dap.listeners.before.event_exited.dapui_config = function()
    dapui.close()
    pcall(function() require('easy-dotnet.terminal').hide() end)
  end

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
