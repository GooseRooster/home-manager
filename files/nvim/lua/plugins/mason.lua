-- Mason tools, derived from the environment profile (see config/profile.lua).
-- The always-on baseline plus the tools for whatever languages are enabled in
-- this environment — so a minimal/container profile never installs LSPs, DAP
-- adapters, or linters for languages it isn't using.
--
-- IMPORTANT: this list must NOT include an LSP server that an enabled LazyVim
-- extra already registers via `servers = {}`. Those are installed by
-- mason-lspconfig; listing them here too makes mason.nvim's ensure_installed loop
-- and mason-lspconfig install the same package concurrently, which mason rejects
-- with "Package is already installing" (a benign-but-noisy config error). The
-- profile's per-feature `mason` lists hold only non-server tools (DAP/lint/format)
-- plus the few LSP servers no extra installs (rust-analyzer, gradle-language-server,
-- css/html/sass).
local profile = require("config.profile")

local ensure_installed = vim.list_extend({}, profile.baseline_mason)
for _, name in ipairs(profile.feature_order) do
	if profile.has(name) then
		vim.list_extend(ensure_installed, profile.features[name].mason)
	end
end

-- Environment-sourced tools (profile / devshell) and NixOS-unrunnable ones
-- never go through mason — see profile.tool_source. Note LazyVim core's own
-- mason spec still merges {"stylua", "shfmt"} here via opts_extend; that
-- copy is harmless at worst: PATH = "append" below keeps it from ever
-- shadowing the working binary on PATH.
ensure_installed = vim.tbl_filter(function(tool)
	return profile.tool_source(tool) == "mason"
end, ensure_installed)

return {
	{
		"mason-org/mason.nvim",
		opts = {
			ensure_installed = ensure_installed,
			-- Keep mason's shim dir BEHIND the home-profile / devshell PATH.
			-- With the default "prepend", any mason-installed copy (e.g. the
			-- core-merged stylua above) would shadow the environment's binary
			-- — on NixOS that shadow copy is unrunnable, and it would win.
			PATH = "append",
		},
	},
}
