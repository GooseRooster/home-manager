-- Cosmetic icon prefixes on leader-group clue descriptions ("+Debug",
-- "+Find", ...). mini.clue itself has no icon rendering path at all (no
-- `MiniIcons` calls anywhere in its source) and mini.icons has no
-- `diagnostic`-style category for this either, so these are hand-picked
-- Nerd Font glyphs prepended as plain text — not a mini.icons integration,
-- just pizazz.
--
-- Glyphs are written as `\xXX` UTF-8 byte escapes (each comment names the
-- codepoint) rather than literal characters in the source: several editors/
-- terminals silently drop or mangle raw Private-Use-Area bytes on save, so
-- escapes are the only way to guarantee the exact bytes land in the file.
--
-- Safe to mutate `Config.leader_group_clues` entries here: per the comments
-- in '45_keymaps_extra.lua' and 'cairn.lua', mini.clue re-flattens/reads this
-- list at query time (when a clue popup actually opens), not once at
-- `MiniClue.setup()` time — so it doesn't matter that some group-adding
-- files (e.g. 'dap.lua', 'herdr-nvim.lua', 'cairn.lua') load alphabetically
-- after this one.
Config.later(function()
  local icons = {
    ['<Leader>a'] = '\xEF\x81\x80', -- U+F040 pencil (herdr: annotations)
    ['<Leader>b'] = '\xEF\x83\x85', -- U+F0C5 files-o (Buffer)
    ['<Leader>c'] = '\xEF\x82\x8D', -- U+F08D thumb-tack (cairn: arena)
    ['<Leader>d'] = '\xEF\x86\x88', -- U+F188 bug (Debug)
    ['<Leader>e'] = '\xEF\x81\xBC', -- U+F07C folder-open (Explore/Edit)
    ['<Leader>f'] = '\xEF\x80\x82', -- U+F002 search (Find)
    ['<Leader>g'] = '\xEF\x87\x93', -- U+F1D3 git (Git)
    ['<Leader>l'] = '\xEF\x84\xA1', -- U+F121 code (Language)
    ['<Leader>m'] = '\xEF\x83\xA8', -- U+F0E8 sitemap (Map)
    ['<Leader>o'] = '\xEF\x86\x92', -- U+F192 dot-circle (Other)
    ['<Leader>s'] = '\xEF\x83\x87', -- U+F0C7 floppy-o (Session)
    ['<Leader>t'] = '\xEF\x84\xA0', -- U+F120 terminal (Terminal)
    ['<Leader>v'] = '\xEF\x87\x9A', -- U+F1DA history (Visits)
  }

  for _, clue in ipairs(Config.leader_group_clues) do
    local icon = icons[clue.keys]
    if icon and clue.desc and not clue.desc:find(icon, 1, true) then
      clue.desc = icon .. ' ' .. clue.desc
    end
  end
end)
