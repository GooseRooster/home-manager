-- LSP servers whose mason download is replaced by an environment binary —
-- see config/profile.lua `nix_substitutes` for the full story.
--
-- Per server, resolved at startup:
--   binary on PATH (home profile or project devshell) -> `mason = false`:
--     LazyVim skips mason and lspconfig resolves the command from PATH.
--   binary missing on NixOS -> `enabled = false`: the server stays off rather
--     than letting mason install a prebuilt binary that can't run.
--   anything else -> no entry; mason installs it, exactly as before.
--
-- rust_analyzer needs no entry here: the rust extra already disables the
-- server (rustaceanvim drives it and locates the binary on PATH itself).
local profile = require("config.profile")

-- lspconfig server -> { feature = profile gate (nil = always on, LazyVim core
-- registers the server in every profile), pkg = mason package name }.
-- Entries are only added for servers whose feature is actually enabled —
-- an ungated entry would enable e.g. clangd even with the clang extra off.
local substituted_servers = {
	lua_ls = { pkg = "lua-language-server" },
	clangd = { feature = "clang", pkg = "clangd" },
	neocmakelsp = { feature = "cmake", pkg = "neocmakelsp" },
}

local servers = {}
for server, sub in pairs(substituted_servers) do
	if sub.feature == nil or profile.has(sub.feature) then
		local source = profile.tool_source(sub.pkg)
		if source == "system" then
			servers[server] = { mason = false }
		elseif source == "skip" then
			servers[server] = { enabled = false }
		end
	end
end

return {
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = servers,
		},
	},
}
