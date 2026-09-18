-- Inline diagnostics as floating text at end of line
-- (rachartier/tiny-inline-diagnostic.nvim), instead of Neovim's built-in
-- virtual text.
--
-- Registers after '10_options.lua's own `later()`-deferred
-- `vim.diagnostic.config(...)` call, so this wins: the built-in per-line
-- virtual text is off (tiny-inline-diagnostic renders its own), and the
-- gutter signs become icons instead of letters (still WARN+ only, matching
-- '10_options.lua's `severity` filter — mini.icons has no `diagnostic`
-- category, so these are hand-picked Nerd Font glyphs, same convention as
-- the icon table in 'easy-dotnet.lua').
Config.later(function()
	vim.pack.add({ "https://github.com/rachartier/tiny-inline-diagnostic.nvim" })

	-- `vim.diagnostic.config()` replaces the whole `signs` sub-table on each
	-- call (no deep merge), so priority/severity from '10_options.lua' must be
	-- restated here alongside the new icon text, or they'd silently revert to
	-- defaults.
	--
	-- Glyphs are `\xXX` UTF-8 byte escapes rather than literal characters:
	-- several editors/terminals silently drop or mangle raw Private-Use-Area
	-- bytes on save, so escapes are the only way to guarantee the exact bytes
	-- land in the file.
	vim.diagnostic.config({
		signs = {
			priority = 9999,
			severity = { min = "WARN", max = "ERROR" },
			text = {
				[vim.diagnostic.severity.ERROR] = "\xEF\x81\x97", -- U+F057 times-circle
				[vim.diagnostic.severity.WARN] = "\xEF\x81\xB1", -- U+F071 exclamation-triangle
			},
		},
	})

	require("tiny-inline-diagnostic").setup({
		preset = "powerline",
		transparent_bg = false,
		transparent_cursorline = true,
		disabled_ft = {},
	})
end)
