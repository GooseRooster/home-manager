-- jsonls settings.
--
-- The server's built-in schemaStore support (HTTP-backed catalog) stays
-- enabled — no SchemaStore.nvim plugin needed.
return {
  settings = {
    json = {
      format = {
        enable = true,
      },
      validate = { enable = true },
    },
  },
}
