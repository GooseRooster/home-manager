-- Environment-driven feature profile — trimmed MiniMax port of the LazyVim
-- setup's 'files/nvim/lua/config/profile.lua' (see the home-manager README
-- roadmap's Phase 5 entry for the full plan).
--
-- Unlike the LazyVim side, nothing here installs anything: every MiniMax
-- plugin is installed unconditionally via 'vim.pack.add()' in whichever
-- 'plugin/50-custom/*.lua' file needs it. This module only decides which
-- language-specific *config* inside those files actually activates (dap
-- keymaps, easy-dotnet/lazydotnet today; LSP servers once Phase 5 lands).
--
-- Mason is not used anywhere in this config (a deliberate choice, not an
-- oversight — see the roadmap), so there is no NixOS-prebuilt-binary problem
-- to route around here, unlike the LazyVim side's `nix_substitutes`/
-- `tool_source()`. Language tools are expected to come from the environment
-- (pkgs/base.nix / project devshells) — same tools, just no indirection.
--
-- Control (same env vars as the LazyVim side, so a project's existing
-- `.dev.local.sh` NVIM_LANGS export works unchanged for both configs):
--   NVIM_PROFILE = "full" | "minimal"   coarse override (optional)
--   NVIM_LANGS   = "rust,python,..."    comma list of extra langs (minimal only)

local M = {}

local function env(name)
  local v = vim.env[name]
  if v == nil or v == '' then return nil end
  return v
end

-- Keep in sync with the LazyVim side's `feature_order` (files/nvim/lua/
-- config/profile.lua) as languages gain actual wiring here. Only `dotnet`
-- has any consumer so far (Phase 2's easy-dotnet.lua/lazydotnet.lua/
-- luasnip.lua); the rest are listed now so `NVIM_LANGS`/`full` resolve
-- identically across both configs even before Phase 5 gives them meaning.
M.feature_order = {
  'python',
  'rust',
  'typescript',
  'java',
  'clang',
  'cmake',
  'docker',
  'sql',
  'json',
  'yaml',
  'nushell',
  'git',
  'dotnet',
}

-- Universal languages enabled even in the minimal profile. Mirrors the
-- LazyVim side; kept even though nothing consumes most of these yet.
M.minimal_langs = { 'python', 'git', 'json', 'yaml', 'docker', 'nushell' }

local function resolve_profile()
  local p = env('NVIM_PROFILE')
  if p == 'full' or p == 'minimal' then return p end
  return 'minimal'
end

local function resolve_langs()
  local set = {}
  if resolve_profile() == 'full' then
    for _, name in ipairs(M.feature_order) do
      set[name] = true
    end
    return set
  end
  for _, name in ipairs(M.minimal_langs) do
    set[name] = true
  end
  local list = env('NVIM_LANGS')
  if list then
    for token in list:gmatch('[^,%s]+') do
      if vim.tbl_contains(M.feature_order, token) then set[token] = true end
    end
  end
  return set
end

M.profile = resolve_profile()
M.langs = resolve_langs()

--- Is a given feature enabled in this environment?
function M.has(feature) return M.langs[feature] == true end

--- Any language enabled at all? Used to gate the generic dap.lua wiring.
function M.any_lang() return next(M.langs) ~= nil end

return M
