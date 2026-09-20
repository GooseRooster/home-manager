-- Environment-driven feature profile
--   NVIM_PROFILE = "full" | "minimal"   coarse override (optional)
--   NVIM_LANGS   = "rust,python,..."    comma list of extra langs (minimal only)

-- Read live at every startup, so a devshell's `.dev.local.sh` env export
-- (typically via direnv) changes the profile without touching config files.

local M = {}

local function env(name)
	local v = vim.env[name]
	if v == nil or v == "" then
		return nil
	end
	return v
end

-- Ordered feature list; iterate with ipairs, never the resolved map.
-- Consumers: the LSP/tree-sitter bundles below (via 'plugin/50-custom/
-- lsp.lua') and easy-dotnet (via its own `has('dotnet')` gate).
M.feature_order = {
	"python",
	"rust",
	"typescript",
	"java",
	"clang",
	"cmake",
	"docker",
	"sql",
	"json",
	"yaml",
	"nushell",
	"git",
	"dotnet",
}

-- Universal languages enabled even in the minimal profile.
M.minimal_langs = { "python", "git", "json", "yaml", "docker", "nushell" }

-- ─────────────────────────────────────────────────────────────────────────
-- LSP/tree-sitter bundles: what each feature actually loads in this config.
--
-- Keys are lspconfig server names (NOT binaries — they differ: `neocmake`
-- runs the `neocmakelsp` binary; `somesass_ls` runs
-- `some-sass-language-server`), consumed by 'plugin/50-custom/lsp.lua'.
-- No Mason anywhere: a server only attaches when its binary is on PATH
-- (checked at enable time), so a host without a toolchain silently degrades
-- instead of erroring — binaries come from 'pkgs/base.nix' or project
-- devshells.
--
-- Deliberate absences:
--   - sql: no LSP configured — treesitter parsers only.
--   - git: no LSP configured — treesitter parsers only.
--   - java: no entry yet.
--   - dotnet: roslyn is driven entirely by easy-dotnet (which downloads and
--     manages it itself); this bundle only carries the markup half — the
--     HTML/CSS language servers Razor cohosting leans on, plus the Sass LS
--     (some-sass-language-server is npm-only: not in nixpkgs, so it's
--     devshell territory).
--
-- Schema catalogs for json/yaml use the servers' own built-in schemaStore
-- support (HTTP-backed catalog) — no SchemaStore.nvim plugin.
M.base_lsp = {
	"bashls", -- universal: shell scripts everywhere
	"lua_ls", -- this config's own language; vendored 'after/lsp/lua_ls.lua'
}
M.base_treesitter = { "bash" }

M.feature_lsp = {
	python = { "pyright", "ruff" },
	rust = { "rust_analyzer" },
	typescript = { "vtsls", "cssls", "html", "somesass_ls" },
	clang = { "clangd" },
	cmake = { "neocmake" },
	docker = { "dockerls", "docker_compose_language_service" },
	json = { "jsonls" },
	yaml = { "yamlls" },
	nushell = { "nushell" },
	dotnet = { "html", "cssls", "somesass_ls" }, -- markup for Razor cohosting; roslyn via easy-dotnet
}

M.feature_treesitter = {
	python = { "python" },
	rust = { "rust", "ron" },
	typescript = { "typescript", "tsx", "javascript", "html" },
	clang = { "c", "cpp" },
	cmake = { "cmake" },
	docker = { "dockerfile" },
	sql = { "sql" },
	json = { "json", "json5" }, -- no jsonc parser in nvim-treesitter (unsupported language); json covers it
	yaml = { "yaml" },
	nushell = { "nu" },
	git = { "gitcommit", "gitignore", "git_rebase", "gitattributes" },
	dotnet = { "c_sharp", "razor", "html" }, -- html is required by razor's injections.scm for markup regions
}

local function resolve_profile()
	local p = env("NVIM_PROFILE")
	if p == "full" or p == "minimal" then
		return p
	end
	return "minimal"
end

local function resolve_langs()
	local set = {}
	if resolve_profile() == "full" then
		for _, name in ipairs(M.feature_order) do
			set[name] = true
		end
		return set
	end
	for _, name in ipairs(M.minimal_langs) do
		set[name] = true
	end
	local list = env("NVIM_LANGS")
	if list then
		for token in list:gmatch("[^,%s]+") do
			if vim.tbl_contains(M.feature_order, token) then
				set[token] = true
			end
		end
	end
	return set
end

M.profile = resolve_profile()
M.langs = resolve_langs()

--- Is a given feature enabled in this environment?
function M.has(feature)
	return M.langs[feature] == true
end

--- Any language enabled at all? Used to gate the generic dap.lua wiring.
function M.any_lang()
	return next(M.langs) ~= nil
end

return M
