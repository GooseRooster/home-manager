return {
  "L3MON4D3/LuaSnip",
  config = function(_, opts)
    -- Run LazyVim's default LuaSnip config first so you don't break anything
    -- the extra already sets up (e.g. friendly-snippets loader)
    require("luasnip").setup(opts)
    require("luasnip.loaders.from_vscode").lazy_load()

    local ls = require("luasnip")
    local s = ls.snippet
    local t = ls.text_node
    local i = ls.insert_node
    local d = ls.dynamic_node
    local sn = ls.snippet_node

    ls.config.set_config({
      enable_autosnippets = true,
    })

    -- The rest of this file is the C# XML-doc autosnippet; only wire it up when
    -- the dotnet feature is enabled for this environment (see config/profile.lua).
    if not require("config.profile").has("dotnet") then
      return
    end

    ls.filetype_extend("razor", { "cs" })

    -- Helper: get the line below the cursor
    local function get_next_line()
      local row = vim.api.nvim_win_get_cursor(0)[1] -- 1-indexed
      local lines = vim.api.nvim_buf_get_lines(0, row, row + 1, false)
      return lines[1] or ""
    end

    -- Helper: parse method signature into a table of param names
    -- Handles: int foo, string bar, CancellationToken ct
    -- Handles: generic types like List<string> items, Dictionary<int,string> map
    -- Returns: { has_return, return_type, params[] }
    local function parse_signature(line)
      local result = { has_return = false, return_type = nil, params = {} }

      -- Strip leading whitespace and common keywords
      line = line:match("^%s*(.+)$") or line
      line = line:gsub(
        "^%s*(public%s+|private%s+|protected%s+|internal%s+|static%s+|async%s+|override%s+|virtual%s+|abstract%s+)*",
        ""
      )
      line = line:gsub("public%s+", "")
      line = line:gsub("private%s+", "")
      line = line:gsub("protected%s+", "")
      line = line:gsub("internal%s+", "")
      line = line:gsub("static%s+", "")
      line = line:gsub("async%s+", "")
      line = line:gsub("override%s+", "")
      line = line:gsub("virtual%s+", "")
      line = line:gsub("abstract%s+", "")
      line = line:gsub("sealed%s+", "")
      line = line:gsub("readonly%s+", "")

      -- Match: ReturnType MethodName(...) or ReturnType MethodName<T>(...)
      -- We need to grab the param string between the outermost parens
      local paren_start = line:find("%(")
      if not paren_start then
        return result
      end

      -- Extract return type + method name (everything before the first paren)
      local before_paren = line:sub(1, paren_start - 1):match("^(.-)%s*$")

      -- Return type is everything before the last word (method name)
      local return_type = before_paren:match("^(.+)%s+%S+$")
      if return_type then
        result.has_return = return_type ~= "void" and not return_type:match("^Task$")
        result.return_type = return_type
      end

      -- Extract content between outermost parens, handling nested generics
      local depth = 0
      local param_str = ""
      for idx = paren_start, #line do
        local ch = line:sub(idx, idx)
        if ch == "(" then
          depth = depth + 1
          if depth > 1 then
            param_str = param_str .. ch
          end
        elseif ch == ")" then
          depth = depth - 1
          if depth == 0 then
            break
          end
          param_str = param_str .. ch
        else
          if depth >= 1 then
            param_str = param_str .. ch
          end
        end
      end

      if param_str:match("^%s*$") then
        return result
      end

      -- Split params by comma, but not commas inside < >
      local params = {}
      local current = ""
      local angle_depth = 0
      for idx = 1, #param_str do
        local ch = param_str:sub(idx, idx)
        if ch == "<" then
          angle_depth = angle_depth + 1
          current = current .. ch
        elseif ch == ">" then
          angle_depth = angle_depth - 1
          current = current .. ch
        elseif ch == "," and angle_depth == 0 then
          table.insert(params, current:match("^%s*(.-)%s*$"))
          current = ""
        else
          current = current .. ch
        end
      end
      if current:match("%S") then
        table.insert(params, current:match("^%s*(.-)%s*$"))
      end

      -- Extract the last word (param name) from each param entry
      for _, param in ipairs(params) do
        -- Handle default values: int foo = 0  →  strip = 0
        param = param:gsub("%s*=.*$", "")
        -- Handle out/ref/in/params keywords
        param = param:gsub("^%s*out%s+", "")
        param = param:gsub("^%s*ref%s+", "")
        param = param:gsub("^%s*in%s+", "")
        param = param:gsub("^%s*params%s+", "")
        -- The param name is the last whitespace-delimited token
        local name = param:match("(%S+)%s*$")
        if name and name ~= "" then
          table.insert(result.params, name)
        end
      end

      return result
    end

    -- Build the dynamic xmldoc node
    local function xmldoc_nodes(_, _)
      local line = get_next_line()
      local sig = parse_signature(line)

      local nodes = {}

      -- <summary> block
      table.insert(nodes, t({ "/// <summary>", "/// " }))
      table.insert(nodes, i(1, "TODO"))
      table.insert(nodes, t({ "", "/// </summary>" }))

      -- <param> tags — each gets its own insert node
      local insert_idx = 2
      for _, param_name in ipairs(sig.params) do
        table.insert(nodes, t({ "", '/// <param name="' .. param_name .. '">' }))
        table.insert(nodes, i(insert_idx, "TODO"))
        table.insert(nodes, t("</param>"))
        insert_idx = insert_idx + 1
      end

      -- <returns> tag if non-void and non-bare-Task
      if sig.has_return then
        table.insert(nodes, t({ "", "/// <returns>" }))
        table.insert(nodes, i(insert_idx, "TODO"))
        table.insert(nodes, t("</returns>"))
      end

      return sn(nil, nodes)
    end

    local xmldoc_snippet = s({ trig = "///", snippetType = "autosnippet" }, { d(1, xmldoc_nodes) })

    ls.add_snippets("cs", { xmldoc_snippet }, { key = "cs_xmldoc" })
  end,
}
