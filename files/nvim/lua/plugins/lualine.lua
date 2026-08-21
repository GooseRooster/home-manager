return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "SmiteshP/nvim-navic", "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    init = function()
      vim.g.lualine_laststatus = vim.o.laststatus
      if vim.fn.argc(-1) > 0 then
        vim.o.statusline = " "
      else
        vim.o.laststatus = 0
      end
    end,
    opts = function()
      local lualine_require = require("lualine_require")
      lualine_require.require = require

      local icons = LazyVim.config.icons
      local has_devicons, devicons = pcall(require, "nvim-web-devicons")
      local navic = require("nvim-navic")

      vim.o.laststatus = vim.g.lualine_laststatus

      local function hl_fg(group, fallback)
        local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
        if ok and hl and hl.fg then
          return string.format("#%06x", hl.fg)
        end
        return fallback
      end

      local custom_icons = {
        added = " ",
        modified = "~ ",
        removed = " ",
        lock = "",
        touched = "●",
        git_branch = "",
      }

      local CTRL_V = string.char(22)
      local CTRL_S = string.char(19)

      local mode_labels = {
        n = "NORMAL",
        no = "NORMAL",
        nov = "NORMAL",
        noV = "NORMAL",
        [CTRL_V] = "V-BLOCK",
        niI = "NORMAL",
        niR = "NORMAL",
        niV = "NORMAL",
        nt = "NORMAL",
        i = "INSERT",
        ic = "INSERT",
        ix = "INSERT",
        v = "VISUAL",
        V = "V-LINE",
        R = "REPLACE",
        Rc = "REPLACE",
        Rv = "REPLACE",
        Rx = "REPLACE",
        c = "COMMAND",
        cv = "COMMAND",
        ce = "COMMAND",
        s = "SELECT",
        S = "S-LINE",
        [CTRL_S] = "S-BLOCK",
        t = "TERMINAL",
        r = "PROMPT",
        ["r?"] = "PROMPT",
        rm = "PROMPT",
        ["!"] = "!",
      }

      local function mode_label()
        local m = vim.fn.mode()
        return mode_labels[m] or m:upper()
      end

      local static = {}

      local function ftype_icon()
        local full = vim.api.nvim_buf_get_name(0)
        local filename = vim.fn.fnamemodify(full, ":t")
        local ext = vim.fn.fnamemodify(filename, ":e")
        if has_devicons then
          static.icon, static.color = devicons.get_icon_color(filename, ext, { default = true })
          return static.icon and static.icon .. " "
        end
        return ""
      end

      local function is_buf_named()
        return vim.fn.empty(vim.fn.expand("%:t")) ~= 1
      end

      local function is_git_repo()
        local filepath = vim.fn.expand("%:p:h")
        local gitdir = vim.fn.finddir(".git", filepath .. ";")
        return gitdir and #gitdir > 0 and #gitdir < #filepath
      end

      local function lsp_clients()
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        if #clients == 0 then
          return ""
        end
        local names = {}
        for _, c in ipairs(clients) do
          table.insert(names, c.name)
        end
        return table.concat(names, ", ")
      end

      local function overseer_status()
        local ok, overseer = pcall(require, "overseer")
        if not ok then
          return ""
        end
        local tasks = overseer.list_tasks({})
        if #tasks == 0 then
          return ""
        end
        local running, failed, succeeded = 0, 0, 0
        for _, t in ipairs(tasks) do
          if t.status == "RUNNING" then
            running = running + 1
          elseif t.status == "FAILURE" then
            failed = failed + 1
          elseif t.status == "SUCCESS" then
            succeeded = succeeded + 1
          end
        end
        local parts = {}
        if running > 0 then
          table.insert(parts, " " .. running)
        end
        if failed > 0 then
          table.insert(parts, " " .. failed)
        end
        if running == 0 and failed == 0 and succeeded > 0 then
          table.insert(parts, " " .. succeeded)
        end
        return table.concat(parts, " ")
      end

      local function dap_active()
        local ok, dap = pcall(require, "dap")
        return ok and dap.session() ~= nil
      end

      local function dap_status()
        local ok, dap = pcall(require, "dap")
        if not ok then
          return ""
        end
        local session = dap.session()
        if not session then
          return ""
        end
        return " " .. (session.config and session.config.name or "debug")
      end

      local function harpoon_status()
        local ok, harpoon = pcall(require, "harpoon")
        if not ok then
          return ""
        end
        local list_ok, list = pcall(function()
          return harpoon:list()
        end)
        if not list_ok or not list or not list.items then
          return ""
        end
        local current = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p")
        for i, item in ipairs(list.items) do
          if item.value and vim.fn.fnamemodify(item.value, ":p") == current then
            return string.format("󰛢 %d/%d", i, #list.items)
          end
        end
        return ""
      end

      local config = {
        options = {
          globalstatus = vim.o.laststatus == 3,
          theme = "auto",
          disabled_filetypes = { statusline = { "dashboard", "alpha", "ministarter", "snacks_dashboard" } },
        },
        sections = {
          lualine_a = {
            { mode_label },
          },
          lualine_b = {
            { "branch", icon = custom_icons.git_branch },
          },
          lualine_c = {
            {
              ftype_icon,
              cond = is_buf_named,
              color = function()
                return { fg = static.color }
              end,
              padding = { left = 1, right = 0 },
            },
            {
              "filename",
              cond = is_buf_named,
              path = 0,
              symbols = {
                modified = custom_icons.touched,
                readonly = custom_icons.lock,
                unnamed = "[No Name]",
                newfile = "[New]",
              },
            },
            {
              harpoon_status,
              cond = function()
                return harpoon_status() ~= ""
              end,
            },
            {
              "diagnostics",
              symbols = {
                error = icons.diagnostics.Error,
                warn = icons.diagnostics.Warn,
                info = icons.diagnostics.Info,
                hint = icons.diagnostics.Hint,
              },
            },
          },
          lualine_x = {
            {
              dap_status,
              cond = dap_active,
              color = { fg = hl_fg("Exception", "#e46876") },
            },
            {
              overseer_status,
              cond = function()
                return overseer_status() ~= ""
              end,
            },
            {
              lsp_clients,
              icon = "",
              cond = function()
                return lsp_clients() ~= ""
              end,
            },
            {
              "diff",
              cond = is_git_repo,
              source = function()
                local gs = vim.b.gitsigns_status_dict
                if gs then
                  return { added = gs.added, modified = gs.changed, removed = gs.removed }
                end
              end,
              symbols = {
                added = custom_icons.added,
                modified = custom_icons.modified,
                removed = custom_icons.removed,
              },
            },
          },
          lualine_y = {
            { "progress", separator = " ", padding = { left = 1, right = 0 } },
            { "location", padding = { left = 0, right = 1 } },
          },
          lualine_z = {
            function()
              return " " .. os.date("%R")
            end,
          },
        },
        inactive_sections = {
          lualine_a = { "filename" },
          lualine_b = { "location" },
          lualine_c = {},
          lualine_x = {},
          lualine_y = {},
          lualine_z = {},
        },
        winbar = {
          lualine_c = {
            {
              function()
                return navic.get_location()
              end,
              cond = navic.is_available,
            },
          },
        },
        extensions = { "neo-tree", "lazy", "fzf" },
      }
      config.inactive_winbar = config.winbar

      return config
    end,
  },

  {
    "SmiteshP/nvim-navic",
    lazy = true,
    init = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("navic_attach", { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.server_capabilities.documentSymbolProvider then
            require("nvim-navic").attach(client, args.buf)
          end
        end,
      })
    end,
    opts = {
      highlight = true,
      depth_limit = 5,
      depth_limit_indicator = "…",
      separator = " › ",
    },
  },
}
