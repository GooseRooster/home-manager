-- Port of nvim-navic, as configured in the LazyVim setup's own
-- 'files/nvim/lua/plugins/lualine.lua' (not LazyVim's stock
-- `editor.navic` extra, which tunes it slightly differently and wires it
-- into lualine's own winbar section) — same opts, same `LspAttach` gate.
--
-- MiniMax has no lualine, so the winbar itself is set directly instead of
-- through a statusline plugin's `winbar` config. Re-applied on every
-- `LspAttach`/`BufWinEnter`/`WinEnter` (all per-window events) rather than
-- once globally, so windows without a navic-capable attached client (mini
-- pickers/starter/files, plain buffers with no LSP, ...) get an empty
-- winbar instead of a permanently-reserved blank line everywhere.
Config.later(function()
  vim.pack.add({ 'https://github.com/SmiteshP/nvim-navic' })

  require('nvim-navic').setup({
    highlight = true,
    depth_limit = 5,
    depth_limit_indicator = '…',
    separator = ' › ',
  })

  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('navic_attach', { clear = true }),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and client.server_capabilities.documentSymbolProvider then
        require('nvim-navic').attach(client, args.buf)
      end
    end,
  })

  local function update_winbar()
    local ok, navic = pcall(require, 'nvim-navic')
    vim.wo.winbar = (ok and navic.is_available(0))
        and "%{%v:lua.require('nvim-navic').get_location()%}"
      or ''
  end

  vim.api.nvim_create_autocmd(
    { 'LspAttach', 'BufWinEnter', 'WinEnter' },
    {
      group = vim.api.nvim_create_augroup('navic_winbar', { clear = true }),
      callback = update_winbar,
    }
  )
end)
