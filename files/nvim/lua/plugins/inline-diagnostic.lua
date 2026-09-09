return {
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    priority = 1000,
    opts = {
      -- Choose a preset style for diagnostic appearance
      -- Available: "modern", "classic", "minimal", "powerline", "ghost", "simple", "nonerdfont", "amongus"
      preset = "powerline",

      -- Make diagnostic background transparent
      transparent_bg = false,

      -- Make cursorline background transparent for diagnostics
      transparent_cursorline = true,

      -- List of filetypes to disable the plugin for
      disabled_ft = {},
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = { diagnostics = { virtual_text = false } },
  },
}
