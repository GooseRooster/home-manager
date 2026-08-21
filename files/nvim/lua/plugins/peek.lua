return {
  {
    "rmagatti/goto-preview",
    dependencies = { "rmagatti/logger.nvim" },
    event = "BufEnter",
    opts = {
      default_mappings = false,
      resizing_mappings = true,
    },
    keys = {
      {
        "gld",
        function()
          require("goto-preview").goto_preview_definition()
        end,
        desc = "Preview definition",
      },
      {
        "glt",
        function()
          require("goto-preview").goto_preview_type_definition()
        end,
        desc = "Preview type definition",
      },
      {
        "gli",
        function()
          require("goto-preview").goto_preview_implementation()
        end,
        desc = "Preview implementation",
      },
      {
        "glD",
        function()
          require("goto-preview").goto_preview_declaration()
        end,
        desc = "Preview declaration",
      },
      {
        "glq",
        function()
          require("goto-preview").close_all_win()
        end,
        desc = "Close preview windows",
      },
    },
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = function(_, opts)
      opts.spec = opts.spec or {}
      table.insert(opts.spec, { "gl", group = "Goto Preview" })
      return opts
    end,
  },
}
