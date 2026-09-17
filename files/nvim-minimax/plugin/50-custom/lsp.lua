-- LSP layer, Mason-free (see 'lua/config/profile.lua' for the
-- full rationale and per-feature server bundles).
--
-- How it works:
--   1. `Config.later()` — runs after '40_plugins.lua's own later-deferred
--      nvim-lspconfig install callback (later() callbacks fire in
--      registration order, and 40 < 50 alphabetically), so lspconfig's
--      runtime `lsp/<server>.lua` configs are resolvable below.
--   2. Enable the always-on base servers (bashls, lua_ls), then every
--      per-feature server the environment opted into (NVIM_LANGS /
--      NVIM_PROFILE / minimal_langs — see 'lua/config/profile.lua').
--   3. A server only enables if lspconfig's resolved `cmd[1]` is on PATH:
--      missing binaries mean the server simply never attaches (silent), so
--      a host without a toolchain doesn't error on every FileType —
--      binaries come from 'pkgs/base.nix' or project devshells. No Mason
--      anywhere in this config (deliberate — see profile.lua's header).
--   4. Install tree-sitter parsers for enabled features (same
--      not-already-installed filter as '40_plugins.lua') and start
--      tree-sitter on their filetypes — 40_plugins only does this for its
--      own hardcoded list (lua/vimdoc/markdown).
--
-- Per-server settings live in 'after/lsp/<server>.lua' (the vendored
-- 'lua_ls.lua' ships there already; ruff/vtsls/yamlls/jsonls carry their
-- own).

local profile = require("config.profile")

-- lspconfig servers whose `cmd` is a *function* (they probe
-- `node_modules/.bin` before falling back to PATH) — the static
-- executability check can't see through those, so the fallback binary name
-- is supplied here for the check. Anything not in this table with a
-- function cmd stays enabled unchecked (vim.lsp just never attaches if the
-- command fails).
local cmd_bin_overrides = {
	jsonls = "vscode-json-language-server",
	yamlls = "yaml-language-server",
}

local function enable_server(name)
	-- Resolving `vim.lsp.config[name]` performs the lspconfig merge; a nil
	-- result means the name isn't defined anywhere (typo'd or plugin absent)
	-- — skip silently, same stance as every other "binary/tool absent" case
	-- in this config.
	local ok, cfg = pcall(function()
		return vim.lsp.config[name]
	end)
	if not (ok and type(cfg) == "table") then
		return false
	end

	local cmd = cfg.cmd
	local bin
	if type(cmd) == "table" and #cmd > 0 and type(cmd[1]) == "string" then
		bin = cmd[1]
	elseif type(cmd) == "function" then
		bin = cmd_bin_overrides[name]
	end
	if bin ~= nil and vim.fn.executable(bin) ~= 1 then
		return false
	end

	vim.lsp.enable(name)
	return true
end

local function install_and_start_parsers(langs)
	local isnt_installed = function(lang)
		return #vim.api.nvim_get_runtime_file("parser/" .. lang .. ".*", false) == 0
	end
	local to_install = vim.tbl_filter(isnt_installed, langs)
	if #to_install > 0 then
		require("nvim-treesitter").install(to_install)
	end

	-- 40_plugins.lua's `ts_start` equivalent, for the languages *this* layer
	-- brought in. A failed start is reported (not silently swallowed): the
	-- usual cause is the parser not being built yet on first run (install()
	-- is asynchronous), but an unhighlighted filetype would otherwise be
	-- undiagnosable.
	local filetypes = {}
	for _, lang in ipairs(langs) do
		for _, ft in ipairs(vim.treesitter.language.get_filetypes(lang)) do
			table.insert(filetypes, ft)
		end
	end
	local ts_start = function(ev)
		local ok, err = pcall(vim.treesitter.start, ev.buf)
		if not ok then
			vim.notify(
				("tree-sitter could not start for %s: %s"):format(vim.bo[ev.buf].filetype, err),
				vim.log.levels.WARN
			)
		end
	end
	Config.new_autocmd("FileType", filetypes, ts_start, "Start tree-sitter (profile bundles)")
end

Config.later(function()
	-- ── Base (every profile) ───────────────────────────────────────────────
	for _, name in ipairs(profile.base_lsp) do
		enable_server(name)
	end

	-- ── Per-feature bundles ────────────────────────────────────────────────
	local parser_langs = vim.list_extend({}, profile.base_treesitter or {})
	for _, feature in ipairs(profile.feature_order) do
		if profile.has(feature) then
			for _, name in ipairs(profile.feature_lsp[feature] or {}) do
				enable_server(name)
			end
			vim.list_extend(parser_langs, profile.feature_treesitter[feature] or {})
		end
	end

	-- Only when nvim-treesitter is actually installed ('40_plugins.lua' adds
	-- it in a `now_if_args` callback that registered before ours, so on a
	-- fresh install it lands before we run).
	if #parser_langs > 0 and pcall(require, "nvim-treesitter") then
		install_and_start_parsers(parser_langs)
	end
end)
