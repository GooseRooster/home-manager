-- Cursor/scroll animations (mini.animate, ships inside 'mini.nvim' but is
-- left commented out in MiniMax's own '30_mini.lua' — this file is that
-- opt-in, done from the overlay instead of touching the vendored file).
--
-- Plus a plain keymap toggle under MiniMax's `<Leader>o` ("Other") group,
-- and the neovide guard: neovide has its own animations.
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
