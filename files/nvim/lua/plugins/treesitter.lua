-- Treesitter parsers, derived from the environment profile (see config/profile.lua).
--
-- Most parsers arrive via each enabled language's LazyVim extra (LazyVim declares
-- ensure_installed with opts_extend, so lists merge across core + extras + this
-- file). This spec only needs to add parsers that no extra provides — currently
-- the .NET ones (c_sharp/razor) under the dotnet feature — plus any baseline set.
--
-- NOTE: on nvim-treesitter's `main` branch, ensure_installed only *installs*
-- missing parsers; it never uninstalls. Disabling a feature stops its parsers
-- from installing on a fresh machine (lean containers), but won't remove parsers
-- already on disk here — use `:TSUninstall <lang>` to reclaim those by hand.
local profile = require("config.profile")

local ensure_installed = vim.list_extend({}, profile.baseline_treesitter)
for _, name in ipairs(profile.feature_order) do
  if profile.has(name) then
    vim.list_extend(ensure_installed, profile.features[name].treesitter or {})
  end
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = ensure_installed,
    },
  },
}
