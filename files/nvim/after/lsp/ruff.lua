-- Ruff runs alongside pyright; Ruff's own hover capability is disabled here
-- so hover requests are answered by pyright only.
return {
  cmd_env = { RUFF_TRACE = 'messages' },
  init_options = {
    settings = {
      logLevel = 'error',
    },
  },
  on_attach = function(client, _buf_id)
    client.server_capabilities.hoverProvider = false
  end,
}
