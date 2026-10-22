; inherits: c_sharp

; nvim-treesitter-textobjects ships no razor query; the razor grammar embeds
; C#, so reuse c_sharp's captures to get `aF`/`aC` etc. in `@code`/`@{ }`
; blocks (same approach as nvim-treesitter's own razor highlights.scm).
; Markup tags are handled by the injected html tree's query.
