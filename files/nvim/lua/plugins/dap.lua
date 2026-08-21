-- Debugging is only useful once at least one language is enabled; matches the
-- dap.core/nlua/test.core gating in config/lazy.lua.
local enabled = require("config.profile").any_lang()

return {
  {
    "mfussenegger/nvim-dap",
    enabled = enabled,
    config = function()
      local dap = require("dap")

      -- Keymaps for controlling the debugger
      vim.keymap.set("n", "<leader>dq", function()
        dap.terminate()
        dap.clear_breakpoints()
      end, { desc = "Terminate and clear breakpoints" })

      vim.keymap.set("n", "<F5>", dap.continue, { desc = "Start/continue debugging" })
      vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Step over" })
      vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Step into" })
      vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Step out" })
      vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
      vim.keymap.set("n", "<leader>dO", dap.step_over, { desc = "Step over (alt)" })
      vim.keymap.set("n", "<leader>dC", dap.run_to_cursor, { desc = "Run to cursor" })
      vim.keymap.set("n", "<leader>dr", dap.repl.toggle, { desc = "Toggle DAP REPL" })
      vim.keymap.set("n", "<leader>dj", dap.down, { desc = "Go down stack frame" })
      vim.keymap.set("n", "<leader>dk", dap.up, { desc = "Go up stack frame" })
    end,
  },

  -- The IDE-style UI: stack / scopes / watches / REPL panes
  {
    "rcarriga/nvim-dap-ui",
    enabled = enabled,
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    config = function()
      local dap, dapui = require("dap"), require("dapui")


      ---@diagnostic disable-next-line: missing-fields
      dapui.setup({
        layouts = {
          -- Left: inspector
          {
            elements = {
              { id = "scopes",      size = 0.45 },
              { id = "stacks",      size = 0.30 },
              { id = "watches",     size = 0.15 },
              { id = "breakpoints", size = 0.10 },
            },
            size = 40,
            position = "left",
          },
          -- Right: repl above the integrated terminal (debuggee console)
          {
            elements = {
              { id = "repl",    size = 0.35 },
              { id = "console", size = 0.65 },
            },
            size = 70,
            position = "right",
          },
        },
      })
      dap.listeners.before.attach.dapui_config = function()
        dapui.open({ reset = true })
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open({ reset = true })
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end

      vim.api.nvim_create_autocmd("VimResized", {
        desc = "Reflow dap-ui layout after terminal resize",
        callback = function()
          if dap.session() then
            dapui.close()
            vim.schedule(function()
              dapui.open({ reset = true })
            end)
          end
        end,
      })
    end,
  },

  -- Inline virtual text showing variable values next to code
  {
    "theHamsta/nvim-dap-virtual-text",
    enabled = enabled,
    dependencies = { "mfussenegger/nvim-dap" },
    opts = {},
  },
}
