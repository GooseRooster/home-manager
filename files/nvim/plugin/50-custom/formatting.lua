-- External formatters (conform.nvim) and linters (nvim-lint), wiring up the
-- tools 'pkgs/base.nix' provides. Both register in a `later()` that lands
-- after '40_plugins.lua's conform setup callback — conform's `setup()` merges
-- `formatters_by_ft`, so this only *adds* entries to the stock config.
--
-- Filetypes without an entry here fall through to `lsp_format = 'fallback'`
-- (set in '40_plugins.lua'): the attached LSP's own formatter is used when
-- it has one (e.g. ruff for python, roslyn for C#).
--
-- `format_on_save = true` — vendor's own conform `setup()` (40_plugins.lua)
-- never set this, so format-on-save was never actually wired up anywhere;
-- only the manual `<Leader>lf` binding worked (`require('conform').format()`
-- always merges in `default_format_opts.lsp_format = 'fallback'` regardless
-- of `format_on_save`, since that merge happens inside `M.format()` itself —
-- see conform's `init.lua`). `format_on_save`, by contrast, only registers
-- its `BufWritePre` autocmd when truthy in the exact `setup()` call that
-- runs — and conform's `setup()` clears its own augroup on every call — so
-- it has to be set here, in the *last* `conform.setup()` call in the load
-- order, for it to actually take effect.
Config.later(function()
  vim.pack.add({ 'https://github.com/mfussenegger/nvim-lint' })

  -- Format on `<Leader>lf` (MiniMax's stock conform binding) AND on save.
  require('conform').setup({
    format_on_save = true,
    formatters_by_ft = {
      lua = { 'stylua' },
      sh = { 'shfmt' },
      bash = { 'shfmt' },
      nix = { 'nixfmt' },
    },
  })

  -- Lint on save and after leaving insert mode. shellcheck only (it speaks
  -- sh/bash, not zsh — for zsh the bashls-adjacent tooling would differ);
  -- statix for Nix (static-analysis lints, orthogonal to nixd's LSP range).
  local lint = require('lint')
  lint.linters_by_ft = {
    sh = { 'shellcheck' },
    bash = { 'shellcheck' },
    nix = { 'statix' },
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
