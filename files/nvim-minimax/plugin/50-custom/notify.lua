-- Route `vim.notify()` through 'mini.notify'.
--
-- MiniMax's stock '30_mini.lua' sets up 'mini.notify' but deliberately
-- leaves `vim.notify` untouched (mini.notify's own default too) — so
-- notifications went through Neovim's default `:messages` handling and
-- never entered the history buffer. Assigning `vim.notify` here makes every
-- notification (errors, LSP progress, plugin notices) land in the history
-- `<Leader>en` (Notification history, stock keymap) shows.
--
-- Registered in a `later()` so this can't out-run the module's own setup;
-- any `vim.notify()` calls before that point keep the default behavior.
Config.later(function()
  vim.notify = require('mini.notify').make_notify()
end)
