return {
	-- lazy.nvim
	{
		"GustavEikaas/easy-dotnet.nvim",
		-- Only loaded (and only downloads roslyn) when the dotnet feature is on.
		enabled = require("config.profile").has("dotnet"),
		-- 'nvim-telescope/telescope.nvim' or 'ibhagwan/fzf-lua' or 'folke/snacks.nvim'
		-- are highly recommended for a better experience
		dependencies = { "nvim-lua/plenary.nvim", "mfussenegger/nvim-dap", "folke/snacks.nvim" },
		config = function()
			local dotnet = require("easy-dotnet")
			-- Options are not required
			dotnet.setup({
				managed_terminal = {
					auto_hide = true, -- auto hides terminal if exit code is 0
					auto_hide_delay = 1000, -- delay before auto hiding, 0 = instant
					mappings = {
						next_tab = { lhs = "<Tab>", desc = "Next terminal tab" },
						prev_tab = { lhs = "<S-Tab>", desc = "Previous terminal tab" },
						new_terminal = { lhs = "+", desc = "New user terminal" },
						close_terminal = { lhs = "X", desc = "Close current terminal tab" },
						hide_panel = { lhs = "q", desc = "Hide terminal panel" },
					},
				},
				-- Only used when debugger.console = "externalTerminal".
				-- wezterm is Windows-only here (/mnt/c); alacritty is the Linux binary on PATH.
				external_terminal = {
					command = "alacritty",
					args = { "-e" },
				},
				projx_lsp = {
					enabled = true,
				},
				lsp = {
					enabled = true, -- Enable builtin roslyn lsp
					set_fold_expr = false,
					roslynator_enabled = true, -- Automatically enable roslynator analyzer
					easy_dotnet_analyzer_enabled = true, -- Enable roslyn analyzer from easy-dotnet-server
					auto_refresh_codelens = true,
					suggest_updates = true, -- Periodically suggest roslyn-language-server updates
					analyzer_assemblies = {}, -- Any additional roslyn analyzers you might use like SonarAnalyzer.CSharp
					config = {},
				},
				debugger = {
					-- Path to custom coreclr DAP adapter
					-- easy-dotnet-server falls back to its own netcoredbg binary if bin_path is nil
					bin_path = nil,
					console = "integratedTerminal", -- Controls where the target app runs: "integratedTerminal" (Neovim buffer) or "externalTerminal" (OS window)
					apply_value_converters = true,
					auto_register_dap = true,
					mappings = {
						open_variable_viewer = { lhs = "T", desc = "open variable viewer" },
					},
				},
				---@type TestRunnerOptions
				test_runner = {
					auto_start_testrunner = true,
					hide_legend = false,
					-- Set to true when using neotest to avoid duplicate signs and conflicting buffer keymaps.
					neotest_integration = false,
					---@type "split" | "vsplit" | "float" | "buf"
					viewmode = "float",
					---@type number|nil
					vsplit_width = nil,
					---@type string|nil "topleft" | "topright"
					vsplit_pos = nil,
					icons = {
						passed = "",
						skipped = "",
						failed = "",
						success = "",
						reload = "",
						test = "",
						sln = "󰘐",
						project = "󰘐",
						dir = "",
						package = "",
						class = "",
						build_failed = "󰒡",
					},
					mappings = {
						run_test_from_buffer = { lhs = "<leader>r", desc = "run test from buffer" },
						run_all_tests_from_buffer = { lhs = "<leader>t", desc = "Run all tests in file" },
						get_build_errors = { lhs = "<leader>e", desc = "get build errors" },
						peek_stack_trace_from_buffer = { lhs = "<leader>p", desc = "peek stack trace from buffer" },
						debug_test_from_buffer = { lhs = "<leader>d", desc = "run test from buffer" },
						debug_test = { lhs = "<leader>d", desc = "debug test" },
						go_to_file = { lhs = "g", desc = "go to file" },
						run_all = { lhs = "<leader>R", desc = "run all tests" },
						run = { lhs = "<leader>r", desc = "run test" },
						peek_stacktrace = { lhs = "<leader>p", desc = "peek stacktrace of failed test" },
						expand = { lhs = "o", desc = "expand" },
						expand_node = { lhs = "E", desc = "expand node" },
						collapse_all = { lhs = "W", desc = "collapse all" },
						close = { lhs = "q", desc = "close testrunner" },
						refresh_testrunner = { lhs = "<C-r>", desc = "refresh testrunner" },
						cancel = { lhs = "<C-c>", desc = "cancel in-flight operation" },
					},
				},
				new = {
					project = {
						prefix = "sln", -- "sln" | "none"
					},
				},
				csproj_mappings = true,
				fsproj_mappings = true,
				auto_bootstrap_namespace = {
					--block_scoped, file_scoped
					type = "block_scoped",
					enabled = true,
					use_clipboard_json = {
						behavior = "prompt", --'auto' | 'prompt' | 'never',
						register = "+", -- which register to check
					},
				},
				server = {
					---@type nil | "Off" | "Critical" | "Error" | "Warning" | "Information" | "Verbose" | "All"
					log_level = nil,
				},
				-- choose which picker to use with the plugin
				-- possible values are "telescope" | "fzf" | "snacks" | "basic"
				-- if no picker is specified, the plugin will determine
				-- the available one automatically with this priority:
				--  snacks -> fzf -> telescope ->  basic
				picker = "snacks",
				notifications = {
					--Set this to false if you have configured lualine to avoid double logging
					handler = function(start_event)
						local spinner = require("easy-dotnet.ui-modules.spinner").new()
						spinner:start_spinner(start_event.job.name)
						---@param finished_event JobEvent
						return function(finished_event)
							spinner:stop_spinner(finished_event.result.msg, finished_event.result.level)
						end
					end,
				},
				diagnostics = {
					default_severity = "error",
					setqflist = false,
				},
				outdated = {
					mappings = {
						upgrade = { lhs = "<leader>pu", desc = "upgrade package under cursor" },
						upgrade_all = { lhs = "<leader>pa", desc = "upgrade all outdated packages" },
					},
				},
			})

			vim.api.nvim_create_user_command("Secrets", function()
				dotnet.secrets()
			end, {})

			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "cs", "razor", "fsharp", "csproj", "sln", "slnx" },
				callback = function(args)
					local bufnr = args.buf
					local map = function(lhs, rhs, desc)
						vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
					end

					map("<leader>rd", function()
						vim.cmd("Dotnet debug profile")
					end, "Debug: launch profile")
					map("<leader>rr", function()
						vim.cmd("Dotnet run profile")
					end, "Dotnet run (profile)")
					map("<leader>rt", function()
						dotnet.testrunner()
					end, "Test runner")
					map("<leader>rb", function()
						vim.cmd("Dotnet build")
					end, "Dotnet build")
					map("<leader>rs", function()
						dotnet.secrets()
					end, "User secrets")
					map("<leader>rT", function()
						vim.cmd("Dotnet terminal toggle")
					end, "Dotnet terminal panel")

					local ok, wk = pcall(require, "which-key")
					if ok then
						wk.add({ { "<leader>r", group = "dotnet", icon = "", buffer = bufnr } })
					end
				end,
			})
		end,
	},
}
