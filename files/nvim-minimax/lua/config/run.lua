-- Stack-agnostic "Run"/"Unit test" keymap groups.
--
-- `<Leader>r` and `<Leader>u` are meant to mean the same thing regardless of
-- which language/toolchain a given buffer belongs to — only easy-dotnet
-- ('plugin/50-custom/easy-dotnet.lua') implements them today, but a future
-- per-stack integration (rust.lua, python.lua, ...) should bind its own
-- buffer-local actions under these same two letters via `M.register_clues`,
-- rather than inventing its own group labels/icons. mini.clue's clue window
-- shows whatever group description is registered for the *buffer at hand*
-- (buffer-local, via 'lua/config/clue.lua'), so two different filetypes can
-- both use `<Leader>r` and each only ever see their own stack's group —
-- there's no runtime collision to design around, just a naming/shape
-- convention worth keeping consistent as more stacks get added.
--
-- Suggested (not enforced) letter convention, so muscle memory transfers
-- across stacks — skip whatever doesn't apply:
--
--   <Leader>r  +Run                <Leader>u  +Unit test
--     rr  run                        ur  run test under cursor
--     rd  debug                      uR  run all tests in file
--     rb  build                      ud  debug test under cursor
--     rs  extra (e.g. secrets)       ue  build/compile errors
--     rT  toggle output console      up  peek failure/stack trace
--
-- Icons for both groups live in 'lua/config/clue.lua's single shared icon
-- table (keyed by the same `<Leader>r`/`<Leader>u` strings — the same table
-- global groups use too), applied automatically by `M.register_clues` below
-- since it goes through
-- `config.clue.add_buf`.
local M = {}

M.clues = {
  { mode = 'n', keys = '<Leader>r', desc = '+Run' },
  { mode = 'n', keys = '<Leader>u', desc = '+Unit test' },
}

--- Register a buffer as participating in the shared Run/Unit-test clue
--- groups. Call once per buffer from a stack integration's own FileType
--- setup, alongside whatever buffer-local `<Leader>r*`/`<Leader>u*`
--- keymaps.set calls that stack actually implements.
---@param bufnr integer
function M.register_clues(bufnr) require('config.clue').add_buf(bufnr, M.clues) end

return M
