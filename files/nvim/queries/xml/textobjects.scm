; extends

; Tag textobject (`at`/`it`) for 'plugin/50-custom/mini-ai-tweaks.lua'
; (.csproj, .xaml, .svg, ...). nvim-treesitter-textobjects ships no xml
; query; `; extends` keeps this additive should it ever gain one. Inner range
; is derived from the STag/ETag children there.

(element) @tag.outer
