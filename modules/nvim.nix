{
  config, lib, pkgs, ...
}:

# Neovim: the vendored LazyVim starter (vendor/lazyvim-starter, kept in sync
# with upstream by CI) merged with the repo's lua overlay (files/nvim/lua) at
# eval time. ~/.config/nvim is a single read-only store symlink, fully
# declarative.
let
  cfg = config.home.modules;

  # `:!`/`system()` shell — follows the host's chosen interactive shell so
  # nvim doesn't shell out to a binary that isn't the one the user expects
  # (or, in nu's case, doesn't understand POSIX-style `-c` invocation the
  # same way zsh/sh do).
  shellCmd = if cfg.defaultShell == "zsh" then "zsh" else "nu";

  # The overlay wins on conflict, and the starter's inert example plugin
  # (returns {} unconditionally) is dropped. The vendor dir itself stays a
  # pure upstream mirror so the sync script can never lose a tweak.
  nvimConfig = pkgs.runCommand "nvim-config" { } ''
    mkdir -p $out
    cp -r ${../vendor/lazyvim-starter}/. $out/
    # Store sources are read-only (dirs included) — make the tree writable
    # before the overlay lands.
    chmod -R u+w $out
    cp -rf ${../files/nvim/lua}/. $out/lua/
    rm -f $out/lua/plugins/example.lua
    substituteInPlace $out/lua/config/options.lua \
      --replace-fail '"@shell@"' '"${shellCmd}"'
  '';
in
{
  home.file.".config/nvim" = {
    source = nvimConfig;
    recursive = true;
  };
}
