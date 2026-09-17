{
  config, lib, pkgs, ...
}:

# Experimental MiniMax (nvim-mini/MiniMax) config, side-by-side with the
# primary LazyVim setup (modules/nvim.nix). Boots as `nvim-minimax` via
# $NVIM_APPNAME, so it never touches ~/.config/nvim or its data/state dirs.
#
# Phase 0 of the home-manager roadmap entry (see README.md): vendors stock
# MiniMax as-is, no custom overlay yet. `vim.pack`'s own lockfile
# (nvim-pack-lock.json) is written straight into this directory at runtime —
# confirmed safe: `recursive = true` below materializes ~/.config/nvim-minimax
# as a real, writable directory containing per-file symlinks into the store
# (matching what modules/nvim.nix already does for ~/.config/nvim), not a
# single read-only directory symlink. vim.pack can create new files there
# freely; only the *vendored* files themselves are read-only (they're
# symlinks to the nix store).
#
# Future phases (custom plugin port, Mason-free LSP layer, etc.) will overlay
# a files/nvim-minimax/ directory here the same way modules/nvim.nix layers
# files/nvim/lua over vendor/lazyvim-starter. Not needed yet for stock boot.
let
  minimaxConfig = pkgs.runCommand "nvim-minimax-config" { } ''
    mkdir -p $out
    cp -r ${../vendor/minimax}/. $out/
  '';
in
{
  home.file.".config/nvim-minimax" = {
    source = minimaxConfig;
    recursive = true;
  };
}
