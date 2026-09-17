-- Inline diagnostics as floating text at end of line
-- (rachartier/tiny-inline-diagnostic.nvim), instead of Neovim's built-in
-- virtual text.
--
-- Registers after '10_options.lua's own `later()`-deferred
-- `vim.diagnostic.config(...)` call, so the `virtual_text = false` here
-- wins: tiny-inline-diagnostic renders its own virtual text and would
-- otherwise duplicate the built-in per-line one.
Config.later(function()
  vim.pack.add({ 'https://github.com/rachartier/tiny-inline-diagnostic.nvim' })

  require('tiny-inline-diagnostic').setup({
    preset = 'powerline',
    transparent_bg = false,
    transparent_cursorline = true,
    disabled_ft = {},
  })

  vim.diagnostic.config({ virtual_text = false })
end)
