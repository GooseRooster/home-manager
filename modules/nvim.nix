{ config, lib, pkgs, ... }:

# Neovim: LazyVim starter (cloned, self-updating) with this repo's `lua/` files
# overlaid on top — the same "starter present + our deltas" model chezmoi used.
# Deliberately not the idiomatic HM symlink approach: LazyVim wants a mutable,
# self-updating directory, so we clone it once and copy our files over it.
{
  # Clone LazyVim/starter into ~/.config/nvim if absent (idempotent).
  # Network-dependent and failure-tolerant: an offline first boot must not
  # abort the whole Home Manager activation (exit 128 from `git clone`).
  home.activation.cloneLazyVim = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run() {
      local dir="$HOME/.config/nvim"
      if [ ! -e "$dir" ]; then
        mkdir -p "$HOME/.config"
        if ${pkgs.git}/bin/git clone https://github.com/LazyVim/starter "$dir"; then
          rm -rf "$dir/.git"
        else
          echo "WARN: 'git clone LazyVim/starter' failed (offline?), skipping." >&2
          rm -rf "$dir"
        fi
      fi
    }
    run
  '';

  # Overlay our lua/ config on top of the freshly cloned starter.
  home.activation.overlayNvimLua = lib.hm.dag.entryAfter [ "cloneLazyVim" ] ''
    run() {
      mkdir -p "$HOME/.config/nvim/lua"
      cp -rf ${../files/nvim/lua}/. "$HOME/.config/nvim/lua/"
    }
    run
  '';
}
