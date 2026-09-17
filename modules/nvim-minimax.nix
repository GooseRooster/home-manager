{
  config, lib, pkgs, ...
}:

# Experimental MiniMax (nvim-mini/MiniMax) config, side-by-side with the
# primary LazyVim setup (modules/nvim.nix). Boots as `nvim-minimax` via
# $NVIM_APPNAME, so it never touches ~/.config/nvim or its data/state dirs.
#
# `vendor/minimax/` is a pure upstream mirror (see scripts/update-minimax.sh);
# `files/nvim-minimax/` is the custom overlay merged on top here — its own
# directory structure (`lua/config/...`, `plugin/50-custom/...`) already
# mirrors the destination layout directly, so the whole tree is just
# copied onto $out (unlike modules/nvim.nix's single-subdirectory overlay,
# there's no `lua/plugins/example.lua`-style file to strip here).
#
# `vim.pack`'s own lockfile (nvim-pack-lock.json) is written straight into
# this directory at runtime — confirmed safe: `recursive = true` below
# materializes ~/.config/nvim-minimax as a real, writable directory
# containing per-file symlinks into the store (matching what
# modules/nvim.nix already does for ~/.config/nvim), not a single read-only
# directory symlink. vim.pack can create new files there freely; only the
# *vendored*/*overlaid* files themselves are read-only (they're symlinks to
# the nix store).
let
  minimaxConfig = pkgs.runCommand "nvim-minimax-config" { } ''
    mkdir -p $out
    cp -r ${../vendor/minimax}/. $out/
    chmod -R u+w $out
    cp -rf ${../files/nvim-minimax}/. $out/
  '';
in
{
  home.file.".config/nvim-minimax" = {
    source = minimaxConfig;
    recursive = true;
  };
}
