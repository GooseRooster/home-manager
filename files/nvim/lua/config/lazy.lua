local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

-- Build the extras spec from the environment profile (see config/profile.lua).
-- On a host this resolves to everything; in a dev container it resolves to the
-- minimal baseline plus whatever NVIM_LANGS opts in.
local profile = require("config.profile")

local spec = {
	-- add LazyVim and import its plugins
	{ "LazyVim/LazyVim", import = "lazyvim.plugins" },
}

-- Always-on, stack-agnostic extras (coding/editor/ui/util). Must come before
-- `plugins`, or lazy.nvim's import-order check flags them as out of order.
for _, import in ipairs(profile.core_extras) do
	spec[#spec + 1] = { import = import }
end

-- Language extras, gated per feature. Iterate feature_order (not the features
-- map) so imports stay deterministically ordered.
for _, name in ipairs(profile.feature_order) do
	if profile.has(name) then
		for _, import in ipairs(profile.features[name].extras) do
			spec[#spec + 1] = { import = import }
		end
	end
end

-- The debug/test machinery is only worth loading when at least one language is on.
if profile.any_lang() then
	spec[#spec + 1] = { import = "lazyvim.plugins.extras.dap.core" }
	spec[#spec + 1] = { import = "lazyvim.plugins.extras.dap.nlua" }
	spec[#spec + 1] = { import = "lazyvim.plugins.extras.test.core" }
end

-- import/override with your plugins (must stay last).
spec[#spec + 1] = { import = "plugins" }

require("lazy").setup({
	spec = spec,
	defaults = {
		-- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
		-- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
		lazy = false,
		-- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
		-- have outdated releases, which may break your Neovim install.
		version = false, -- always use the latest git commit
		-- version = "*", -- try installing the latest stable version for plugins that support semver
	},
	install = { colorscheme = { "tokyonight", "habamax" } },
	checker = {
		enabled = true, -- check for plugin updates periodically
		notify = false, -- notify on update
	}, -- automatically check for plugin updates
	performance = {
		rtp = {
			-- disable some rtp plugins
			disabled_plugins = {
				"gzip",
				-- "matchit",
				-- "matchparen",
				-- "netrwPlugin",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
			},
		},
	},
})
