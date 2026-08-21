{ config, lib, pkgs, ... }:

# Mutable tool caches that used to be bootstrapped imperatively. The binaries
# (tealdeer, television) come from nix-cli; here we only manage their state.
{
  # tealdeer: auto-refresh the tldr page cache on use (replaces `tldr --update`).
  xdg.configFile."tealdeer/config.toml" = {
    force = true;
    text = ''
      [updates]
      auto_update = true
    '';
  };

  # television: fetch the community channel prototypes on first activation.
  # Network-dependent and failure-tolerant (like the old bootstrap step).
  home.activation.updateTvChannels = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run() {
      if command -v tv >/dev/null 2>&1; then
        tv update-channels || echo "WARN: 'tv update-channels' failed (offline?), skipping." >&2
      else
        "${pkgs.television}/bin/tv" update-channels || echo "WARN: 'tv update-channels' failed (offline?), skipping." >&2
      fi
    }
    run
  '';
}
