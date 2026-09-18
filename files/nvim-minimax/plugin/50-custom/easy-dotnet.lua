-- .NET integration (GustavEikaas/easy-dotnet.nvim): solution/test-runner/
-- secrets/debugging surface, plus its own roslyn language server.
--
-- Gated on `profile.has('dotnet')` (see 'lua/config/profile.lua') — only
-- loaded (and only downloads roslyn) when the dotnet feature is on for this
-- environment.
--
-- `picker = 'basic'` (`vim.ui.select`-backed): easy-dotnet has no
-- 'mini.pick' integration (its own priority list is snacks -> fzf ->
-- telescope -> basic) and this config doesn't carry any of the first three;
-- 'basic' is the zero-extra-dependency option. Revisit if easy-dotnet ever
-- gains mini.pick support upstream.
--
-- The buffer-scoped `<Leader>r` group clue is registered via
-- `require('config.clue').add_buf(...)` (mini.clue's buffer-local mechanism
-- — see 'lua/config/clue.lua').
Config.later(function()
  if not require('config.profile').has('dotnet') then return end

  vim.pack.add({
    'https://github.com/nvim-lua/plenary.nvim',
    'https://github.com/mfussenegger/nvim-dap',
    'https://github.com/GustavEikaas/easy-dotnet.nvim',
  })

  local dap = require('dap')

  -- `preload_roslyn` calls `vim.lsp.start(cap)` without options, which
  -- attaches the client to the *current* buffer unconditionally (buf_attach_client
  -- ignores `filetypes`; only the `vim.lsp.enable` FileType autocmd machinery
  -- gates attachment). At startup in a solution folder the current buffer is the
  -- mini.starter dashboard (`filetype=ministarter`), so roslyn ends up attached to
  -- it. easy-dotnet's `refresh_diag` (run on `workspace/projectInitializationComplete`
  -- and `workspace/textDocumentContent/refresh`) then pulls `textDocument/diagnostic`
  -- for that buffer; the Roslyn server never got a didOpen for it and throws
  -- `Failed to get language for textDocument/diagnostic` (StreamJsonRpc code
  -- -30099) — see dotnet/roslyn#81410. Patched here to start the server with
  -- `attach = false`: preloading (warm server while the dashboard shows) is
  -- preserved and real cs/razor buffers still attach via `vim.lsp.enable`'s
  -- FileType gating (set up by `M.enable`, which runs before preload).
  -- Must be installed *before* `dotnet.setup()` — setup() itself calls
  -- `preload_roslyn` (easy-dotnet/lua/easy-dotnet/init.lua).
  -- TODO: drop once upstream fixes `M.preload_roslyn` (GustavEikaas/easy-dotnet.nvim).
  local roslyn_lsp = require('easy-dotnet.roslyn.lsp')
  roslyn_lsp.preload_roslyn = function(opts)
    local sln = require('easy-dotnet.current_solution').try_get_selected_solution()
    if sln and opts.preload_roslyn == true then
      local cap = vim.tbl_deep_extend(
        'force',
        vim.lsp.config[require('easy-dotnet.constants').lsp_client_name],
        { root_dir = vim.fs.dirname(sln) }
      )
      vim.lsp.start(cap, { attach = false })
    end
  end

  local dotnet = require('easy-dotnet')
  dotnet.setup({
    managed_terminal = {
      auto_hide = true, -- auto hides terminal if exit code is 0
      auto_hide_delay = 1000, -- delay before auto hiding, 0 = instant
      mappings = {
        next_tab = { lhs = '<Tab>', desc = 'Next terminal tab' },
        prev_tab = { lhs = '<S-Tab>', desc = 'Previous terminal tab' },
        new_terminal = { lhs = '+', desc = 'New user terminal' },
        close_terminal = { lhs = 'X', desc = 'Close current terminal tab' },
        hide_panel = { lhs = 'q', desc = 'Hide terminal panel' },
      },
    },
    projx_lsp = {
      enabled = true,
    },
    lsp = {
      enabled = true, -- Enable builtin roslyn lsp
      set_fold_expr = false,
      preload_roslyn = true, -- Start loading roslyn before any buffer is opened
      roslynator_enabled = true, -- Automatically enable roslynator analyzer
      easy_dotnet_analyzer_enabled = true, -- Enable roslyn analyzer from easy-dotnet-server
      easy_dotnet_extension_enabled = true, -- Needs true for enhanced_rename / create_type_from_usage
      enhanced_rename = true, -- Auto-rename file when renaming primary class
      create_type_from_usage = true, -- Code action: create class from unresolved symbol
      restart_roslyn_on_branch_change = true, -- Helps on Linux with stale diagnostics after big git swaps
      auto_refresh_codelens = true,
      suggest_updates = true, -- Periodically suggest roslyn-language-server updates
      analyzer_assemblies = {}, -- Any additional roslyn analyzers you might use like SonarAnalyzer.CSharp
      -- Razor cohosting: markup goes through vscode-html-language-server. Not bundled —
      -- install with `npm i -g vscode-langservers-extracted` (or per project).
      razor = {
        enabled = true,
        html = {
          enabled = true,
          cmd = nil, -- Auto-detect project node_modules/.bin, then PATH
          request_timeout = 5000,
        },
      },
      config = {},
    },
    debugger = {
      -- Path to custom coreclr DAP adapter
      -- When set, this fully overrides `engine`; easy-dotnet-server uses this binary as-is.
      -- When nil, easy-dotnet-server falls back to its bundled debugger selected by `engine`.
      bin_path = nil,
      -- Bundled debugger used when bin_path is nil:
      --   "netcoredbg" (default) — Samsung netcoredbg
      --   "dncdbg"               — viewizard/dncdbg (richer fork of netcoredbg)
      --   "sharpdbg"             — MattParkerDev/sharpdbg (C# rewrite)
      engine = 'netcoredbg',
      console = 'integratedTerminal', -- Controls where the target app runs: "integratedTerminal" (Neovim buffer) or "externalTerminal" (OS window)
      apply_value_converters = true,
      auto_register_dap = true,
      -- Sample the debugged process' CPU/mem so the `easy-dotnet_cpu` and
      -- `easy-dotnet_mem` dapui widgets have data. Off = widgets unregistered.
      mem_cpu_usage = true,
      mappings = {
        open_variable_viewer = { lhs = 'T', desc = 'open variable viewer' },
      },
    },
    ---@type TestRunnerOptions
    test_runner = {
      auto_start_testrunner = true,
      hide_legend = false,
      -- Set to true when using neotest to avoid duplicate signs and conflicting buffer keymaps.
      neotest_integration = false,
      ---@type "split" | "vsplit" | "float" | "buf"
      viewmode = 'float',
      ---@type number|nil
      vsplit_width = nil,
      ---@type string|nil "topleft" | "topright"
      vsplit_pos = nil,
      icons = {
        passed = '',
        skipped = '',
        failed = '',
        success = '',
        reload = '',
        test = '',
        sln = '󰘐',
        project = '󰘐',
        dir = '',
        package = '',
        class = '',
        build_failed = '󰒡',
      },
      mappings = {
        run_test_from_buffer = { lhs = '<Leader>r', desc = 'run test from buffer' },
        run_all_tests_from_buffer = {
          lhs = '<Leader>t',
          desc = 'Run all tests in file',
        },
        get_build_errors = { lhs = '<Leader>e', desc = 'get build errors' },
        peek_stack_trace_from_buffer = {
          lhs = '<Leader>p',
          desc = 'peek stack trace from buffer',
        },
        debug_test_from_buffer = { lhs = '<Leader>d', desc = 'run test from buffer' },
        debug_test = { lhs = '<Leader>d', desc = 'debug test' },
        go_to_file = { lhs = 'g', desc = 'go to file' },
        run_all = { lhs = '<Leader>R', desc = 'run all tests' },
        run = { lhs = '<Leader>r', desc = 'run test' },
        peek_stacktrace = {
          lhs = '<Leader>p',
          desc = 'peek stacktrace of failed test',
        },
        expand = { lhs = 'o', desc = 'expand' },
        expand_node = { lhs = 'E', desc = 'expand node' },
        collapse_all = { lhs = 'W', desc = 'collapse all' },
        close = { lhs = 'q', desc = 'close testrunner' },
        refresh_testrunner = { lhs = '<C-r>', desc = 'refresh testrunner' },
        cancel = { lhs = '<C-c>', desc = 'cancel in-flight operation' },
        next_failure = { lhs = ']f', desc = 'jump to next failing test' },
        prev_failure = { lhs = '[f', desc = 'jump to previous failing test' },
      },
    },
    new = {
      project = {
        prefix = 'sln', -- "sln" | "none"
      },
    },
    csproj_mappings = true,
    fsproj_mappings = true,
    auto_bootstrap_namespace = {
      --block_scoped, file_scoped
      type = 'block_scoped',
      enabled = true,
      use_clipboard_json = {
        behavior = 'prompt', --'auto' | 'prompt' | 'never',
        register = '+', -- which register to check
      },
    },
    server = {
      -- Windows .NET Framework support via MSBuild in a Visual Studio install.
      use_visual_studio = false,
      ---@type nil | "Off" | "Critical" | "Error" | "Warning" | "Information" | "Verbose" | "All"
      log_level = nil,
    },
    -- "basic" — see file header for why (no mini.pick integration upstream).
    picker = 'basic',
    notifications = {
      --Set this to false if you have configured lualine to avoid double logging
      handler = function(start_event)
        local spinner = require('easy-dotnet.ui-modules.spinner').new()
        -- Upstream switched start_spinner to a callable text provider so the
        -- job name updates live; the spinner still accepts a plain string
        -- for backwards compat, but the callable form is what current
        -- easy-dotnet ships as the default handler.
        spinner:start_spinner(function() return start_event.job.name end)
        ---@param finished_event JobEvent
        return function(finished_event)
          spinner:stop_spinner(
            finished_event.result.msg,
            finished_event.result.level
          )
        end
      end,
    },
    diagnostics = {
      default_severity = 'error',
      setqflist = false,
    },
    outdated = {
      mappings = {
        upgrade = { lhs = '<Leader>pu', desc = 'upgrade package under cursor' },
        upgrade_all = { lhs = '<Leader>pa', desc = 'upgrade all outdated packages' },
      },
    },
  })

  vim.api.nvim_create_user_command('Secrets', function() dotnet.secrets() end, {})

  -- easy-dotnet's managed-terminal panel (the debuggee's stdout/stderr,
  -- `debugger.console = 'integratedTerminal'` above) pops open unconditionally
  -- on every debug/run launch (`run_command_managed.lua` calls
  -- `terminal.show()` with no option check — there's no upstream flag to
  -- suppress it). That fights with the dapui layout in 'dap.lua', which
  -- reserves the bottom of the screen for the CPU/mem profiler widgets during
  -- dotnet sessions: patch `show()` so an auto-triggered open immediately
  -- hides itself again, unless `<Leader>rT` has toggled the panel on. `require`
  -- caches modules, so patching the field on the table returned here is also
  -- what `run_command_managed.lua`'s own `require("easy-dotnet.terminal")`
  -- sees.
  local terminal = require('easy-dotnet.terminal')
  local real_show = terminal.show
  local user_toggled_open = false
  terminal.show = function(...)
    real_show(...)
    if not user_toggled_open then vim.schedule(function() terminal.hide() end) end
  end

  dap.listeners.before.event_terminated.easy_dotnet_console_reset = function()
    user_toggled_open = false
  end
  dap.listeners.before.event_exited.easy_dotnet_console_reset = function()
    user_toggled_open = false
  end

  local setup_buf = function(bufnr)
    local map = function(lhs, rhs, desc)
      vim.keymap.set('n', lhs, rhs, { buffer = bufnr, desc = desc })
    end

    map(
      '<Leader>rd',
      function() vim.cmd('Dotnet debug profile') end,
      'Debug: launch profile'
    )
    map(
      '<Leader>rr',
      function() vim.cmd('Dotnet run profile') end,
      'Dotnet run (profile)'
    )
    map('<Leader>rt', function() dotnet.testrunner() end, 'Test runner')
    map('<Leader>rb', function() vim.cmd('Dotnet build') end, 'Dotnet build')
    map('<Leader>rs', function() dotnet.secrets() end, 'User secrets')
    map('<Leader>rT', function()
      user_toggled_open = not user_toggled_open
      if user_toggled_open then
        real_show()
      else
        terminal.hide()
      end
    end, 'Toggle dotnet debug console')

    require('config.clue').add_buf(
      bufnr,
      { { mode = 'n', keys = '<Leader>r', desc = '+dotnet' } }
    )
  end

  local dotnet_filetypes = { 'cs', 'razor', 'fsharp', 'csproj', 'sln', 'slnx' }
  vim.api.nvim_create_autocmd('FileType', {
    pattern = dotnet_filetypes,
    callback = function(args) setup_buf(args.buf) end,
  })

  -- If nvim was started as `nvim foo.cs` (a startup file arg), that buffer's
  -- FileType event already fired synchronously during startup, before this
  -- `later()`-deferred code ever registered the autocmd above — same class
  -- of gap as 'plugin/50-custom/zk.lua'/'markdown.lua', just via `later()`
  -- instead of `Config.on_filetype`. Catch it explicitly here.
  if vim.tbl_contains(dotnet_filetypes, vim.bo.filetype) then
    setup_buf(vim.api.nvim_get_current_buf())
  end
end)
