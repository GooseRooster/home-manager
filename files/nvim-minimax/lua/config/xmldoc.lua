-- C# XML-doc snippet: typing `///` on the line above a method signature and
-- pressing `<C-j>` (mini.snippets' insert-mode expand mapping) builds the
-- `/// <summary>` / `/// <param name="...">` / `/// <returns>` doc comment
-- from the signature below, with a tabstop per description to fill.
--
-- Implemented as a mini.snippets *function snippet*: the file element is a
-- function called at expansion time with the context ({ buf_id, lang }),
-- returning the snippet data (`{ prefix, body }`) — so the body can depend
-- on the buffer content around the cursor. Body is LSP-style snippet syntax
-- (`${N:default}` tabstops) that `default_insert` expands into a jump
-- session.
--
-- The signature parser is deliberately regex-based (not treesitter): it only
-- needs the next line's method shape and works regardless of parser
-- availability.
local M = {}

--- Read the line immediately below the cursor
local function get_next_line()
  local row = vim.api.nvim_win_get_cursor(0)[1] -- 1-indexed
  local lines = vim.api.nvim_buf_get_lines(0, row, row + 1, false)
  return lines[1] or ''
end

--- Parse a C# method signature into its return type and parameter names.
--- Handles access/static/async modifier chains, generic types
--- (`List<string>`, `Dictionary<int, string>`), default values and
--- out/ref/in/params keywords. Returns { has_return, params }.
local function parse_signature(line)
  local result = { has_return = false, params = {} }

  line = line:match('^%s*(.+)$') or line
  line = line:gsub('public%s+', '')
  line = line:gsub('private%s+', '')
  line = line:gsub('protected%s+', '')
  line = line:gsub('internal%s+', '')
  line = line:gsub('static%s+', '')
  line = line:gsub('async%s+', '')
  line = line:gsub('override%s+', '')
  line = line:gsub('virtual%s+', '')
  line = line:gsub('abstract%s+', '')
  line = line:gsub('sealed%s+', '')
  line = line:gsub('readonly%s+', '')

  local paren_start = line:find('%(')
  if not paren_start then return result end

  -- Return type = everything before the last word (the method name)
  local before_paren = line:sub(1, paren_start - 1):match('^(.-)%s*$')
  local return_type = before_paren:match('^(.+)%s+%S+$')
  if return_type then
    result.has_return = return_type ~= 'void' and not return_type:match('^Task$')
  end

  -- Extract the parameter list between the outermost parens (so nested
  -- generics like `Dictionary<int, string>` survive intact)
  local depth, param_str = 0, ''
  for idx = paren_start, #line do
    local ch = line:sub(idx, idx)
    if ch == '(' then
      depth = depth + 1
      if depth > 1 then param_str = param_str .. ch end
    elseif ch == ')' then
      depth = depth - 1
      if depth == 0 then break end
      param_str = param_str .. ch
    elseif depth >= 1 then
      param_str = param_str .. ch
    end
  end
  if param_str:match('^%s*$') then return result end

  -- Split parameters on top-level commas (commas inside <> stay put)
  local params = {}
  local current, angle_depth = '', 0
  for idx = 1, #param_str do
    local ch = param_str:sub(idx, idx)
    if ch == '<' then
      angle_depth = angle_depth + 1
      current = current .. ch
    elseif ch == '>' then
      angle_depth = angle_depth - 1
      current = current .. ch
    elseif ch == ',' and angle_depth == 0 then
      table.insert(params, current:match('^%s*(.-)%s*$'))
      current = ''
    else
      current = current .. ch
    end
  end
  if current:match('%S') then
    table.insert(params, current:match('^%s*(.-)%s*$'))
  end

  -- The parameter name is the last token of each entry
  for _, param in ipairs(params) do
    param = param:gsub('%s*=.*$', '') -- default values: `int foo = 0`
    param = param:gsub('^%s*out%s+', '')
    param = param:gsub('^%s*ref%s+', '')
    param = param:gsub('^%s*in%s+', '')
    param = param:gsub('^%s*params%s+', '')
    local name = param:match('(%S+)%s*$')
    if name and name ~= '' then table.insert(result.params, name) end
  end

  return result
end

--- Called by mini.snippets at expansion time. Returns the snippet data, or
--- nil when this environment has no dotnet feature (the loader only invokes
--- this for cs/c_sharp/razor contexts anyway — see snippets/*.lua).
M.snippets = function(_context)
  if not require('config.profile').has('dotnet') then return nil end

  local sig = parse_signature(get_next_line())

  local body_parts = {
    '/// <summary>',
    '/// ${1:TODO}',
    '/// </summary>',
  }

  local tabstop = 2
  for _, param_name in ipairs(sig.params) do
    table.insert(
      body_parts,
      ('/// <param name="%s">${%d:TODO}</param>'):format(param_name, tabstop)
    )
    tabstop = tabstop + 1
  end

  if sig.has_return then
    table.insert(body_parts, ('/// <returns>${%d:TODO}</returns>'):format(tabstop))
  end

  return { { prefix = '///', body = table.concat(body_parts, '\n') } }
end

return M
