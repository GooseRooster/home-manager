-- External formatters (conform.nvim) and linters (nvim-lint), wiring up the
-- tools 'pkgs/base.nix' provides. Both register in a `later()` that lands
-- after '40_plugins.lua's conform setup callback — conform's `setup()` merges
-- `formatters_by_ft`, so this only *adds* entries to the stock config.
--
-- Filetypes without an entry here fall through to `lsp_format = 'fallback'`
-- (set in '40_plugins.lua'): the attached LSP's own formatter is used when
-- it has one (e.g. ruff for python, roslyn for C#).
Config.later(function()
  vim.pack.add({ 'https://github.com/mfussenegger/nvim-lint' })

  -- Format on `<Leader>lf` (MiniMax's stock conform binding)
  require('conform').setup({
    formatters_by_ft = {
      lua = { 'stylua' },
      sh = { 'shfmt' },
      bash = { 'shfmt' },
    },
  })

  -- Lint on save and after leaving insert mode. shellcheck only (it speaks
  -- sh/bash, not zsh — for zsh the bashls-adjacent tooling would differ).
  local lint = require('lint')
  lint.linters_by_ft = {
    sh = { 'shellcheck' },
    bash = { 'shellcheck' },
  }

  local lint_buf = function()
    lint.try_lint()
  end
  Config.new_autocmd(
    { 'BufWritePost', 'InsertLeave' },
    nil,
    lint_buf,
    'Run nvim-lint on the buffer'
  )
  vim.defer_fn(lint_buf, 0) -- cover the buffer(s) already open at startup
end)
