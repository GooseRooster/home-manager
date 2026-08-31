{
  config, lib, pkgs, ...
}:

# Neovim: the vendored LazyVim starter (vendor/lazyvim-starter, kept in sync
# with upstream by CI) merged with the repo's lua overlay (files/nvim/lua) at
# eval time. Replaces the old `bootstrap` flow (git clone + cp overlay) —
# ~/.config/nvim is now a single read-only store symlink, fully declarative.
let
  # Merge semantics mirror the old bootstrap: the overlay wins on conflict,
  # and the starter's inert example plugin (returns {} unconditionally) is
  # dropped. The vendor dir itself stays a pure upstream mirror so the sync
  # script can never lose a manual tweak.
  nvimConfig = pkgs.runCommand "nvim-config" { } ''
    mkdir -p $out
    cp -r ${../vendor/lazyvim-starter}/. $out/
    # Store sources are read-only (dirs included) — make the tree writable
    # before the overlay lands.
    chmod -R u+w $out
    cp -rf ${../files/nvim/lua}/. $out/lua/
    rm -f $out/lua/plugins/example.lua
  '';
in
{
  home.file.".config/nvim" = {
    source = nvimConfig;
    recursive = true;
  };
}
