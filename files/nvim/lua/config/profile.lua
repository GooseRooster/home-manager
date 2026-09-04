-- Environment-driven feature profile.
--
-- Single source of truth for WHICH languages/features this Neovim should load.
-- Both `config/lazy.lua` (which LazyVim extras to import) and `plugins/mason.lua`
-- (which tools to install) derive from the tables here, and language-specific
-- plugin specs gate themselves with `enabled = require("config.profile").has(...)`.
--
-- Why runtime (not chezmoi templating): the decision is read live from the
-- environment at every nvim startup, so a dev container can drive it purely via
-- `containerEnv` without re-running `chezmoi apply`. The config file stays
-- byte-identical on every machine.
--
-- Control:
--   NVIM_PROFILE = "full" | "minimal"   coarse override (optional)
--   NVIM_LANGS   = "rust,python,..."    comma list of extra langs (minimal only)
--
-- Defaults: everything resolves to "minimal" — baseline below plus whatever
-- NVIM_LANGS opts in (typically via a project .envrc). "full" is a deliberate
-- per-machine opt-in (NVIM_PROFILE=full) for hosts that genuinely carry every
-- toolchain; an accidental launch with the env unset must never be able to pull
-- the kitchen sink. On NixOS a stray "full" resolve is actively harmful: mason
-- would install prebuilt native servers (clangd, rust-analyzer, ...) that
-- cannot run there at all (see nix_substitutes below).
-- NOTE: do not run `:LazyExtras` — it writes `lazyvim.json`, which LazyVim imports
-- outside this gate. The `features` map below is the source of truth for extras.

local M = {}

local function env(name)
	local v = vim.env[name]
	if v == nil or v == "" then
		return nil
	end
	return v
end

-- Ordered so extras import deterministically (lazy.nvim's "extras before plugins"
-- import-order check is sensitive to order). Iterate this with ipairs, never the
-- `features` map with pairs.
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

-- feature -> { extras = <LazyVim extra imports>, mason = <tools that feature needs> }.
-- Every language-specific Mason tool lives here (NOT in baseline_mason), so a minimal
-- profile never installs tooling for a language it isn't using.
M.features = {
	python = {
		extras = { "lazyvim.plugins.extras.lang.python" },
		-- pyright + ruff LSPs are installed by the python extra (mason-lspconfig).
		mason = {},
	},
	rust = {
		extras = { "lazyvim.plugins.extras.lang.rust" },
		-- rust-analyzer stays: the rust extra sets `rust_analyzer = { enabled = false }`
		-- (rustaceanvim drives it and expects it on PATH), so nothing installs it for us.
		mason = { "rust-analyzer", "codelldb" },
	},
	typescript = {
		extras = { "lazyvim.plugins.extras.lang.typescript" },
		-- vtsls (the extra's default LSP) is installed by the extra. css/html/sass
		-- servers are NOT registered by any extra, so they must live here.
		-- typescript-language-server is kept only for on-demand use (tsserver is
		-- enabled=false since vtsls is chosen); drop it if you never want it.
		mason = {
			"typescript-language-server",
			"js-debug-adapter",
			"css-lsp",
			"html-lsp",
			"some-sass-language-server",
		},
	},
	java = {
		extras = { "lazyvim.plugins.extras.lang.java" },
		-- jdtls LSP is installed by the java extra. gradle-language-server is not,
		-- so it stays here.
		mason = { "java-debug-adapter", "java-test", "gradle-language-server" },
	},
	-- C/C++ (clangd LSP + clangd_extensions + c/cpp treesitter + codelldb debugging).
	clang = {
		extras = { "lazyvim.plugins.extras.lang.clangd" },
		-- clangd LSP is installed by the clangd extra; only codelldb (DAP) stays.
		mason = { "codelldb" },
	},
	cmake = {
		extras = { "lazyvim.plugins.extras.lang.cmake" },
		-- neocmakelsp is installed by the cmake extra; keep the lint/format tools.
		mason = { "cmakelang", "cmakelint" },
	},
	docker = {
		extras = { "lazyvim.plugins.extras.lang.docker" },
		-- dockerls + docker-compose LSPs are installed by the docker extra.
		mason = { "hadolint" },
	},
	sql = {
		extras = { "lazyvim.plugins.extras.lang.sql" },
		mason = { "sqlfluff" },
	},
	json = {
		extras = { "lazyvim.plugins.extras.lang.json" },
		-- jsonls is installed by the json extra.
		mason = {},
	},
	yaml = {
		extras = { "lazyvim.plugins.extras.lang.yaml" },
		-- yamlls is installed by the yaml extra.
		mason = {},
	},
	nushell = {
		extras = { "lazyvim.plugins.extras.lang.nushell" },
		mason = {},
	},
	git = {
		extras = { "lazyvim.plugins.extras.lang.git" },
		mason = {},
	},
	-- No LazyVim extra; gates the custom easy-dotnet/lazydotnet plugins + the C#
	-- snippet block. Roslyn is fetched by easy-dotnet itself (not Mason), so gating
	-- the plugin via `enabled` is what actually prevents that download.
	-- html-lsp is here because Razor (.razor/.cshtml) leans on the HTML language
	-- server for its markup regions. c_sharp/razor treesitter parsers have no
	-- LazyVim extra to pull them in, so declare them here (they were previously
	-- only ever installed by hand via :TSInstall).
	dotnet = {
		extras = {},
		mason = {
			"js-debug-adapter",
			"css-lsp",
			"html-lsp",
			"some-sass-language-server",
		},
		treesitter = { "c_sharp", "razor" },
	},
}

-- Always imported, in every profile: stack-agnostic coding/editor/ui/util extras.
-- (mini-animate + smear-cursor are intentionally kept everywhere.)
M.core_extras = {
	"lazyvim.plugins.extras.coding.mini-surround",
	"lazyvim.plugins.extras.coding.neogen",
	"lazyvim.plugins.extras.coding.yanky",
	"lazyvim.plugins.extras.editor.dial",
	"lazyvim.plugins.extras.editor.illuminate",
	"lazyvim.plugins.extras.editor.inc-rename",
	"lazyvim.plugins.extras.editor.navic",
	"lazyvim.plugins.extras.editor.outline",
	"lazyvim.plugins.extras.ui.mini-animate",
	"lazyvim.plugins.extras.ui.smear-cursor",
	"lazyvim.plugins.extras.util.dot",
	"lazyvim.plugins.extras.util.mini-hipatterns",
	"lazyvim.plugins.extras.util.startuptime",
	"lazyvim.plugins.extras.util.rest",
}

-- Language-agnostic Mason tools kept in every profile.
-- LSP servers are intentionally NOT listed here: lua_ls is registered by LazyVim
-- core and bashls by the always-on util.dot extra, so mason-lspconfig already
-- installs both. Listing them here too made mason.nvim and mason-lspconfig race
-- to install the same package ("Package is already installing"). Only non-server
-- tools (formatters/linters) belong here.
M.baseline_mason = {
	"stylua",
	"shellcheck",
	"shfmt",
}

-- Treesitter parsers kept in every profile, on top of LazyVim core's base set
-- (bash, c, html, json, lua, markdown, markdown_inline, python, vim, yaml, ...).
-- Most language parsers ride in with their feature's extra (opts_extend merges
-- them), so features only need a `treesitter` entry for parsers no extra provides
-- (see dotnet). Add a parser here only if you want it available everywhere.
M.baseline_treesitter = {}

