-- zk note-taking (zk-org/zk-nvim). Loaded only when `zk` is on PATH, only
-- for markdown buffers.
--
-- `Config.on_filetype` fires once, on the *first* markdown buffer — the
-- buffer-scoped keymap autocmd registered below only fires for *subsequent*
-- markdown buffers (a freshly-registered autocmd doesn't retroactively apply
-- to the event currently being processed), so the setup function is called
-- once directly for that first buffer too, further down.
Config.on_filetype('markdown', function()
  if vim.fn.executable('zk') ~= 1 then return end

  vim.pack.add({ { src = 'https://github.com/zk-org/zk-nvim', name = 'zk' } })

  require('zk').setup({
    picker = 'select', -- matches easy-dotnet's picker choice; swap if you use something else
    lsp = {
      config = {
        name = 'zk',
        cmd = { 'zk', 'lsp' },
        filetypes = { 'markdown' },
      },
      auto_attach = { enabled = true },
    },
  })

  local setup_buf = function(bufnr)
    local path = vim.api.nvim_buf_get_name(bufnr)
    if path == '' then
      return -- unsaved buffer, nothing to check membership against yet
    end

    local notebook_root = require('zk.util').notebook_root(path)
    if notebook_root == nil then
      return -- ordinary markdown file, not in ~/notes or any other notebook
    end

    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
    end

    -- Note creation (dir defaults to the current buffer's directory)
    map(
      'n',
      '<Leader>zn',
      function()
        vim.cmd(
          ("ZkNew { dir = %q, title = vim.fn.input('Title: ') }"):format(
            vim.fn.expand('%:p:h')
          )
        )
      end,
      'New note (here)'
    )
    map(
      'v',
      '<Leader>znt',
      ":'<,'>ZkNewFromTitleSelection { dir = vim.fn.expand('%:p:h') }<CR>",
      'New note from selection (title)'
    )
    map(
      'v',
      '<Leader>znc',
      function()
        vim.cmd(
          (":'<,'>ZkNewFromContentSelection { dir = %q, title = vim.fn.input('Title: ') }"):format(
            vim.fn.expand('%:p:h')
          )
        )
      end,
      'New note from selection (content)'
    )

    -- Navigation
    map(
      'n',
      '<Leader>zo',
      "<Cmd>ZkNotes { sort = { 'modified' } }<CR>",
      'Open notes'
    )
    map('n', '<Leader>zb', '<Cmd>ZkBacklinks<CR>', 'Backlinks')
    map('n', '<Leader>zl', '<Cmd>ZkLinks<CR>', 'Outbound links')
    map('n', '<Leader>zt', '<Cmd>ZkTags<CR>', 'Notes by tag')

    -- Search
    map(
      'n',
      '<Leader>zf',
      function()
        vim.cmd(
          ("ZkNotes { sort = { 'modified' }, match = { %q } }"):format(
            vim.fn.input('Search: ')
          )
        )
      end,
      'Search notes'
    )
    map('v', '<Leader>zf', ":'<,'>ZkMatch<CR>", 'Search matching selection')

    -- LSP-backed link/preview behavior — only meaningful because auto_attach
    -- has already attached zk's LSP client to this same notebook_root check
    map('n', '<CR>', vim.lsp.buf.definition, 'Follow link under cursor')
    map('n', 'K', vim.lsp.buf.hover, 'Preview linked note')
    map('v', '<Leader>za', vim.lsp.buf.code_action, 'Code action on selection')

    require('config.clue').add_buf(
      bufnr,
      { { mode = 'n', keys = '<Leader>z', desc = '+zk notes' } }
    )
  end

  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'markdown',
    callback = function(args) setup_buf(args.buf) end,
  })

  -- Apply to the buffer that triggered this `on_filetype` callback too (see
  -- the note at the top of this file for why the autocmd above alone isn't
  -- enough for it).
  setup_buf(vim.api.nvim_get_current_buf())
end)
