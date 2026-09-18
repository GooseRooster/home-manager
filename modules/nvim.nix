{
  config, lib, pkgs, ...
}:

# Neovim: the vendored LazyVim starter (vendor/lazyvim-starter, kept in sync
# with upstream by CI) merged with the repo's lua overlay (files/nvim/lua) at
# eval time. Always deployed to the fixed ~/.config/nvim-lazyvim path (a
# single read-only store symlink, fully declarative) and reachable there via
# the `nvim-lazyvim` shell alias regardless of `home.modules.nvimVariant` —
# see modules/nvim-main.nix, which is what actually claims ~/.config/nvim
# for whichever variant is selected.
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
  home.modules.nvimPackages.lazyvim = nvimConfig;

  home.file.".config/nvim-lazyvim" = {
    source = nvimConfig;
    recursive = true;
  };
}
