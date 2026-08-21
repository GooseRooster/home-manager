return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim" },
    opts = {
      pipe_table = {
        enabled = false,
      },
    },
  },
  {
    "ice345/markdown-table-wrap.nvim",
    ft = { "markdown", "quarto", "rmd" },
    opts = {},
  },
  {
    "yousefhadder/markdown-plus.nvim",
    ft = "markdown",
    opts = {
      keymaps = { enabled = false }, -- kill default <localleader> tree
      table = { keymaps = { enabled = false } },
      links = { smart_paste = { enabled = true } }, -- opt-in, needs `curl`
    },
    config = function(_, opts)
      require("markdown-plus").setup(opts)

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function(args)
          local bufnr = args.buf
          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
          end

          -- Formatting (leaf actions, top level)
          map({ "n", "x" }, "<leader>Mb", "<Plug>(MarkdownPlusBold)", "Bold")
          map({ "n", "x" }, "<leader>Mi", "<Plug>(MarkdownPlusItalic)", "Italic")
          map({ "n", "x" }, "<leader>Ms", "<Plug>(MarkdownPlusStrikethrough)", "Strikethrough")
          map({ "n", "x" }, "<leader>M`", "<Plug>(MarkdownPlusCode)", "Inline code")
          map({ "n", "x" }, "<leader>Mu", "<Plug>(MarkdownPlusUnderline)", "Underline")
          map({ "n", "x" }, "<leader>M=", "<Plug>(MarkdownPlusHighlight)", "Highlight")
          map("x", "<leader>Me", "<Plug>(MarkdownPlusEscapeSelection)", "Escape/unescape punctuation")
          map({ "n", "x" }, "<leader>MF", "<Plug>(MarkdownPlusClearFormatting)", "Clear formatting")

          -- Headers / TOC
          map("n", "<leader>Mh+", "<Plug>(MarkdownPlusPromoteHeader)", "Promote header")
          map("n", "<leader>Mh-", "<Plug>(MarkdownPlusDemoteHeader)", "Demote header")
          for i = 1, 6 do
            map("n", "<leader>Mh" .. i, "<Plug>(MarkdownPlusHeader" .. i .. ")", "Set H" .. i)
          end
          map("n", "<leader>Mhs", "<Plug>(MarkdownPlusToggleAtxSetext)", "Toggle ATX/setext")
          map("n", "<leader>Mht", "<Plug>(MarkdownPlusGenerateTOC)", "Generate TOC")
          map("n", "<leader>Mhu", "<Plug>(MarkdownPlusUpdateTOC)", "Update TOC")
          map("n", "<leader>Mho", "<Plug>(MarkdownPlusOpenTocWindow)", "Open TOC window")

          -- Thematic breaks
          map("n", "<leader>Mrr", "<Plug>(MarkdownPlusInsertThematicBreak)", "Insert break")
          map("n", "<leader>Mrc", "<Plug>(MarkdownPlusCycleThematicBreak)", "Cycle break style")

          -- Links (insert vs selection-to-link are separate <Plug> names)
          map("n", "<leader>Mll", "<Plug>(MarkdownPlusInsertLink)", "Insert link")
          map("x", "<leader>Mll", "<Plug>(MarkdownPlusSelectionToLink)", "Selection to link")
          map("n", "<leader>Mle", "<Plug>(MarkdownPlusEditLink)", "Edit link")
          map("n", "<leader>Mla", "<Plug>(MarkdownPlusAutoLinkURL)", "Auto-link bare URL")
          map("n", "<leader>Mlr", "<Plug>(MarkdownPlusConvertToReference)", "Convert to reference")
          map("n", "<leader>Mli", "<Plug>(MarkdownPlusConvertToInline)", "Convert to inline")
          map("n", "<leader>Mlp", "<Plug>(MarkdownPlusSmartPaste)", "Smart paste URL")

          -- Images (same insert-vs-selection split as links)
          map("n", "<leader>MIi", "<Plug>(MarkdownPlusInsertImage)", "Insert image")
          map("x", "<leader>MIi", "<Plug>(MarkdownPlusSelectionToImage)", "Selection to image")
          map("n", "<leader>MIe", "<Plug>(MarkdownPlusEditImage)", "Edit image")
          map("n", "<leader>MIt", "<Plug>(MarkdownPlusToggleImageLink)", "Toggle link/image")

          -- Quotes & callouts
          map({ "n", "x" }, "<leader>Mqq", "<Plug>(MarkdownPlusToggleQuote)", "Toggle blockquote")
          map({ "n", "x" }, "<leader>Mqi", "<Plug>(MarkdownPlusInsertCallout)", "Insert/wrap callout")
          map("n", "<leader>Mqt", "<Plug>(MarkdownPlusToggleCalloutType)", "Cycle callout type")
          map("n", "<leader>Mqc", "<Plug>(MarkdownPlusConvertToCallout)", "Blockquote -> callout")
          map("n", "<leader>Mqb", "<Plug>(MarkdownPlusConvertToBlockquote)", "Callout -> blockquote")

          -- Code blocks (]b / [b kept as raw motions, mirroring ]] / [[ for headers)
          map({ "n", "x" }, "<leader>Mcc", "<Plug>(MarkdownPlusCodeBlockInsert)", "Insert/wrap code block")
          map("n", "<leader>Mcl", "<Plug>(MarkdownPlusCodeBlockChangeLanguage)", "Change language")
          map("n", "<leader>Mcf", "<Plug>(MarkdownPlusCodeBlockToggleFence)", "Toggle fence style")
          map("n", "]b", "<Plug>(MarkdownPlusCodeBlockNext)", "Next code block")
          map("n", "[b", "<Plug>(MarkdownPlusCodeBlockPrev)", "Previous code block")

          -- List management
          map({ "n", "x" }, "<leader>MLx", "<Plug>(MarkdownPlusToggleCheckbox)", "Toggle checkbox")
          map("i", "<C-t>", "<Plug>(MarkdownPlusToggleCheckbox)", "Toggle checkbox")
          map("n", "<leader>MLr", "<Plug>(MarkdownPlusRenumberLists)", "Renumber lists")
          map("n", "<leader>MLo", "<Plug>(MarkdownPlusNewListItemBelow)", "New item below")
          map("n", "<leader>MLO", "<Plug>(MarkdownPlusNewListItemAbove)", "New item above")

          local list_types = {
            u = "MarkdownPlusToggleListUnordered",
            t = "MarkdownPlusToggleListTask",
            n = "MarkdownPlusToggleListOrdered",
            N = "MarkdownPlusToggleListOrderedParen",
            l = "MarkdownPlusToggleListLetterLower",
            L = "MarkdownPlusToggleListLetterUpper",
            p = "MarkdownPlusToggleListLetterLowerParen",
            P = "MarkdownPlusToggleListLetterUpperParen",
            c = "MarkdownPlusToggleListClear",
          }
          for key, plug in pairs(list_types) do
            map({ "n", "x" }, "<leader>MLt" .. key, "<Plug>(" .. plug .. ")", "List: " .. key)
          end

          -- Table (mirrors upstream's own `t` scheme, just moved under <leader>Mt)
          map("n", "<leader>Mtc", "<Plug>(MarkdownPlusTableCreate)", "Create table")
          map("n", "<leader>Mtf", "<Plug>(MarkdownPlusTableFormat)", "Format table")
          map("n", "<leader>Mtn", "<Plug>(MarkdownPlusTableNormalize)", "Normalize table")
          map("n", "<leader>Mtir", "<Plug>(MarkdownPlusTableInsertRowBelow)", "Insert row below")
          map("n", "<leader>MtiR", "<Plug>(MarkdownPlusTableInsertRowAbove)", "Insert row above")
          map("n", "<leader>Mtic", "<Plug>(MarkdownPlusTableInsertColumnRight)", "Insert column right")
          map("n", "<leader>MtiC", "<Plug>(MarkdownPlusTableInsertColumnLeft)", "Insert column left")
          map("n", "<leader>Mtdr", "<Plug>(MarkdownPlusTableDeleteRow)", "Delete row")
          map("n", "<leader>Mtdc", "<Plug>(MarkdownPlusTableDeleteColumn)", "Delete column")
          map("n", "<leader>Mtyr", "<Plug>(MarkdownPlusTableDuplicateRow)", "Duplicate row")
          map("n", "<leader>Mtyc", "<Plug>(MarkdownPlusTableDuplicateColumn)", "Duplicate column")
          -- Note: move-row/column has <Plug> targets but no documented default key upstream; I picked these
          map("n", "<leader>Mtmj", "<Plug>(MarkdownPlusTableMoveRowDown)", "Move row down")
          map("n", "<leader>Mtmk", "<Plug>(MarkdownPlusTableMoveRowUp)", "Move row up")
          map("n", "<leader>Mtmh", "<Plug>(MarkdownPlusTableMoveColumnLeft)", "Move column left")
          map("n", "<leader>Mtml", "<Plug>(MarkdownPlusTableMoveColumnRight)", "Move column right")
          map("n", "<leader>Mta", "<Plug>(MarkdownPlusTableToggleCellAlignment)", "Toggle cell alignment")
          map("n", "<leader>Mtx", "<Plug>(MarkdownPlusTableClearCell)", "Clear cell")
          map("n", "<leader>Mtb", "<Plug>(MarkdownPlusTableInsertBreak)", "Insert <br> in cell")
          map("n", "<leader>Mtw", "<Plug>(MarkdownPlusTableWrapCell)", "Wrap cell")
          map("n", "<leader>MtW", "<Plug>(MarkdownPlusTableUnwrapCell)", "Unwrap cell (strip <br>)")
          map("n", "<leader>Mte", "<Plug>(MarkdownPlusTableEditCell)", "Edit cell (popup)")
          map("n", "<leader>MtT", "<Plug>(MarkdownPlusTableTranspose)", "Transpose table")
          map("n", "<leader>Mtsa", "<Plug>(MarkdownPlusTableSortAscending)", "Sort ascending")
          map("n", "<leader>Mtsd", "<Plug>(MarkdownPlusTableSortDescending)", "Sort descending")
          map("n", "<leader>Mtvx", "<Plug>(MarkdownPlusTableToCSV)", "Table -> CSV")
          map("n", "<leader>Mtvi", "<Plug>(MarkdownPlusTableFromCSV)", "CSV -> table")
          -- insert-mode cell nav kept raw (Alt+hjkl), same rationale as ]b/[b
          map("i", "<A-h>", "<Plug>(MarkdownPlusTableNavLeft)", "Cell left")
          map("i", "<A-l>", "<Plug>(MarkdownPlusTableNavRight)", "Cell right")
          map("i", "<A-j>", "<Plug>(MarkdownPlusTableNavDown)", "Cell down")
          map("i", "<A-k>", "<Plug>(MarkdownPlusTableNavUp)", "Cell up")

          -- Footnotes ("notes")
          map("n", "<leader>Mni", "<Plug>(MarkdownPlusFootnoteInsert)", "Insert footnote")
          map("n", "<leader>Mne", "<Plug>(MarkdownPlusFootnoteEdit)", "Edit footnote")
          map("n", "<leader>Mnd", "<Plug>(MarkdownPlusFootnoteDelete)", "Delete footnote")
          map("n", "<leader>Mng", "<Plug>(MarkdownPlusFootnoteGotoDefinition)", "Go to definition")
          map("n", "<leader>Mnr", "<Plug>(MarkdownPlusFootnoteGotoReference)", "Go to reference(s)")
          map("n", "<leader>Mnn", "<Plug>(MarkdownPlusFootnoteNext)", "Next footnote")
          map("n", "<leader>Mnp", "<Plug>(MarkdownPlusFootnotePrev)", "Previous footnote")
          map("n", "<leader>Mnl", "<Plug>(MarkdownPlusFootnoteList)", "List footnotes")

          -- Buffer-scoped which-key group labels — only needed for prefix nodes
          -- that have no leaf mapping of their own; which-key infers the rest from `desc`.
          local ok, wk = pcall(require, "which-key")
          if ok then
            wk.add({
              { "<leader>M", group = "markdown", buffer = bufnr },
              { "<leader>Mh", group = "headers/toc", buffer = bufnr },
              { "<leader>Mr", group = "thematic rule", buffer = bufnr },
              { "<leader>Ml", group = "links", buffer = bufnr },
              { "<leader>MI", group = "images", buffer = bufnr },
              { "<leader>Mq", group = "quote/callout", buffer = bufnr },
              { "<leader>Mc", group = "code block", buffer = bufnr },
              { "<leader>ML", group = "list", buffer = bufnr },
              { "<leader>MLt", group = "list type", buffer = bufnr },
              { "<leader>Mt", group = "table", buffer = bufnr },
              { "<leader>Mti", group = "insert row/col", buffer = bufnr },
              { "<leader>Mtd", group = "delete row/col", buffer = bufnr },
              { "<leader>Mty", group = "duplicate row/col", buffer = bufnr },
              { "<leader>Mtm", group = "move row/col", buffer = bufnr },
              { "<leader>Mts", group = "sort", buffer = bufnr },
              { "<leader>Mtv", group = "csv", buffer = bufnr },
              { "<leader>Mn", group = "notes (footnotes)", buffer = bufnr },
            })
          end
        end,
      })
    end,
  },
}
