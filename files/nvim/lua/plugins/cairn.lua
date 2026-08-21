return {
  "GooseRooster/cairn.nvim",
  dependencies = {
    "folke/which-key.nvim",
  },
  config = function()
    require("cairn").setup({

      track_cursor = true,
    })

    require("which-key").add({
      { "<leader>m", group = "cairn", icon = "󰔷" },
    })
  end,
}
