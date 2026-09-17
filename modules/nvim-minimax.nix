{
  config, lib, pkgs, ...
}:

# Experimental MiniMax (nvim-mini/MiniMax) config, side-by-side with the
# primary LazyVim setup (modules/nvim.nix). Boots as `nvim-minimax` via
# $NVIM_APPNAME, so it never touches ~/.config/nvim or its data/state dirs.
#
# `shellCmd` mirrors modules/nvim.nix: 'files/nvim-minimax/
# plugin/15_options_extra.lua' ships an '@shell@' placeholder that is
# substituted with the host's chosen interactive shell (home.modules.
# defaultShell) so `:!`/`:term` shell out to the binary the user expects.
let
  cfg = config.home.modules;

  # See modules/nvim.nix for why nu/zsh specifically.
  shellCmd = if cfg.defaultShell == "zsh" then "zsh" else "nu";

  # `vendor/minimax/` is a pure upstream mirror (see scripts/update-minimax.sh);
  # `files/nvim-minimax/` is the custom overlay merged on top here — its own
  # directory structure (`lua/config/...`, `plugin/50-custom/...`) already
  # mirrors the destination layout directly, so the whole tree is just
  # copied onto $out (unlike modules/nvim.nix's single-subdirectory overlay,
  # there's no `lua/plugins/example.lua`-style file to strip here).
#
# `nvim-pack-lock.json` is deliberately DROPPED from $out (see below) — do
# not reintroduce it without re-reading this comment.
#
# The precise (previously wrong) claim to correct: `recursive = true` below
# does make ~/.config/nvim-minimax a real, writable *directory* containing
# per-file symlinks into the store (confirmed: `lazyvim.json` already proves
# this for modules/nvim.nix's ~/.config/nvim — a path genuinely absent from
# the vendored source, so home-manager never manages it, leaving room for
# LazyVim to create it itself at runtime as a plain file). But that "vim.pack
# can create new files there freely" claim only holds for paths *absent*
# from the source tree. `vendor/minimax/nvim-pack-lock.json` is NOT absent —
# MiniMax's own upstream repo ships one (a snapshot of the revisions its
# maintainer had installed) — so before this fix it became a managed
# read-only symlink into the store at exactly the path `vim.pack` needs to
# *overwrite* every time it installs/updates a plugin. Opening a symlink
# whose target lives in the read-only nix store for writing fails outright,
# breaking every `vim.pack.add()` call that needs to persist lock data —
# not a "new file" scenario at all, and the previous version of this comment
# missed that distinction. Fix: `rm` it from $out entirely, so home-manager
# never manages that path and `vim.pack` is free to create a genuine mutable
# file there on first run — exactly the `lazyvim.json` precedent, just
# reached by removal instead of by the file never having existed upstream.
# Cost: MiniMax's own stock plugins (mini.nvim, conform.nvim,
# friendly-snippets, nvim-lspconfig, nvim-treesitter(-textobjects)) install
# from their default branch tip instead of the maintainer-tested pin — but
# every custom plugin added in files/nvim-minimax/ was *already* unpinned
# this way, so this just makes the whole config consistently unpinned rather
# than "stock pinned, everything else not". `vendor/minimax/nvim-pack-lock.json`
# itself is untouched (still a normal tracked file, still useful as a
# diffable reference of what upstream had installed at vendoring time) —
  # only the copy that would've landed in the live config is removed.
  minimaxConfig = pkgs.runCommand "nvim-minimax-config" { } ''
    mkdir -p $out
    cp -r ${../vendor/minimax}/. $out/
    chmod -R u+w $out
    rm -f $out/nvim-pack-lock.json
    cp -rf ${../files/nvim-minimax}/. $out/
    substituteInPlace $out/plugin/15_options_extra.lua \
      --replace-fail '@shell@' '${shellCmd}'
  '';
in
{
  home.file.".config/nvim-minimax" = {
    source = minimaxConfig;
    recursive = true;
  };
}
