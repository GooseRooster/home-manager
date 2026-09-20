-- mini.files tweaks on top of MiniMax's stock setup ('30_mini.lua' sets
-- `windows.preview = true` and bookmarks; 'vendor/nvim/' stays a pure
-- upstream mirror, so these live in the overlay — same pattern as
-- 'mini-clue-tweaks.lua' and 'pick.lua': `MiniFiles.config` is re-read
-- fresh on every `MiniFiles.open()` (`H.get_config()`), so post-setup
-- changes apply from the next open).
--
-- Preview: `windows.width_preview` (the pane showing the file/dir under
-- cursor, default 25 cols) — widened so file previews are actually usable.
-- It only materializes when there's room for focus + preview width, so on
-- narrow terminals it gracefully stays off.
Config.later(function()
  local files = require('mini.files')
  files.config.windows.width_preview = 60

  -- `<CR>` = "open this": navigate into a directory, and for a file open it
  -- *and* close the explorer. This is exactly `go_in_plus`'s behavior —
  -- `MiniFiles.go_in({ close_on_file = true })` — just on a more convenient
  -- key than the default `L` (stock `l`/`L` keep working). Buffer-local via
  -- the documented 'MiniFilesBufferCreate' event so it never leaks outside
  -- the explorer.
  Config.new_autocmd('User', 'MiniFilesBufferCreate', function(args)
    local buf_id = args.data.buf_id
    vim.keymap.set('n', '<CR>', function()
      MiniFiles.go_in({ close_on_file = true })
    end, { buffer = buf_id, desc = 'Open entry (closes explorer on files)' })
  end, 'Add <CR> open-and-close mapping in mini.files')
end)
