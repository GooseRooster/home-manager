-- ┌─────────────────────────────┐
-- │ Custom options (extra layer)│
-- └─────────────────────────────┘
--
-- Runs after MiniMax's stock 'plugin/10_options.lua' (numeric prefix 15 > 10)
-- for options that stock doesn't set. 'vendor/nvim/' stays a pure upstream
-- mirror — these are overlay-only tweaks, mirroring how '45_keymaps_extra.lua'
-- extends '20_keymaps.lua'.

-- Sync yanks/puts with the system clipboard (wl-clipboard providers are in
-- 'pkgs/base.nix').
vim.o.clipboard = 'unnamedplus'

-- `:!`/`system()`/`:term` shell.
vim.o.shell = 'zsh'
