return {
	"zk-org/zk-nvim",
	name = "zk",
	ft = "markdown",
	cond = function()
		return vim.fn.executable("zk") == 1
	end,
	opts = {
		picker = "select", -- matches your easy-dotnet picker choice; swap if you use something else
		lsp = {
			config = {
				name = "zk",
				cmd = { "zk", "lsp" },
				filetypes = { "markdown" },
			},
			auto_attach = { enabled = true },
		},
	},
	config = function(_, opts)
		require("zk").setup(opts)

		vim.api.nvim_create_autocmd("FileType", {
			pattern = "markdown",
			callback = function(args)
				local bufnr = args.buf
				local path = vim.api.nvim_buf_get_name(bufnr)
				if path == "" then
					return -- unsaved buffer, nothing to check membership against yet
				end

				local notebook_root = require("zk.util").notebook_root(path)
				if notebook_root == nil then
					return -- ordinary markdown file, not in ~/notes or any other notebook
				end

				local map = function(mode, lhs, rhs, desc)
					vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
				end

				-- Note creation (dir defaults to the current buffer's directory)
				map("n", "<leader>zn", function()
					vim.cmd(("ZkNew { dir = %q, title = vim.fn.input('Title: ') }"):format(vim.fn.expand("%:p:h")))
				end, "New note (here)")
				map(
					"v",
					"<leader>znt",
					":'<,'>ZkNewFromTitleSelection { dir = vim.fn.expand('%:p:h') }<CR>",
					"New note from selection (title)"
				)
				map("v", "<leader>znc", function()
					vim.cmd(
						(":'<,'>ZkNewFromContentSelection { dir = %q, title = vim.fn.input('Title: ') }"):format(
							vim.fn.expand("%:p:h")
						)
					)
				end, "New note from selection (content)")

				-- Navigation
				map("n", "<leader>zo", "<Cmd>ZkNotes { sort = { 'modified' } }<CR>", "Open notes")
				map("n", "<leader>zb", "<Cmd>ZkBacklinks<CR>", "Backlinks")
				map("n", "<leader>zl", "<Cmd>ZkLinks<CR>", "Outbound links")
				map("n", "<leader>zt", "<Cmd>ZkTags<CR>", "Notes by tag")

				-- Search
				map("n", "<leader>zf", function()
					vim.cmd(("ZkNotes { sort = { 'modified' }, match = { %q } }"):format(vim.fn.input("Search: ")))
				end, "Search notes")
				map("v", "<leader>zf", ":'<,'>ZkMatch<CR>", "Search matching selection")

				-- LSP-backed link/preview behavior — only meaningful because auto_attach
				-- has already attached zk's LSP client to this same notebook_root check
				map("n", "<CR>", vim.lsp.buf.definition, "Follow link under cursor")
				map("n", "K", vim.lsp.buf.hover, "Preview linked note")
				map("v", "<leader>za", vim.lsp.buf.code_action, "Code action on selection")

				local ok, wk = pcall(require, "which-key")
				if ok then
					wk.add({ { "<leader>z", group = "zk notes", icon = "󰎚", buffer = bufnr } })
				end
			end,
		})
	end,
}
