return {
	"dzfrias/arena.nvim",
	event = "BufWinEnter",
	-- Calls `.setup()` automatically
	config = true,
	keys = {
		{
			"<leader>a",
			function()
				require("arena").toggle()
			end,
			desc = "Recent buffers",
		},
	},
}
