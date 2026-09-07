require("full-border"):setup()

-- Shell prompt (top header line). No padded-border snippet: it conflicts with
-- full-border's Tab.build override.
require("starship"):setup()

-- Disk space meter in the status bar (uses `df`).
require("sduf"):setup()

require("recycle-bin"):setup()

require("bunny"):setup({
	hops = {
		{ key = "/", path = "/" },
		{ key = "t", path = "/tmp" },
		{ key = "h", path = "~", desc = "Home" },
{{ GAMING_HOPS }}		{ key = "d", path = "~/Downloads", desc = "Downloads" },
		{ key = "r", path = "~/repos", desc = "Development" },
		{ key = "v", path = "~/Videos", desc = "Videos" },
		{ key = "M", path = "~/Music", desc = "Music" },
		{ key = "p", path = "~/Pictures", desc = "Pictures" },
		{ key = "c", path = "~/.config", desc = "Config files" },
	},
	desc_strategy = "path", -- If desc isn't present, use "path" or "filename", default is "path"
	ephemeral = true, -- Enable ephemeral hops, default is true
	tabs = true, -- Enable tab hops, default is true
	notify = false, -- Notify after hopping, default is false
	fuzzy_cmd = "fzf", -- Fuzzy searching command, default is "fzf"
})

require("yaziline"):setup({
	separator_style = "angly", -- powerline look, matches previous yatline setup
})

-- ~/.config/yazi/init.lua
require("linemode-plus"):setup({
	-- Date formatting mode
	-- Available options:
	--   "default" - Yazi's native format with conditional year display:
	--               • For current year:     "MM/DD HH:mm"
	--               • For other years:      "MM/DD  YYYY"
	--
	--   "custom"  - smart user-defined format with today detection:
	--               • For today's files:     "HH:mm" (time only)
	--               • For older files:       Custom date format from 'custom' table
	--                 (configurable order, separator and year digits)
	date_mode = "custom",
	-- Custom format settings (only used when mode = "custom")
	custom = {
		-- Date components order
		-- MUST contain all three components: "year", "month", "day"
		-- Each component must appear exactly once (no duplicates)
		--
		-- All valid examples:
		--   { "year", "month", "day" }     -- year → month → day
		--   { "year", "day", "month" }     -- year → day → month
		--   { "month", "year", "day" }     -- month → year → day
		--   { "month", "day", "year" }     -- month → day → year
		--   { "day", "year", "month" }     -- day → year → month
		--   { "day", "month", "year" }     -- day → month → year
		order = { "year", "month", "day" },
		-- Separator between date components
		-- Allowed separators: "-", "/", "."  (only these characters are supported)
		--
		-- Examples:
		--   "-" -> 2026-02-20
		--   "/" -> 2026/02/20
		--   "." -> 2026.02.20
		separator = "-",

		-- Number of digits for the year:
		--   4 -> 2026 (full year)
		--   2 -> 26   (short year)
		year_digits = 4,
	},
})
require("session"):setup({
	sync_yanked = true,
})
