{
  config, lib, pkgs, ...
}:

# Neovim: the MiniMax (nvim-mini/MiniMax) base config (vendor/nvim, kept in
# sync with upstream by scripts/update-nvim.sh) merged with the repo's custom
# overlay (files/nvim) at eval time, deployed to ~/.config/nvim — the path
# plain `nvim`/$EDITOR/$VISUAL (modules/misc-config.nix) resolve to.
#
# `shellCmd`: 'files/nvim/plugin/15_options_extra.lua' ships an '@shell@'
# placeholder that is substituted with the host's chosen interactive shell
# (home.modules.defaultShell) so `:!`/`:term` shell out to the binary the
# user expects. nu/zsh specifically because those are the only two
# interactive shells this repo manages (modules/flavors.nix).
let
  cfg = config.home.modules;

  shellCmd = if cfg.defaultShell == "zsh" then "zsh" else "nu";

  # `vendor/nvim/` is a pure upstream mirror (see scripts/update-nvim.sh);
  # `files/nvim/` is the custom overlay merged on top here — its own
  # directory structure (`lua/config/...`, `plugin/50-custom/...`) already
  # mirrors the destination layout directly, so the whole tree is just
  # copied onto $out (nothing to strip, unlike an overlay that shadows
  # upstream files).
  #
  # `nvim-pack-lock.json` is deliberately DROPPED from $out (see below) — do
  # not reintroduce it without re-reading this comment.
  #
  # `recursive = true` below makes ~/.config/nvim a real, writable
  # *directory* containing per-file symlinks into the store. But that "vim.pack
  # can create new files there freely" claim only holds for paths *absent*
  # from the source tree. `vendor/nvim/nvim-pack-lock.json` is NOT absent —
  # MiniMax's own upstream repo ships one (a snapshot of the revisions its
  # maintainer had installed) — so if kept it would become a managed
  # read-only symlink into the store at exactly the path `vim.pack` needs to
  # *overwrite* every time it installs/updates a plugin. Opening a symlink
  # whose target lives in the read-only nix store for writing fails outright,
  # breaking every `vim.pack.add()` call that needs to persist lock data —
  # not a "new file" scenario at all. Fix: `rm` it from $out entirely, so
  # home-manager never manages that path and `vim.pack` is free to create a
  # genuine mutable file there on first run.
  # Cost: MiniMax's own stock plugins (mini.nvim, conform.nvim,
  # friendly-snippets, nvim-lspconfig, nvim-treesitter(-textobjects)) install
  # from their default branch tip instead of the maintainer-tested pin — but
  # every custom plugin added in files/nvim/ was *already* unpinned this way,
  # so this just makes the whole config consistently unpinned rather than
  # "stock pinned, everything else not". `vendor/nvim/nvim-pack-lock.json`
  # itself is untouched (still a normal tracked file, still useful as a
  # diffable reference of what upstream had installed at vendoring time) —
  # only the copy that would've landed in the live config is removed.
  nvimConfig = pkgs.runCommand "nvim-config" { } ''
    mkdir -p $out
    cp -r ${../vendor/nvim}/. $out/
    chmod -R u+w $out
    rm -f $out/nvim-pack-lock.json
    cp -rf ${../files/nvim}/. $out/
    substituteInPlace $out/plugin/15_options_extra.lua \
      --replace-fail '@shell@' '${shellCmd}'
  '';
in
{
  home.file.".config/nvim" = {
    source = nvimConfig;
    recursive = true;
  };
}
