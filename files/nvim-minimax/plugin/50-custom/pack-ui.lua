-- Floating-window UI for Neovim's built-in `vim.pack` plugin manager
-- (https://codeberg.org/cryptomilk/nvim-pack-ui).
--
-- Registered only — no auto-open. `vim.pack.add()` is synchronous, so any
-- UI opened inside the `PackChanged` event stream renders stale state while
-- the next install continues underneath; opening `:Pack` (or `:Pack check`
-- to also probe remotes) manually shows the settled state. Deliberately in
-- `Config.now` so it's installed *before* every other `vim.pack.add()` in
-- this config runs and can't be a latecomer on a fresh `~/.local/share`.
--
-- Keymaps inside the UI window: U (update all), u (update under cursor),
-- C (check remote), X (clean non-active), D (delete), L (log),
-- <CR> (details), ]]/[[ (next/prev plugin), ? (help), q/<Esc> (close).
Config.now(function()
  vim.pack.add({ { src = 'https://codeberg.org/cryptomilk/nvim-pack-ui' } })
end)
