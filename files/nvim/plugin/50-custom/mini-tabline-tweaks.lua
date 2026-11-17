-- Quick on/off toggle for 'mini.tabline' (the buffer "bufferline" at the top).
--
-- 'vendor/nvim/plugin/30_mini.lua' calls `require('mini.tabline').setup()`
-- inside `now()`, which forces `'showtabline'` to 2. mini.tabline's own
-- `vim.g.minitabline_disable` flag only blanks the line's *content* — the
-- empty row would still be reserved — so the toggle also flips
-- `'showtabline'` (0 = hidden, 2 = always shown) to get the row back.
--
-- Set `enabled` below to change the startup state; `<Leader>ob` toggles it at
-- runtime (under MiniMax's `<Leader>o` "Other" group, next to `<Leader>oa`
-- from 'mini-animate.lua').
--
-- Must run after MiniMax's own `now()` setup call so that its
-- `showtabline = 2` doesn't overwrite ours — guaranteed here since `later()`
-- callbacks run after all `now()` ones.
Config.later(function()
	local enabled = false

	local apply = function()
		vim.g.minitabline_disable = not enabled
		vim.o.showtabline = enabled and 2 or 0
	end

	apply()

	vim.keymap.set("n", "<Leader>ob", function()
		enabled = not enabled
		apply()
	end, { desc = "Toggle tabline" })
end)
