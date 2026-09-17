-- Inline diagnostics as floating text at end of line
-- (rachartier/tiny-inline-diagnostic.nvim), instead of Neovim's built-in
-- virtual text.
--
-- Registers after '10_options.lua's own `later()`-deferred
-- `vim.diagnostic.config(...)` call, so this wins: the built-in per-line
-- virtual text is off (tiny-inline-diagnostic renders its own), and the
-- gutter signs become icon-only markers for every severity (stock config
-- shows E/W letters for WARN+ only — with everything inline, the gutter
-- carries all four).
Config.later(function()
	vim.pack.add({ "https://github.com/rachartier/tiny-inline-diagnostic.nvim" })

	require("tiny-inline-diagnostic").setup({
		preset = "powerline",
		transparent_bg = false,
		transparent_cursorline = true,
		disabled_ft = {},
	})
end)
