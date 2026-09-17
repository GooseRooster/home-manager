-- Port of LazyVim's `lazyvim.plugins.extras.ui.mini-animate` extra.
--
-- `mini.animate` itself needs no `vim.pack.add()` — it ships inside
-- `mini.nvim`, already vendored by MiniMax core. It's just commented out by
-- default there (`vendor/minimax/plugin/30_mini.lua`: "not enabled by
-- default because its effects are a matter of taste") — this file is that
-- opt-in, done from the overlay instead of touching the vendored file.
--
-- Dropped from the original (no equivalent here): the "disable snacks
-- scroll when animate is enabled" stanza (no snacks.nvim in this config at
-- all) and the `grug-far` filetype disable (grug-far.nvim isn't part of
-- this plugin set). The `Snacks.toggle(...)` UI toggle is reimplemented as
-- a plain keymap instead, since there's no snacks toggle framework here —
-- added under MiniMax's own `<Leader>o` ("Other") group rather than
-- inventing a new one for a single mapping.
Config.later(function()
  if vim.g.neovide ~= nil then return end -- neovide has its own animations

  -- Don't animate when scrolling with the mouse.
  local mouse_scrolled = false
  for _, scroll in ipairs({ 'Up', 'Down' }) do
    local key = '<ScrollWheel' .. scroll .. '>'
    vim.keymap.set({ '', 'i' }, key, function()
      mouse_scrolled = true
      return key
    end, { expr = true })
  end

  local animate = require('mini.animate')
  animate.setup({
    resize = {
      timing = animate.gen_timing.linear({ duration = 50, unit = 'total' }),
    },
    scroll = {
      timing = animate.gen_timing.linear({ duration = 150, unit = 'total' }),
      subscroll = animate.gen_subscroll.equal({
        predicate = function(total_scroll)
          if mouse_scrolled then
            mouse_scrolled = false
            return false
          end
          return total_scroll > 1
        end,
      }),
    },
  })

  vim.keymap.set(
    'n',
    '<Leader>oa',
    function() vim.g.minianimate_disable = not vim.g.minianimate_disable end,
    { desc = 'Toggle animate' }
  )
end)
