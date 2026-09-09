return {
	{
		"GooseRooster/cairn.nvim",
		dependencies = {
			"folke/which-key.nvim",
		},
		config = function()
			require("cairn").setup({

				track_cursor = true,
				arena = {
					enabled = true,
					max_items = 10,
					persist = true, -- persist per-workspace to <key>_arena.json
					scope_to_workspace = true, -- hide entries tracked in other workspaces
					algorithm = {
						recency_factor = 0.5, -- weight given to how recently a file was visited
						frequency_factor = 1, -- weight given to how often a file was visited
					},
				},
			})

			require("which-key").add({
				{ "<leader>m", group = "cairn", icon = "󰔷" },
			})
		end,
	},
	{
		"akinsho/bufferline.nvim",
		enabled = false,
	},
}
