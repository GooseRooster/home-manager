return {
	{
		"GooseRooster/osc-colors.nvim",
		priority = 1000, -- load colorscheme early
		lazy = false, -- apply on startup
		opts = {
			-- your config overrides
		},
	},
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "GooseRooster/osc-colors.nvim" },
		opts = {
			options = {
				theme = "osc-colors",
			},
		},
	},
	{
		"folke/noice.nvim",
		opts = {
			presets = {
				lsp_doc_border = true, -- adds border to hover docs and signature help
			},
		},
	},
}
