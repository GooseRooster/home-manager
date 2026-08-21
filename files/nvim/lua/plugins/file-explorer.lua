-- lua/plugins/file-explorer.lua
return {
	-- Disable snacks explorer keymaps so yazi.nvim can reclaim them
	{
		"folke/snacks.nvim",
		opts = {
			explorer = { enabled = false },
		},
		keys = {
			{ "<leader>fe", false },
			{ "<leader>fE", false },
			{ "<leader>e", false },
			{ "<leader>E", false },
		},
	},

	-- ---------------------------------------------------------------------------
	-- yazi.nvim  –  sole file explorer (directory-buffer interception + bulk ops,
	-- preview, multi-select, images)
	--
	-- Keymaps:
	--   <leader>e  / <leader>fe / <leader>fy  →  open at LSP/git root
	--   <leader>E  / <leader>fE / <leader>fY  →  open at cwd
	--   <leader>ft                            →  toggle / resume last session
	-- ---------------------------------------------------------------------------
	{
		"mikavilpas/yazi.nvim",
		version = "*",
		event = "VeryLazy",
		dependencies = {
			{ "nvim-lua/plenary.nvim", lazy = true },
			-- snacks.nvim is already in LazyVim; listed here for bufdelete integration
			{ "folke/snacks.nvim" },
		},
		init = function()
			-- yazi.nvim now owns directory-buffer interception (open_for_directories
			-- = true below), so suppress netrw the way mini.files used to.
			vim.g.loaded_netrw = 1
			vim.g.loaded_netrwPlugin = 1
		end,
		---@type YaziConfig
		opts = {
			-- yazi now intercepts directory buffers/args (nvim ., :e some/dir)
			-- instead of deferring to mini.files (removed).
			open_for_directories = true,

			-- Open visible splits as yazi tabs for context on where you are
			open_multiple_tabs = true,

			-- Change nvim cwd when closing yazi without selecting a file
			change_neovim_cwd_on_close = false,

			-- Floating window appearance
			yazi_floating_window_border = "rounded",
			yazi_floating_window_winblend = 0,

			-- Highlight the hovered buffer in nvim while yazi is open
			highlight_groups = {
				hovered_buffer = nil,
				hovered_buffer_in_same_directory = nil,
			},

			-- Keymaps active while yazi is open (intercept input before yazi sees it)
			-- Only map keys yazi itself never needs
			keymaps = {
				show_help = "<f1>",
				open_file_in_vertical_split = "<c-v>",
				open_file_in_horizontal_split = "<c-x>",
				open_file_in_tab = "<c-t>",
				grep_in_directory = "<c-s>", -- opens snacks picker grep
				replace_in_directory = "<c-g>", -- opens grug-far if installed
				cycle_open_buffers = "<tab>",
				copy_relative_path_to_selected_files = "<c-y>",
				send_to_quickfix_list = "<c-q>",
				change_working_directory = "<c-\\>",
				open_and_pick_window = "<c-o>",
			},

			future_features = {
				use_cwd_file = true,
			},
		},
		keys = {
			{
				"<leader>E",
				"<cmd>Yazi cwd<cr>",
				mode = { "n", "v" },
				desc = "Explorer Yazi (nvim cwd)",
			},
			{
				"<leader>e",
				"<cmd>Yazi<cr>",
				mode = { "n", "v" },
				desc = "Explorer Yazi (current file)",
			},
			{
				"<leader>ft",
				"<cmd>Yazi toggle<cr>",
				desc = "Resume last Yazi session",
			},
		},
	},
}
