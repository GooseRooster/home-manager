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
--
-- 'clipboard' is left at 'unnamedplus' (yank/put auto-sync with the system
-- clipboard), but the provider commands are overridden via 'g:clipboard' so
-- that they are TIME-BOUNDED.
--
-- Why: the Wayland clipboard is reached through shell commands
-- ('wl-paste'/'wl-copy'), which talk to the compositor over the Wayland
-- socket. When the compositor's current selection is stale (its owner no
-- longer answers the data request), 'wl-paste' never returns — it blocks
-- forever inside the compositor round-trip. Neovim probes the clipboard
-- provider *synchronously* during startup, so a hung 'wl-paste' blocks the
-- whole startup path: the TUI never finishes drawing, the instance stops
-- answering RPC, and the window looks frozen. This was reproducible with
-- this config only in standalone ghostty windows (the selection the
-- compositor hands out there can carry a broken/empty mime-type list, so
-- the data transfer never completes), while the same config started fine
-- inside herdr panes.
--
-- 'timeout' bounds the wait in both directions: a clipboard that does not
-- answer within the timeout reads as empty (and a copy that does not answer
-- is simply dropped) instead of hanging Neovim. 0.5s for the paste is
-- generous for a local compositor round-trip; 2s for the copy leaves room
-- for 'wl-copy' to fork into the background and take ownership.
vim.g.clipboard = {
  name = 'wl-clipboard-timeout',
  copy = {
    ['+'] = { 'timeout', '2', 'wl-copy' },
    ['*'] = { 'timeout', '2', 'wl-copy', '--primary' },
  },
  paste = {
    ['+'] = { 'timeout', '0.5', 'wl-paste', '--no-newline' },
    ['*'] = { 'timeout', '0.5', 'wl-paste', '--no-newline', '--primary' },
  },
  -- 'wl-copy' daemonises (forks, keeps the selection alive); the cache
  -- bookkeeping in 'g:clipboard' keys off the copy process' lifetime, which
  -- a timed-out foreground process would end immediately. Caching is
  -- pointless here — the clipboard is already the source of truth.
  cache_enabled = 0,
}
vim.o.clipboard = 'unnamedplus'

-- `:!`/`system()`/`:term` shell.
vim.o.shell = 'zsh'
