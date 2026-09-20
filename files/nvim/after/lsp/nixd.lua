-- nixd settings.
--
-- The Nix language server (nix-community/nixd). lspconfig already sets
-- `filetypes = { 'nix' }` and `root_markers = { 'flake.nix', '.git' }`, so
-- flake projects (including this home-manager repo) auto-detect the project
-- root and nixd resolves the flake's inputs for evaluation-based features.
return {
  settings = {
    nixd = {
      -- Formatting is delegated to nixfmt (the RFC-style standard); nixd
      -- has no formatter of its own. The binary comes from 'pkgs/base.nix'.
      formatting = {
        command = { "nixfmt" },
      },
      options = {
        -- Home-manager option docs for completion/hover. The expr targets
        -- this repo's flake (`homeConfigurations`, standalone HM targets —
        -- see flake.nix); `container` is the leanest one, but every target
        -- here evaluates the same `home.nix`/`modules` tree so the option
        -- set is equivalent. A flake opened as another project root with
        -- different outputs simply fails this lookup — nixd then serves
        -- option completion from its generic fallback, never erroring into
        -- the buffer.
        home_manager = {
          expr = '(builtins.getFlake ("git+file://" + toString ./.)).homeConfigurations.container.options',
        },
      },
    },
  },
}
