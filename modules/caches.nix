{ ... }:

# Mutable tool caches that used to be bootstrapped imperatively (tealdeer). The
# binaries themselves come from nix-cli; here we only manage their state.
{
  # tealdeer: auto-refresh the tldr page cache on use (replaces `tldr --update`).
  xdg.configFile."tealdeer/config.toml" = {
    force = true;
    text = ''
      [updates]
      auto_update = true
    '';
  };
}
