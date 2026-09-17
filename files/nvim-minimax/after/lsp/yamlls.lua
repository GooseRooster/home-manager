-- yamlls settings.
--
-- `capabilities.foldingRange` is required for yamlls to understand line
-- folding. The server's built-in schemaStore support (HTTP-backed catalog)
-- stays enabled — no SchemaStore.nvim plugin needed.
return {
  capabilities = {
    textDocument = {
      foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      },
    },
  },
  settings = {
    redhat = { telemetry = { enabled = false } },
    yaml = {
      keyOrdering = false,
      format = {
        enable = true,
      },
      validate = true,
    },
  },
}
