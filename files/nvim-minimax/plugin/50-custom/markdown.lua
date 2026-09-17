-- Port of the LazyVim setup's 'files/nvim/lua/plugins/markdown.lua'.
--
-- `nvim-treesitter`/`mini.nvim` deps are already present in MiniMax core, so
-- render-markdown.nvim needs no extra `vim.pack.add()` beyond itself.
-- `ft = "markdown"` (both plugins, in the original) becomes
-- `Config.on_filetype('markdown', ...)` — see 'plugin/50-custom/zk.lua' for
-- why the buffer-scoped setup below is called both from a persistent
-- autocmd (future buffers) and once directly (the buffer that triggered
-- this callback).
--
-- which-key's 16 buffer-scoped `wk.add({ ..., buffer = bufnr })` group
-- labels are translated to a single `require('config.clue').add_buf(bufnr, {...})`
-- call (mini.clue's buffer-local equivalent — see 'lua/config/clue.lua').
Config.on_filetype('markdown', function()
  vim.pack.add({ 'https://github.com/MeanderingProgrammer/render-markdown.nvim' })
  require('render-markdown').setup({})

  vim.pack.add({ 'https://github.com/yousefhadder/markdown-plus.nvim' })
  require('markdown-plus').setup({
    keymaps = { enabled = false }, -- kill default <localleader> tree
    table = { keymaps = { enabled = false } },
    links = { smart_paste = { enabled = true } }, -- opt-in, needs `curl`
  })

  local setup_buf = function(bufnr)
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
    end

    -- Formatting (leaf actions, top level)
    map({ 'n', 'x' }, '<Leader>Mb', '<Plug>(MarkdownPlusBold)', 'Bold')
    map({ 'n', 'x' }, '<Leader>Mi', '<Plug>(MarkdownPlusItalic)', 'Italic')
    map(
      { 'n', 'x' },
      '<Leader>Ms',
      '<Plug>(MarkdownPlusStrikethrough)',
      'Strikethrough'
    )
    map({ 'n', 'x' }, '<Leader>M`', '<Plug>(MarkdownPlusCode)', 'Inline code')
    map({ 'n', 'x' }, '<Leader>Mu', '<Plug>(MarkdownPlusUnderline)', 'Underline')
    map({ 'n', 'x' }, '<Leader>M=', '<Plug>(MarkdownPlusHighlight)', 'Highlight')
    map(
      'x',
      '<Leader>Me',
      '<Plug>(MarkdownPlusEscapeSelection)',
      'Escape/unescape punctuation'
    )
    map(
      { 'n', 'x' },
      '<Leader>MF',
      '<Plug>(MarkdownPlusClearFormatting)',
      'Clear formatting'
    )

    -- Headers / TOC
    map('n', '<Leader>Mh+', '<Plug>(MarkdownPlusPromoteHeader)', 'Promote header')
    map('n', '<Leader>Mh-', '<Plug>(MarkdownPlusDemoteHeader)', 'Demote header')
    for i = 1, 6 do
      map(
        'n',
        '<Leader>Mh' .. i,
        '<Plug>(MarkdownPlusHeader' .. i .. ')',
        'Set H' .. i
      )
    end
    map(
      'n',
      '<Leader>Mhs',
      '<Plug>(MarkdownPlusToggleAtxSetext)',
      'Toggle ATX/setext'
    )
    map('n', '<Leader>Mht', '<Plug>(MarkdownPlusGenerateTOC)', 'Generate TOC')
    map('n', '<Leader>Mhu', '<Plug>(MarkdownPlusUpdateTOC)', 'Update TOC')
    map('n', '<Leader>Mho', '<Plug>(MarkdownPlusOpenTocWindow)', 'Open TOC window')

    -- Thematic breaks
    map(
      'n',
      '<Leader>Mrr',
      '<Plug>(MarkdownPlusInsertThematicBreak)',
      'Insert break'
    )
    map(
      'n',
      '<Leader>Mrc',
      '<Plug>(MarkdownPlusCycleThematicBreak)',
      'Cycle break style'
    )

    -- Links (insert vs selection-to-link are separate <Plug> names)
    map('n', '<Leader>Mll', '<Plug>(MarkdownPlusInsertLink)', 'Insert link')
    map(
      'x',
      '<Leader>Mll',
      '<Plug>(MarkdownPlusSelectionToLink)',
      'Selection to link'
    )
    map('n', '<Leader>Mle', '<Plug>(MarkdownPlusEditLink)', 'Edit link')
    map('n', '<Leader>Mla', '<Plug>(MarkdownPlusAutoLinkURL)', 'Auto-link bare URL')
    map(
      'n',
      '<Leader>Mlr',
      '<Plug>(MarkdownPlusConvertToReference)',
      'Convert to reference'
    )
    map(
      'n',
      '<Leader>Mli',
      '<Plug>(MarkdownPlusConvertToInline)',
      'Convert to inline'
    )
    map('n', '<Leader>Mlp', '<Plug>(MarkdownPlusSmartPaste)', 'Smart paste URL')

    -- Images (same insert-vs-selection split as links)
    map('n', '<Leader>MIi', '<Plug>(MarkdownPlusInsertImage)', 'Insert image')
    map(
      'x',
      '<Leader>MIi',
      '<Plug>(MarkdownPlusSelectionToImage)',
      'Selection to image'
    )
    map('n', '<Leader>MIe', '<Plug>(MarkdownPlusEditImage)', 'Edit image')
    map(
      'n',
      '<Leader>MIt',
      '<Plug>(MarkdownPlusToggleImageLink)',
      'Toggle link/image'
    )

    -- Quotes & callouts
    map(
      { 'n', 'x' },
      '<Leader>Mqq',
      '<Plug>(MarkdownPlusToggleQuote)',
      'Toggle blockquote'
    )
    map(
      { 'n', 'x' },
      '<Leader>Mqi',
      '<Plug>(MarkdownPlusInsertCallout)',
      'Insert/wrap callout'
    )
    map(
      'n',
      '<Leader>Mqt',
      '<Plug>(MarkdownPlusToggleCalloutType)',
      'Cycle callout type'
    )
    map(
      'n',
      '<Leader>Mqc',
      '<Plug>(MarkdownPlusConvertToCallout)',
      'Blockquote -> callout'
    )
    map(
      'n',
      '<Leader>Mqb',
      '<Plug>(MarkdownPlusConvertToBlockquote)',
      'Callout -> blockquote'
    )

    -- Code blocks (]b / [b kept as raw motions, mirroring ]] / [[ for headers)
    map(
      { 'n', 'x' },
      '<Leader>Mcc',
      '<Plug>(MarkdownPlusCodeBlockInsert)',
      'Insert/wrap code block'
    )
    map(
      'n',
      '<Leader>Mcl',
      '<Plug>(MarkdownPlusCodeBlockChangeLanguage)',
      'Change language'
    )
    map(
      'n',
      '<Leader>Mcf',
      '<Plug>(MarkdownPlusCodeBlockToggleFence)',
      'Toggle fence style'
    )
    map('n', ']b', '<Plug>(MarkdownPlusCodeBlockNext)', 'Next code block')
    map('n', '[b', '<Plug>(MarkdownPlusCodeBlockPrev)', 'Previous code block')

    -- List management
    map(
      { 'n', 'x' },
      '<Leader>MLx',
      '<Plug>(MarkdownPlusToggleCheckbox)',
      'Toggle checkbox'
    )
    map('i', '<C-t>', '<Plug>(MarkdownPlusToggleCheckbox)', 'Toggle checkbox')
    map('n', '<Leader>MLr', '<Plug>(MarkdownPlusRenumberLists)', 'Renumber lists')
    map('n', '<Leader>MLo', '<Plug>(MarkdownPlusNewListItemBelow)', 'New item below')
    map('n', '<Leader>MLO', '<Plug>(MarkdownPlusNewListItemAbove)', 'New item above')

    local list_types = {
      u = 'MarkdownPlusToggleListUnordered',
      t = 'MarkdownPlusToggleListTask',
      n = 'MarkdownPlusToggleListOrdered',
      N = 'MarkdownPlusToggleListOrderedParen',
      l = 'MarkdownPlusToggleListLetterLower',
      L = 'MarkdownPlusToggleListLetterUpper',
      p = 'MarkdownPlusToggleListLetterLowerParen',
      P = 'MarkdownPlusToggleListLetterUpperParen',
      c = 'MarkdownPlusToggleListClear',
    }
    for key, plug in pairs(list_types) do
      map(
        { 'n', 'x' },
        '<Leader>MLt' .. key,
        '<Plug>(' .. plug .. ')',
        'List: ' .. key
      )
    end

    -- Table (mirrors upstream's own `t` scheme, just moved under <leader>Mt)
    map('n', '<Leader>Mtc', '<Plug>(MarkdownPlusTableCreate)', 'Create table')
    map('n', '<Leader>Mtf', '<Plug>(MarkdownPlusTableFormat)', 'Format table')
    map('n', '<Leader>Mtn', '<Plug>(MarkdownPlusTableNormalize)', 'Normalize table')
    map(
      'n',
      '<Leader>Mtir',
      '<Plug>(MarkdownPlusTableInsertRowBelow)',
      'Insert row below'
    )
    map(
      'n',
      '<Leader>MtiR',
      '<Plug>(MarkdownPlusTableInsertRowAbove)',
      'Insert row above'
    )
    map(
      'n',
      '<Leader>Mtic',
      '<Plug>(MarkdownPlusTableInsertColumnRight)',
      'Insert column right'
    )
    map(
      'n',
      '<Leader>MtiC',
      '<Plug>(MarkdownPlusTableInsertColumnLeft)',
      'Insert column left'
    )
    map('n', '<Leader>Mtdr', '<Plug>(MarkdownPlusTableDeleteRow)', 'Delete row')
    map(
      'n',
      '<Leader>Mtdc',
      '<Plug>(MarkdownPlusTableDeleteColumn)',
      'Delete column'
    )
    map(
      'n',
      '<Leader>Mtyr',
      '<Plug>(MarkdownPlusTableDuplicateRow)',
      'Duplicate row'
    )
    map(
      'n',
      '<Leader>Mtyc',
      '<Plug>(MarkdownPlusTableDuplicateColumn)',
      'Duplicate column'
    )
    -- Note: move-row/column has <Plug> targets but no documented default key upstream; I picked these
    map('n', '<Leader>Mtmj', '<Plug>(MarkdownPlusTableMoveRowDown)', 'Move row down')
    map('n', '<Leader>Mtmk', '<Plug>(MarkdownPlusTableMoveRowUp)', 'Move row up')
    map(
      'n',
      '<Leader>Mtmh',
      '<Plug>(MarkdownPlusTableMoveColumnLeft)',
      'Move column left'
    )
    map(
      'n',
      '<Leader>Mtml',
      '<Plug>(MarkdownPlusTableMoveColumnRight)',
      'Move column right'
    )
    map(
      'n',
      '<Leader>Mta',
      '<Plug>(MarkdownPlusTableToggleCellAlignment)',
      'Toggle cell alignment'
    )
    map('n', '<Leader>Mtx', '<Plug>(MarkdownPlusTableClearCell)', 'Clear cell')
    map(
      'n',
      '<Leader>Mtb',
      '<Plug>(MarkdownPlusTableInsertBreak)',
      'Insert <br> in cell'
    )
    map('n', '<Leader>Mtw', '<Plug>(MarkdownPlusTableWrapCell)', 'Wrap cell')
    map(
      'n',
      '<Leader>MtW',
      '<Plug>(MarkdownPlusTableUnwrapCell)',
      'Unwrap cell (strip <br>)'
    )
    map('n', '<Leader>Mte', '<Plug>(MarkdownPlusTableEditCell)', 'Edit cell (popup)')
    map('n', '<Leader>MtT', '<Plug>(MarkdownPlusTableTranspose)', 'Transpose table')
    map(
      'n',
      '<Leader>Mtsa',
      '<Plug>(MarkdownPlusTableSortAscending)',
      'Sort ascending'
    )
    map(
      'n',
      '<Leader>Mtsd',
      '<Plug>(MarkdownPlusTableSortDescending)',
      'Sort descending'
    )
    map('n', '<Leader>Mtvx', '<Plug>(MarkdownPlusTableToCSV)', 'Table -> CSV')
    map('n', '<Leader>Mtvi', '<Plug>(MarkdownPlusTableFromCSV)', 'CSV -> table')
    -- insert-mode cell nav kept raw (Alt+hjkl), same rationale as ]b/[b
    map('i', '<A-h>', '<Plug>(MarkdownPlusTableNavLeft)', 'Cell left')
    map('i', '<A-l>', '<Plug>(MarkdownPlusTableNavRight)', 'Cell right')
    map('i', '<A-j>', '<Plug>(MarkdownPlusTableNavDown)', 'Cell down')
    map('i', '<A-k>', '<Plug>(MarkdownPlusTableNavUp)', 'Cell up')

    -- Footnotes ("notes")
    map('n', '<Leader>Mni', '<Plug>(MarkdownPlusFootnoteInsert)', 'Insert footnote')
    map('n', '<Leader>Mne', '<Plug>(MarkdownPlusFootnoteEdit)', 'Edit footnote')
    map('n', '<Leader>Mnd', '<Plug>(MarkdownPlusFootnoteDelete)', 'Delete footnote')
    map(
      'n',
      '<Leader>Mng',
      '<Plug>(MarkdownPlusFootnoteGotoDefinition)',
      'Go to definition'
    )
    map(
      'n',
      '<Leader>Mnr',
      '<Plug>(MarkdownPlusFootnoteGotoReference)',
      'Go to reference(s)'
    )
    map('n', '<Leader>Mnn', '<Plug>(MarkdownPlusFootnoteNext)', 'Next footnote')
    map('n', '<Leader>Mnp', '<Plug>(MarkdownPlusFootnotePrev)', 'Previous footnote')
    map('n', '<Leader>Mnl', '<Plug>(MarkdownPlusFootnoteList)', 'List footnotes')

    -- Buffer-scoped which-key group labels, translated to mini.clue.
    require('config.clue').add_buf(bufnr, {
      { mode = 'n', keys = '<Leader>M', desc = '+markdown' },
      { mode = 'n', keys = '<Leader>Mh', desc = '+headers/toc' },
      { mode = 'n', keys = '<Leader>Mr', desc = '+thematic rule' },
      { mode = 'n', keys = '<Leader>Ml', desc = '+links' },
      { mode = 'n', keys = '<Leader>MI', desc = '+images' },
      { mode = 'n', keys = '<Leader>Mq', desc = '+quote/callout' },
      { mode = 'n', keys = '<Leader>Mc', desc = '+code block' },
      { mode = 'n', keys = '<Leader>ML', desc = '+list' },
      { mode = 'n', keys = '<Leader>MLt', desc = '+list type' },
      { mode = 'n', keys = '<Leader>Mt', desc = '+table' },
      { mode = 'n', keys = '<Leader>Mti', desc = '+insert row/col' },
      { mode = 'n', keys = '<Leader>Mtd', desc = '+delete row/col' },
      { mode = 'n', keys = '<Leader>Mty', desc = '+duplicate row/col' },
      { mode = 'n', keys = '<Leader>Mtm', desc = '+move row/col' },
      { mode = 'n', keys = '<Leader>Mts', desc = '+sort' },
      { mode = 'n', keys = '<Leader>Mtv', desc = '+csv' },
      { mode = 'n', keys = '<Leader>Mn', desc = '+notes (footnotes)' },
    })
  end

  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'markdown',
    callback = function(args) setup_buf(args.buf) end,
  })

  -- Apply to the buffer that triggered this `on_filetype` callback too (see
  -- 'plugin/50-custom/zk.lua' for why the autocmd above alone isn't enough).
  setup_buf(vim.api.nvim_get_current_buf())
end)
