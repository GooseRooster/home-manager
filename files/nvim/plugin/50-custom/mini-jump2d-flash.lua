-- Replace mini.jump2d's default `<CR>` binding with a flash.nvim-style
-- 2-character query jump, since the default word/line-start spotter isn't
-- very useful in practice.
--
-- Flow: press <CR> -> type 2 characters (no further <CR> needed) -> every
-- match of that 2-char string in visible lines gets a label -> type the
-- label to jump there. <Esc>/<C-c> mid-query cancels.
--
-- Built the same way `MiniJump2d.builtin_opts.single_character` works
-- ('lua/mini/jump2d.lua'): a shared `opts` table whose `hooks.before_start`
-- mutates `opts.spotter` in place before spots are computed. This only
-- works when the SAME table is passed to `MiniJump2d.start()` on every
-- invocation (`H.get_config()` re-reads `opts.spotter` right after
-- `before_start()` mutates it) -- it would NOT work via `.setup()`, since
-- `.setup()` copies the (still stale) `spotter` field into `MiniJump2d.config`
-- once, before the closure ever mutates it. So we keep our own keymaps
-- instead of touching `MiniJump2d.config.spotter`/`.setup()`.
--
-- Must run after MiniMax's own mini.jump2d `later()`-deferred setup() call
-- (which installs the default `<CR>` mapping) -- guaranteed here since
-- `later()` callbacks fire in registration order (see
-- 'plugin/45_keymaps_extra.lua' for the same reasoning), and this file
-- sorts after '30_mini.lua' alphabetically either way.

local n_chars = 2

local function read_query(n)
  local chars = {}
  for _ = 1, n do
    local ok, ch = pcall(vim.fn.getcharstr)
    -- Cancel on <Esc>/<C-c> or failed read
    if not ok or ch == '\27' then return nil end
    table.insert(chars, ch)
  end
  return table.concat(chars)
end

Config.later(function()
  local jump2d = require('mini.jump2d')

  local flash_opts = {
    spotter = function() return {} end,
    allowed_lines = { blank = false, fold = false },
    hooks = {
      before_start = function()
        local query = read_query(n_chars)
        if query == nil then return end
        flash_opts.spotter = jump2d.gen_spotter.pattern(vim.pesc(query))
      end,
    },
  }

  -- Exposed globally so the operator-pending mapping below can invoke it via
  -- a `<Cmd>...<CR>` string, which mini.jump2d itself relies on for correct
  -- dot-repeat in operator-pending mode (see
  -- https://github.com/neovim/neovim/issues/23406).
  _G.MiniJump2dFlashStart = function() jump2d.start(flash_opts) end

  vim.keymap.set({ 'n', 'x' }, '<CR>', MiniJump2dFlashStart, { desc = 'Jump2d (flash-style query)' })
  vim.keymap.set('o', '<CR>', '<Cmd>lua MiniJump2dFlashStart()<CR>', { desc = 'Jump2d (flash-style query)' })
end)
