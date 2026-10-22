-- Structural 'mini.ai' textobjects on top of MiniMax's stock setup
-- ('vendor/nvim/plugin/30_mini.lua'):
--   - `aF`/`iF` - around/inside function *definition* (replaces vendor's)
--   - `aC`/`iC` - around/inside class (class/struct/record/interface/enum in
--                 C#, class in Python/Rust/TS, landmark elements in HTML)
--   - `at`/`it` - around/inside tag, via tree-sitter in HTML (incl. markup
--                 inside Razor), JSX/TSX and XML; falls back to mini.ai's
--                 builtin Lua-pattern tag everywhere else
-- All compose with mini.ai's usual extras: `an`/`il` (next/last),
-- `g[`/`g]` (jump to edges), counts (`2iF`), and repeating `aF`/`it` in
-- Visual mode to grow to the enclosing one. `f` (function *call*) is
-- untouched.
--
-- Why not just `MiniAi.gen_spec.treesitter()` (what vendor's `F` used):
--   1. It only *reads* the buffer's existing tree, it never parses. A buffer
--      without `vim.treesitter.start()` (feature not in NVIM_LANGS, or the
--      first file of `nvim foo.cs` before the 'lsp.lua' fix) has no tree, so
--      it silently found nothing. `parse_buf()` forces a full parse
--      (injections included) — incremental, so ~free when the highlighter
--      already parsed.
--   2. It searches only the language under cursor and stops at the first
--      language with *any* match. In Razor the combined html injection
--      claims the whole file, so inside `@code { }` it found html elements
--      (which upstream captures as `@function.outer`), none covering the
--      cursor, and never looked at the C# methods. `capture_regions()`
--      collects from every language tree and lets mini.ai's own "cover"
--      logic pick the smallest enclosing match.
--   3. Its `i` regions compete on their own, so `iF` with the cursor on a
--      method's *signature* (outside the body) picked the enclosing class's
--      inner instead. `resolve_inner()` picks the `a` textobject first and
--      returns *its* inner part — the way builtin `i(`/`it` behave.
--
-- Captures come from 'nvim-treesitter-textobjects' queries, plus this
-- config's own 'queries/<lang>/textobjects.scm' overlay: `@tag.outer` for
-- html/jsx/xml (upstream has no tag captures) and a razor query inheriting
-- c_sharp (upstream has none, so `F`/`C` work in `@code` blocks).
--
-- Must run after vendor's `later()`-deferred `MiniAi.setup()` — guaranteed
-- since `later()` callbacks fire in registration order and '50-custom/'
-- sorts after '30_mini.lua'. `MiniAi.config` is read live on every
-- textobject lookup, so mutating it here needs no re-setup, and mini.ai's
-- `a`/`i` mappings accept any id character, so no new mappings either.

-- Helpers ---------------------------------------------------------------------

-- Parse the current buffer (and its injected languages). Returns the
-- parser, or nil when the filetype has no tree-sitter parser.
local parse_buf = function(buf)
  local ok, parser = pcall(vim.treesitter.get_parser, buf, nil, { error = false })
  if not (ok and parser) then return nil end
  parser:parse(true)
  return parser
end

-- 0-based end-exclusive tree-sitter range -> 1-based end-inclusive mini.ai
-- region. Same conversion as `MiniAi.gen_spec.treesitter()`: "col 0 of next
-- row" means "up to and including the previous row's newline".
local to_region = function(sr, sc, er, ec)
  local to = { line = er + 1, col = ec }
  if ec == 0 then to = { line = er, col = vim.fn.col({ er, '$' }) } end
  return { from = { line = sr + 1, col = sc + 1 }, to = to }
end

local pos_lt = function(a, b) return a.line < b.line or (a.line == b.line and a.col < b.col) end
local pos_eq = function(a, b) return a.line == b.line and a.col == b.col end
local region_eq = function(a, b)
  if not (a and b and pos_eq(a.from, b.from)) then return false end
  if a.to == nil or b.to == nil then return a.to == b.to end
  return pos_eq(a.to, b.to)
end
-- Is `inner` within `outer`? Empty regions use `from` as their end.
local region_within = function(inner, outer)
  local inner_to, outer_to = inner.to or inner.from, outer.to or outer.from
  return not pos_lt(inner.from, outer.from) and not pos_lt(outer_to, inner_to)
end

local warn_no_parser = function()
  vim.notify(('(mini.ai) No tree-sitter parser for filetype "%s"'):format(vim.bo.filetype), vim.log.levels.WARN)
end

-- Regions of the given capture (e.g. 'function.outer') across *every*
-- language tree in the buffer. Quantified captures (`_+ @x`) span from
-- their first to last node, like mini.ai's builtin tree-sitter spec.
local capture_regions = function(buf, parser, capture)
  local res = {}
  parser:for_each_tree(function(tree, ltree)
    local ok, query = pcall(vim.treesitter.query.get, ltree:lang(), 'textobjects')
    if not (ok and query) then return end
    for _, match, metadata in query:iter_matches(tree:root(), buf, nil, nil, { all = true }) do
      for capture_id, nodes in pairs(match) do
        if query.captures[capture_id] == capture then
          local left, right
          for _, node in ipairs(nodes) do
            local r = vim.treesitter.get_range(node, buf, metadata[capture_id])
            if left == nil or r[3] < left[3] then left = r end
            if right == nil or r[6] > right[6] then right = r end
          end
          table.insert(res, to_region(left[1], left[2], right[4], right[5]))
        end
      end
    end
  end)
  return res
end

-- `i` textobject resolved *through* the `a` one: find the `a` region the
-- user means (honouring search method, count and Visual reference region
-- via mini.ai itself), then return that region's inner part. If that has no
-- inner part (`<br/>`, abstract method) or it equals the current Visual
-- selection (repeated `it`/`iF` to expand), step out to the next `a` region.
-- Returning a single region makes mini.ai use it as-is; `{}` makes it report
-- "No textobject found" under the `i` id the user actually typed.
-- The inner `a` lookup runs silenced (buffer-local `silent`), so a miss
-- reports only the `i` id the user typed, not an extra "No textobject aX".
local find_outer = function(id, opts)
  local prev = vim.b.miniai_config
  vim.b.miniai_config = vim.tbl_deep_extend('force', prev or {}, { silent = true })
  local ok, res = pcall(MiniAi.find_textobject, 'a', id, opts)
  vim.b.miniai_config = prev
  if not ok then error(res, 0) end
  return res
end

local resolve_inner = function(id, opts, inner_of)
  local o = vim.deepcopy(opts)
  for _ = 1, 1000 do
    local outer = find_outer(id, o)
    if outer == nil then return {} end
    local inner = inner_of(outer)
    if inner ~= nil and not region_eq(inner, opts.reference_region) then return inner end
    o.reference_region, o.n_times = outer, 1
  end
  return {}
end

-- Function/class textobjects --------------------------------------------------

local treesitter = function(kind)
  return function(ai_type, id, opts)
    local buf = vim.api.nvim_get_current_buf()
    local parser = parse_buf(buf)
    if parser == nil then return warn_no_parser() end

    local outers = capture_regions(buf, parser, kind .. '.outer')
    if ai_type == 'a' then return outers end

    -- An outer's own inner is the inner capture inside it that isn't inside
    -- some smaller (nested) outer — e.g. a method's body rather than the
    -- body of a lambda declared in it.
    local inners = capture_regions(buf, parser, kind .. '.inner')
    return resolve_inner(id, opts, function(outer)
      local nested = vim.tbl_filter(
        function(r) return region_within(r, outer) and not region_eq(r, outer) end,
        outers
      )
      for _, inner in ipairs(inners) do
        if region_within(inner, outer) then
          local in_nested = false
          for _, n in ipairs(nested) do
            in_nested = in_nested or region_within(inner, n)
          end
          if not in_nested then return inner end
        end
      end
    end)
  end
end

-- Tag textobject --------------------------------------------------------------
--
-- Only `@tag.outer` is captured by the queries; the inner part is derived
-- from the element node's first/last named children instead of a second
-- capture, because a query can't capture the *empty* gap in `<div></div>`.
-- Only elements with both an opening and a closing tag have one —
-- self-closing (`<br/>`, `<Foo />`) and implicitly closed HTML elements
-- (`<li>a<li>b`) only have `at`.
--
-- The inner part skips leading/trailing whitespace (like `iF`'s statements),
-- so on a multi-line element `cit` keeps the surrounding lines/indent and
-- `yit` yields just the content. Whitespace-only/empty content becomes an
-- empty region right after the opening tag, so `cit` there just inserts.
local open_tag_types = { start_tag = true, STag = true, jsx_opening_element = true }
local close_tag_types = { end_tag = true, ETag = true, jsx_closing_element = true }

local tag_inner = function(buf, node)
  local n = node:named_child_count()
  if n < 2 then return nil end
  local open, close = node:named_child(0), node:named_child(n - 1)
  if not (open_tag_types[open:type()] and close_tag_types[close:type()]) then return nil end
  local _, _, sr, sc = open:range()
  local er, ec = close:range()

  local lines = vim.api.nvim_buf_get_text(buf, sr, sc, er, ec, {})
  local from, to
  for i, l in ipairs(lines) do
    local c = l:find('%S')
    if c then
      from = { line = sr + i, col = (i == 1 and sc or 0) + c }
      break
    end
  end
  if from == nil then return { from = { line = sr + 1, col = sc + 1 } } end
  for i = #lines, 1, -1 do
    local c = lines[i]:find('%S%s*$')
    if c then
      to = { line = sr + i, col = (i == 1 and sc or 0) + c }
      break
    end
  end
  return { from = from, to = to }
end

-- mini.ai's builtin `t` spec (`H.builtin_textobjects.t` in 'lua/mini/ai.lua',
-- not exported). Used when the buffer has no parser or no tag captures, e.g.
-- tags in markdown, plain text or a Lua string.
local tag_pattern = { '<(%w-)%f[^<%w][^<>]->.-</%1%s->', '^<.->().*()</.->$' }

local tag = function(ai_type, id, opts)
  local buf = vim.api.nvim_get_current_buf()
  local parser = parse_buf(buf)
  if parser == nil then return tag_pattern end

  -- Every language tree, not just the one under cursor: HTML in Razor (and
  -- in markdown blocks) lives in an injected child tree.
  local outers, inners = {}, {}
  parser:for_each_tree(function(tree, ltree)
    local ok, query = pcall(vim.treesitter.query.get, ltree:lang(), 'textobjects')
    if not (ok and query) then return end
    for capture_id, node in query:iter_captures(tree:root(), buf) do
      if query.captures[capture_id] == 'tag.outer' then
        table.insert(outers, to_region(node:range()))
        inners[#outers] = tag_inner(buf, node)
      end
    end
  end)

  if #outers == 0 then return tag_pattern end
  if ai_type == 'a' then return outers end
  return resolve_inner(id, opts, function(outer)
    for i, r in ipairs(outers) do
      if region_eq(r, outer) then return inners[i] end
    end
  end)
end

Config.later(function()
  local custom = MiniAi.config.custom_textobjects
  custom.F = treesitter('function')
  custom.C = treesitter('class')
  custom.t = tag
end)