-- Universal languages enabled even in the minimal profile (markdown highlighting
-- comes from LazyVim core's treesitter list, so it needs no feature here).
-- python earns a place here: standalone scripts show up everywhere, and its
-- whole toolchain is mason-safe on NixOS (pyright = node, ruff = static,
-- debugpy = pip), so it never needs a project devshell to work.
M.minimal_langs = { "python", "git", "json", "yaml", "docker", "nushell" }

function M.is_container()
	return env("CONTAINER_ID") ~= nil
end

function M.is_host()
	return not M.is_container()
end

local function resolve_profile()
	local p = env("NVIM_PROFILE")
	if p == "full" or p == "minimal" then
		return p
	end
	-- Hosts and containers share the same lean default; "full" is always an
	-- explicit opt-in. See the header comment for why.
	return "minimal"
end

local function resolve_langs()
	local set = {}
	if resolve_profile() == "full" then
		for name in pairs(M.features) do
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
			if M.features[token] then
				set[token] = true
			end
		end
	end
	return set
end

M.profile = resolve_profile()
M.langs = resolve_langs()

-- Is a given feature enabled in this environment?
function M.has(feature)
	return M.langs[feature] == true
end

-- Any language enabled at all? Used to gate the dap/test machinery, which is
-- pointless with zero languages.
function M.any_lang()
	return next(M.langs) ~= nil
end

-- ──────────────────────────────────────────────────────────────────────
-- Environment-sourced tools (home profile / project devshell).
--
-- Mason's downloads for these packages are prebuilt *native* binaries; on
-- NixOS such ELFs cannot run (no /lib64 loader — the stub-ld error), so on
-- NixOS they must always come from the environment: the home profile
-- (pkgs/base.nix) or a project devshell. Everywhere else mason stays a fine
-- fallback — the tools simply prefer whatever is already on PATH.
--
-- Keyed by mason package name -> the PATH binary to look for.
M.nix_substitutes = {
	["lua-language-server"] = "lua-language-server",
	clangd = "clangd",
	["rust-analyzer"] = "rust-analyzer",
	neocmakelsp = "neocmakelsp",
	codelldb = "codelldb",
	stylua = "stylua",
}

function M.is_nixos()
	return vim.fn.filereadable("/etc/NIXOS") == 1
end

--- How a tool mason would otherwise install should actually be sourced.
---   "system" — binary is on PATH: use it, keep mason out of it
---   "skip"   — on NixOS with no binary: leave the tool off entirely rather
---              than let mason install a copy that can't run
---   "mason"  — not a substituted tool (or generic Linux, no binary): mason,
---              exactly as before
function M.tool_source(mason_pkg)
	local bin = M.nix_substitutes[mason_pkg]
	if bin == nil then
		return "mason"
	end
	if vim.fn.executable(bin) == 1 then
		return "system"
	end
	return M.is_nixos() and "skip" or "mason"
end

return M
