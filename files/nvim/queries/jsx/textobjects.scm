; extends

; Tag textobject (`at`/`it`) for 'plugin/50-custom/mini-ai-tweaks.lua'.
; javascript and tsx queries both `; inherits: ...jsx`, so this covers
; .jsx/.tsx. Inner range is derived from opening/closing elements there.

(jsx_element) @tag.outer

(jsx_self_closing_element) @tag.outer
